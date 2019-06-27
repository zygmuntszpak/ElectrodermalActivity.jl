
function launch()

    @static if Sys.isapple()
        # OpenGL 3.2 + GLSL 150
        glsl_version = 150
        GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)
        GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 2)
        GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE) # 3.2+ only
        GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, GL_TRUE) # required on Mac
    else
        # OpenGL 3.0 + GLSL 130
        glsl_version = 130
        GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)
        GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 0)
        # GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE) # 3.2+ only
        # GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, GL_TRUE) # 3.0+ only
    end

    # setup GLFW error callback
    error_callback(err::GLFW.GLFWError) = @error "GLFW ERROR: code $(err.code) msg: $(err.description)"
    GLFW.SetErrorCallback(error_callback)

    # create window
    window = GLFW.CreateWindow(1280, 720, "Electrodermal Activity Analysis")
    @assert window != C_NULL
    GLFW.MakeContextCurrent(window)
    GLFW.SwapInterval(1)  # enable vsync

    # setup Dear ImGui context
    ctx = CImGui.CreateContext()

    # setup Dear ImGui style
    CImGui.StyleColorsLight()

    # setup Platform/Renderer bindings
    ImGui_ImplGlfw_InitForOpenGL(window, true)
    ImGui_ImplOpenGL3_Init(glsl_version)

    # Instantiate variables that are used to control input and output
    # of various widges.
    clear_color = Cfloat[0.45, 0.55, 0.60, 1.00]


    gui_events = Dict{String, Bool}()

    eda_data = nothing
    tags_data = nothing
    electrodermal_data = nothing

    # Initialize importers
    import_labels_key = "Import Interval Labels"
    import_labelled_intervals = create_import_context(GenericVendor(), GenericProduct(), IntervalLabels(), import_labels_key)

    import_eda_key = "Empatica E4 EDA.csv"
    import_eda = create_import_context(Empatica(), E4(), SkinConductance(), import_eda_key)

    import_tags_key = "Empatica E4 tags.csv"
    import_tags = create_import_context(Empatica(), E4(), Tags(), import_tags_key)

    select_timezone_key = "Select Time Zone"
    # Set the default time zome in accordance with the PC.
    select_timezone = create_timezone_context(localzone().name, timezone_names())

    # Initialize exporters
    labels_key = "Export Interval Labels"
    export_labelled_intervals = create_export_context(GenericVendor(), GenericProduct(), IntervalLabels(), labels_key)

    export_electrodermal_activity_key = "Export Electrodermal Activity"
    export_electrodermal_activity = create_export_context(Empatica(), E4(), SkinConductance(), export_electrodermal_activity_key)

    outline_layout = RectangularLayout(pos = ImVec2(0,0), width = Cfloat(600), height = Cfloat(80))
    data_layout = RectangularLayout(pos = ImVec2(0,0), width = Cfloat(600), height = Cfloat(400))


    # Configure overview plot context
    plotmodel = PlotlinesModel(rand(Float32,100))
    plotproperties₁ = PlotlinesDisplayProperties(id = "###overview"; caption = x -> "", createwindow = false, layout = outline_layout, xaxis = Axis(false, Cfloat(1)), yaxis = Axis(false, Cfloat(1)), padding = (0,0,0,0))
    plot_data_context = PlotContext(PlotlinesControl(true), plotmodel, plotproperties₁)

    # Configure interval selection context
    ni_control = NestedIntervalControl(true)
    ni_model = NestedInterval(start = 20.0, stop = 80.0, interval = 1:100)
    ni_properties = NestedIntervalDisplayProperties(id="###hidden control", caption = "Nested Interval", col = ImVec4(0.0, 0.0, 0.99, 0.2), layout = outline_layout, plotcontext = plot_data_context, padding = (0,0,0,0))
    ni_context = NestedIntervalContext(ni_control, ni_model, ni_properties)

    # Configure zoomed plot context.
    plotproperties₂ = PlotlinesDisplayProperties(id = "###eda"; caption = x -> "EDA", layout = data_layout, padding = (0,0,0,0))
    plotcontrol = PlotlinesControl(true)
    plot_outline_context = PlotContext(plotcontrol, plotmodel, plotproperties₂)

    plot_data_context = nothing
    ni_context = nothing
    plot_roi_context = nothing
    label_context = nothing
    tags_context = nothing
    enable_filter = false

    while !GLFW.WindowShouldClose(window)
        GLFW.PollEvents()
        # start the Dear ImGui frame
        ImGui_ImplOpenGL3_NewFrame()
        ImGui_ImplGlfw_NewFrame()
        CImGui.NewFrame()


        menubar!(gui_events)
        for (key, event) in pairs(gui_events)
            if key == import_eda_key
                if event == true
                    enable!(import_eda.control)
                    gui_events[key] = false
                end
                electrodermal_data₀ = import_eda()
                if !isrunning(import_eda) && !isnothing(electrodermal_data₀)
                    electrodermal_data = electrodermal_data₀
                    plot_data_context = construct_plot_data_context(electrodermal_data)
                    # The interval selection model will be shared with the PlotlinesDisplayProperties so that we can determine the mapping from the interval to
                    # an appropriate timestamp on the x-axis on the zoomed EDA plot.
                    data = get_eda(electrodermal_data)
                    ni_model = NestedInterval(start = Float64(1.0), stop = Float64(length(data)), interval = 1:length(data))
                    plot_outline_context =  construct_plot_outline_context(ni_model, plot_data_context.model, electrodermal_data)
                    ni_context = construct_nested_interval_context(ni_model, plot_data_context)
                    # Configure interactive truncated/zoomed plot context.
                    plot_roi_context = TruncatedPlotContext(PlotlinesControl(true),  plot_outline_context, ni_context)
                    #
                    dict = Dict{String, LabelledInterval}()
                    labelled_intervals = LabelledIntervals("Conditions", dict)
                    label_context = construct_labelled_interval_context(labelled_intervals, plot_data_context.model, ni_context.model, get_layout(plot_data_context.display_properties))
                    delete!(gui_events, key)
                end
            end
            if key == "Empatica E4 tags.csv"
                if isnothing(label_context) || isnothing(electrodermal_data)
                    CImGui.OpenPopup("Have you loaded electrodermal activity data?")
                    delete!(gui_events, key)
                else
                    if event == true
                        enable!(import_tags.control)
                        gui_events[key] = false
                    end
                    tags_data₀ = import_tags()
                    if !isrunning(import_tags) && !isnothing(tags_data₀)
                        tags_data = tags_data₀
                        tags_context  = construct_tags_context(tags_data, label_context.display_properties, electrodermal_data)
                        delete!(gui_events, key)
                    end
                end
            end
            if key == "Export Interval Labels"
                if isnothing(electrodermal_data)
                    CImGui.OpenPopup("Have you loaded electrodermal activity data?")
                    delete!(gui_events, key)
                else
                    if event == true
                        enable!(export_labelled_intervals)
                        gui_events[key] = false
                    end
                    export_labelled_intervals(label_context.model)
                    if !isrunning(export_labelled_intervals)
                        delete!(gui_events, key)
                    end
                end
            end
            if key == "Export Electrodermal Activity"
                if isnothing(electrodermal_data)
                    CImGui.OpenPopup("Have you loaded electrodermal activity data?")
                    delete!(gui_events, key)
                else
                    if event == true
                        enable!(export_electrodermal_activity)
                        gui_events[key] = false
                    end
                    export_electrodermal_activity(electrodermal_data, label_context.model)
                    if !isrunning(export_electrodermal_activity)
                        delete!(gui_events, key)
                    end
                end
            end
            if key == "Import Interval Labels"
                if isnothing(plot_data_context)
                    CImGui.OpenPopup("Have you loaded electrodermal activity data?")
                    delete!(gui_events, key)
                else
                    if event == true
                        enable!(import_labelled_intervals)
                        gui_events[key] = false
                    end
                    data = import_labelled_intervals()
                    if !isrunning(import_labelled_intervals) && !isnothing(data)
                        labelled_intervals = data
                        label_context = construct_labelled_interval_context(labelled_intervals, plot_data_context.model, ni_context.model, get_layout(plot_data_context.display_properties))
                        delete!(gui_events, key)
                    end
                end
            end
             if key == "Filter Lowpass 1Hz"
                 enable_filter = !enable_filter
                 if !isnothing(electrodermal_data)
                     apply_filter!(enable_filter, electrodermal_data)
                     # Update all contexts so that they reflect the new data
                     plot_data_context = construct_plot_data_context(electrodermal_data)
                     data = get_eda(electrodermal_data)
                     ni_model = NestedInterval(start = get_start(ni_context.model), stop = get_stop(ni_context.model), interval = 1:length(data))
                     plot_outline_context =  construct_plot_outline_context(ni_model, plot_data_context.model, electrodermal_data)
                     ni_context = construct_nested_interval_context(ni_model, plot_data_context)
                     # Configure interactive truncated/zoomed plot context.
                     plot_roi_context = TruncatedPlotContext(PlotlinesControl(true),  plot_outline_context, ni_context)
                     label_context = construct_labelled_interval_context(label_context.model, plot_data_context.model, ni_context.model, get_layout(plot_data_context.display_properties))
                     delete!(gui_events, key)
                end
             end
             if key == "Select Time Zone"
                 if isnothing(plot_data_context)
                     CImGui.OpenPopup("Have you loaded electrodermal activity data?")
                     delete!(gui_events, key)
                 else
                     if event == true
                         enable!(select_timezone)
                         gui_events[key] = false
                     end
                     data = select_timezone()
                     if !isrunning(select_timezone) && !isnothing(data)
                         tz = data
                         #label_context = construct_labelled_interval_context(labelled_intervals, plot_data_context.model, ni_context.model, get_layout(plot_data_context.display_properties))
                         plot_outline_context = plot_roi_context.plot_context
                         properties = plot_outline_context.display_properties
                         xtick = get_xtick(properties)
                         interpreter = get_interpreter(xtick)
                         timestamp = get_timestamp(interpreter)
                         intersample_duration = get_intersample_duration(interpreter)
                         nested_interval = get_nested_interval(interpreter)
                         xtick_new = Tickmark(; interpret = TimestampResolver(tz, timestamp, intersample_duration, nested_interval), spacing = Cfloat(15))
                         set_xtick!(properties, xtick_new )
                         delete!(gui_events, key)
                     end
                 end
             end
        end

        handle_import_error_messages()

        # Display the electrodermal activity data and concomitant interval selector.
        if !isnothing(plot_roi_context)
            CImGui.Begin("EDA (microsiemens)",C_NULL, CImGui.ImGuiWindowFlags_NoBringToFrontOnFocus)
                plot_roi_context()
            CImGui.End()
        end

        # Display the labelled conditions and markers.
        if !isnothing(label_context) || !isnothing(tags_context)
            CImGui.Begin("Conditions###Conditions and Tags",C_NULL, CImGui.ImGuiWindowFlags_NoBringToFrontOnFocus)
                pos = CImGui.GetCursorScreenPos()
                !isnothing(label_context) ? label_context() : nothing
                CImGui.SetCursorScreenPos(pos.x, pos.y + 3)
                !isnothing(tags_context) ? tags_context() : nothing
            CImGui.End()
        end

        # rendering
        CImGui.Render()
        GLFW.MakeContextCurrent(window)
        display_w, display_h = GLFW.GetFramebufferSize(window)
        glViewport(0, 0, display_w, display_h)
        glClearColor(clear_color...)
        glClear(GL_COLOR_BUFFER_BIT)
        ImGui_ImplOpenGL3_RenderDrawData(CImGui.GetDrawData())

        GLFW.MakeContextCurrent(window)
        GLFW.SwapBuffers(window)
    end

    # cleanup
    ImGui_ImplOpenGL3_Shutdown()
    ImGui_ImplGlfw_Shutdown()
    CImGui.DestroyContext(ctx)

    GLFW.DestroyWindow(window)

end

function labels_to_dataframe(labelled_intervals)
    df = DataFrame(label = String[], start = Int64[], stop = Int64[], first = Float64[], step = Float64[], last  = Float64[])
    for (key, labelled_interval) in pairs(labelled_intervals)
        nested_interval = labelled_interval.nested_interval
        start = get_start(nested_interval)
        stop = get_stop(nested_interval)
        interval = get_interval(nested_interval)
        push!(df, [key start stop first(interval) step(interval) last(interval)])
    end
    return df
end

function construct_tags_context(tags_data::AbstractVector, label_display_properties::LabelIntervalDisplayProperties, electrodermal_data::ElectrodermalData)
    outline_layout = get_layout(label_display_properties)
    padding = get_padding(label_display_properties)
    start_time = get_timestamp(electrodermal_data)
    Δt = (1 / get_sampling_frequency(electrodermal_data)) * 1000
    time₀ = Δt
    time₁ = Δt * length(get_unprocessed_eda(electrodermal_data))
    tags_model = TagsModel(start_time, time₀, time₁,  tags_data)
    tags_display_properties = TagsDisplayProperties(id = "###tags"; caption = x -> "", createwindow = false, layout = outline_layout, padding = padding)
    tags_context = TagsContext(TagsControl(true),  tags_model, tags_display_properties)
end

function construct_plot_data_context(data::ElectrodermalData)
    outline_layout = RectangularLayout(pos = ImVec2(0,0), width = Cfloat(1820), height = Cfloat(80))
    eda = Float32.(get_eda(data))
    # Configure overview plot context
    plotmodel = PlotlinesModel(eda)
    plotproperties₁ = PlotlinesDisplayProperties(id = "###overview"; caption = x -> "", createwindow = false, layout = outline_layout, xaxis = Axis(false, Cfloat(1)), yaxis = Axis(false, Cfloat(1)), padding = (0,80,0,0))
    plot_data_context = PlotContext(PlotlinesControl(true), plotmodel, plotproperties₁)
    return plot_data_context
end

function construct_plot_outline_context(ni_model, plotmodel,  data::ElectrodermalData)
    Δt = (1 / get_sampling_frequency(data)) * 1000
    timestamp₀ = get_timestamp(data)
    data_layout = RectangularLayout(pos = ImVec2(0,0), width = Cfloat(1820), height = Cfloat(400))
    # Configure zoomed plot context.
    plotproperties₂ = PlotlinesDisplayProperties(id = "###eda"; caption = DurationResolver(Δt, ni_model), layout = data_layout, padding = (0,80,0,0), xtick = Tickmark(; interpret = TimestampResolver(localzone().name,timestamp₀, Δt, ni_model), spacing = Cfloat(15)))
    plotcontrol = PlotlinesControl(true)
    plot_outline_context = PlotContext(plotcontrol, plotmodel, plotproperties₂)
    return plot_outline_context
end

function construct_labelled_interval_context(labelled_intervals::LabelledIntervals, plotmodel::AbstractModel, ni_model::NestedInterval, outline_layout)
    label_control = LabelIntervalControl(true, ni_model, "\0"^64*"\0")
    label_display_properties = LabelIntervalDisplayProperties(id = "###event markers" ; caption = "Conditions", createwindow =  false, layout = outline_layout)
    plotproperties = PlotlinesDisplayProperties(id = "###events overview"; caption = x->"", createwindow = false, layout = outline_layout, xaxis = Axis(false, Cfloat(1)), yaxis = Axis(false, Cfloat(1)), padding = (0,0,0,0))
    plot_outline_context = PlotContext(PlotlinesControl(true), plotmodel, plotproperties)
    label_context = LabelIntervalContext(label_control, labelled_intervals, label_display_properties, plot_outline_context)
    return label_context
end

function construct_nested_interval_context(ni_model, plot_data_context)
    # Configure interval selection context
    outline_layout = get_layout(plot_data_context.display_properties)
    ni_control = NestedIntervalControl(true)
    ni_properties = NestedIntervalDisplayProperties(id="###hidden control", caption = "Nested Interval", col = ImVec4(0.0, 0.0, 0.99, 0.2), layout = outline_layout, plotcontext = plot_data_context, padding = (0,80,0,0))
    ni_context = NestedIntervalContext(ni_control, ni_model, ni_properties)
    return ni_context
end

function apply_filter!(enabled::Bool, electrodermal_data::ElectrodermalData)
    eda₀ = get_unprocessed_eda(electrodermal_data)
    if enabled
        response_type = Lowpass(1; fs = get_sampling_frequency(electrodermal_data))
        design_method = Butterworth(2)
        eda₁ = filt(digitalfilter(response_type, design_method), eda₀)
        set_eda!(electrodermal_data, eda₁)
    else
        set_eda!(electrodermal_data, eda₀)
    end
end

function create_timezone_context(zone::String, possible_zones::Vector{String})
    TimeZoneContext(TimeZoneControl(false), TimeZoneModel(zone,  possible_zones), TimeZoneDisplayProperties(), SelectTimeZone(true))
end

function handle_import_error_messages()
    if CImGui.BeginPopupModal("Have you loaded electrodermal activity data?", C_NULL, CImGui.ImGuiWindowFlags_AlwaysAutoResize)
        CImGui.Text("Please first import the accompanying electrodermal activity data.\n\n")
        CImGui.Separator()
        CImGui.Button("OK", (120, 0)) && CImGui.CloseCurrentPopup()
        CImGui.SetItemDefaultFocus()
        CImGui.EndPopup()
    end

    # if CImGui.BeginPopupModal("Do you have permission to read the file?", C_NULL, CImGui.ImGuiWindowFlags_AlwaysAutoResize)
    #     CImGui.Text("Unable to access the specified file.\nPlease verify that: \n   (1) the file exists; \n   (2) you have permission to read the file.\n\n")
    #     CImGui.Separator()
    #     CImGui.Button("OK", (120, 0)) && CImGui.CloseCurrentPopup()
    #     CImGui.SetItemDefaultFocus()
    #     CImGui.EndPopup()
    # end
end
