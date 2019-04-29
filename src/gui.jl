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
    window = GLFW.CreateWindow(1280, 720, "Demo")
    @assert window != C_NULL
    GLFW.MakeContextCurrent(window)
    GLFW.SwapInterval(1)  # enable vsync

    # setup Dear ImGui context
    ctx = CImGui.CreateContext()

    # setup Dear ImGui style
    # CImGui.StyleColorsDark()
    # CImGui.StyleColorsClassic()
    CImGui.StyleColorsLight()

    # setup Platform/Renderer bindings
    ImGui_ImplGlfw_InitForOpenGL(window, true)
    ImGui_ImplOpenGL3_Init(glsl_version)
    should_show_dialog = true
    clear_color = Cfloat[0.45, 0.55, 0.60, 1.00]


    open_file_dialog = OpenFileDialog(pwd(),"", pwd(),"", false, false)
    time_selector = TimeSelector(Cfloat(100), Cfloat(1224), Cfloat(100), Cfloat(1224), 1, 1, 250.0:250.0:1000.0)
    ts = 0.0
    hz = 4.0
    #eda = Array{Union{Missing, Float64},1}(undef, 0)
    eda_record = ElectrodermalData(0.0, 0, Vector{Float64}(undef, 0), Vector{Float64}(undef, 0))
    events = Dict{String,MarkedInterval}()
    event_name = "\0"^(10)
    while !GLFW.WindowShouldClose(window)

        GLFW.PollEvents()
        # start the Dear ImGui frame
        ImGui_ImplOpenGL3_NewFrame()
        ImGui_ImplGlfw_NewFrame()
        CImGui.NewFrame()

        if CImGui.BeginMainMenuBar()
            if CImGui.BeginMenu("File")
                populate_file_menu!(open_file_dialog)
                CImGui.EndMenu()
            end
            if CImGui.BeginMenu("Filters")
                populate_filter_menu!()
                CImGui.EndMenu()
            end
            CImGui.EndMainMenuBar()
        end

        if isvisible(open_file_dialog)
            display_dialog!(open_file_dialog)
            if has_pending_action(open_file_dialog)
                #eda, ts, hz, time_selector = perform_dialog_action(open_file_dialog)
                eda_record, time_selector = perform_dialog_action(open_file_dialog)
                consume_action!(open_file_dialog)
            end
        end

        if !isempty(eda_record)
            eda =  Float32.(get_eda(eda_record))
            CImGui.SetNextWindowPos((0, 0))
            CImGui.Begin("Main",C_NULL, CImGui.ImGuiWindowFlags_NoBringToFrontOnFocus)
                visualize_data!(time_selector, events, event_name, eda)
                viusalize_events!(events, event_name, time_selector, eda)
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

function perform_dialog_action(dialog::OpenFileDialog)
    directory = get_directory(dialog, ConfirmedStatus())
    file_name = get_file(dialog, ConfirmedStatus())
    path = joinpath(directory, file_name)
    data = CSV.File(path, header=["EDA"]) |> DataFrame
    eda = Float64.(data[:EDA])
    ts = eda[1]
    hz = round(Int,eda[2])
    # It looks like the first EDA measurement will always be zero.
    # We replace zero with a genuine EDA measurement so that
    # the zero doesn't adversly affect our computation of the actual
    # range of EDA value. The genuine range is needed in order to scale
    # the plot.
    eda[3] = eda[4]
    eda = eda[3:end]

    eda_record = ElectrodermalData(ts, hz, eda, eda)

    timestamps_in_ms = range(250; step = 1000 / hz, length = length(eda))
    # TODO revisit the interval story here...
    spacing = Cfloat(40)
    width = CImGui.GetWindowContentRegionWidth() - spacing
    @show length(eda)
    time_selector = TimeSelector(spacing, width, Cfloat(250), Cfloat(640), 1, length(eda), timestamps_in_ms)

    #eda, ts, hz, time_selector
    eda_record, time_selector
end

function populate_file_menu!(dialog::AbstractDialog)
    if CImGui.BeginMenu("Import")
        if CImGui.BeginMenu("Empatica E4")
            if CImGui.MenuItem("EDA.csv")
                set_visibility!(dialog, true)
            end
            if CImGui.MenuItem("TEMP.csv")
            end
            if CImGui.MenuItem("tags.csv")
            end
            CImGui.EndMenu()
        end
       CImGui.EndMenu()
    end
    # if CImGui.MenuItem("Open", "Ctrl+O")
    #     set_visibility!(dialog, true)
    # end
end

function populate_filter_menu!()
    @cstatic enabled=true begin
        @c CImGui.MenuItem("Enabled", "", &enabled)
    end
end

function tag_event!(events, event_name₁, mi::MarkedInterval)
    events[event_name₁] = mi
end

function remove_event!(events, event_name)
    if haskey(events, event_name)
        delete!(events, event_name)
    end
end

function handle_event_annotation!(events,  event_name, time_selector, eda::AbstractArray)
    buffer = Cstring(pointer(event_name))
    CImGui.PushItemWidth(100)
    CImGui.InputText("###event description", buffer, length(event_name))
    CImGui.PopItemWidth()
    CImGui.SameLine()
    color = Cfloat[0/255, 144/255, 0/255, 250/255]
    # Tag on event name
    CImGui.Button("Create Event") && tag_event!(events, event_name[1:end], MarkedInterval(event_name[1:end], copy(time_selector)))
    CImGui.SameLine()
    CImGui.Button("Remove Event") && remove_event!(events, event_name[1:end])
    #@show event_name
    #CImGui.Button("Select Event..") && CImGui.OpenPopup("my_select_popup")
end

function viusalize_events!(events, event_name, time_selector, eda)
    #CImGui.BeginChild("Events")
    # TODO move these values out of this function....

    # We indent all of the plots and widgets to leave space for the
    # EDA values on the y-axis of zoomed eda plot.
    padx₀ = Cfloat(40)
    # Determines the gap between subsequent tick on the y-axis.
    y_tick_spacing = 40
    # Determines the gap between subsequent ticks on the x-axis (the timeline).
    x_tick_spacing = 120
    # Total vertical space allotted for the zoomed eda plot.
    zoomed_plot_height = Cfloat(200)
    # Total vertical space allotted for the overview eda plot
    overview_plot_height = Cfloat(50)
    #
    CImGui.SetCursorPosX(padx₀)
    pos = CImGui.GetCursorPos()
    x = pos.x
    y = pos.y
    width = CImGui.GetWindowContentRegionWidth() - padx₀
    #@show x,y,width
    # Allow the user to type a name for an event and respond to the
    # "Create Event" button press.
    handle_event_annotation!(events, event_name, time_selector, eda)
    # Draw a rectangle and label on the eda overlay to demarcate the created event.
    demarcate_events(events, x, y-108, width, overview_plot_height)
    # Respond to mouse events on the demarcated region.
    handle_event_interaction!(time_selector, event_name, events, x, y-108, overview_plot_height)
    #draw_events(events, x, y-108, width, overview_plot_height)

    #draw_list = CImGui.GetWindowDrawList()
    #CImGui.AddRectFilled(draw_list, ImVec2(20, 20), ImVec2(100, 100),  CImGui.ColorConvertFloat4ToU32(ImVec4(Cfloat[0.0,0.0,0.0,1.0]...)));
    #CImGui.EndChild()
end

function demarcate_events(events, x, y, width, height)
    draw_list = CImGui.GetWindowDrawList()
    for (key, value) in events
           time_interval = get_time_interval(value)
           CImGui.AddRectFilled(draw_list, ImVec2(get_x₀(time_interval), y), ImVec2(get_x₁(time_interval),  y + height), CImGui.ColorConvertFloat4ToU32(ImVec4(Cfloat[1.0,0.0,0.99,0.2]...)));
           first_nul = findfirst(isequal('\0'), key)
           str = key[1:first_nul-1]
           xₜ = get_x₀(time_interval) + 5
           yₜ =  y + 5
           CImGui.AddText(draw_list,ImVec2(xₜ, yₜ), CImGui.ColorConvertFloat4ToU32(ImVec4(Cfloat[0.4,0.4,0.4, 1.0]...)) , str)
    end
end

function handle_event_interaction!(time_interval, event_name, events,  x, y, height)

    for (key, value) in events
           time_intervalₙ = get_time_interval(value)
           CImGui.SetCursorPos(ImVec2(get_x₀(time_intervalₙ), y))
           width = get_x₁(time_intervalₙ) - get_x₀(time_intervalₙ)

           first_nul = findfirst(isequal('\0'), key)
           str = key[1:first_nul-1]
           # The invisible button will be used to detect mouse hovering events.
           CImGui.InvisibleButton("###$str", ImVec2(width,height))
           δms = get_t₁_ms(time_intervalₙ) - get_t₀_ms(time_intervalₙ)
           elapsed_time = Dates.canonicalize(Dates.CompoundPeriod(Dates.Millisecond(δms)))
           CImGui.IsItemHovered() && CImGui.SetTooltip(string(elapsed_time))
           # As well as mouse click events.
           if CImGui.IsItemClicked()
               set_x₀!(time_interval, get_x₀(time_intervalₙ))
               set_x₁!(time_interval, get_x₁(time_intervalₙ))
               # TODO Look into this once we update CImGui to sidestep pointer issue in strings.
               #event_name = key[1:end]
           end
    end
    # It will also be used to detect click events and to set the main
    # time_interval widget equal to the scope of the time_interval associated
    # with this particular event.
end

# function draw_events(events, x, y, width, height)
#     draw_list = CImGui.GetWindowDrawList()
#
#     for (key, value) in events
#            time_interval = get_time_interval(value)
#            CImGui.AddRectFilled(draw_list, ImVec2(get_x₀(time_interval), y), ImVec2(get_x₁(time_interval),  y + height), CImGui.ColorConvertFloat4ToU32(ImVec4(Cfloat[1.0,0.0,0.99,0.2]...)));
#            CImGui.SetCursorPos(ImVec2(get_x₀(time_interval), y))
#            w = get_x₁(time_interval) - get_x₀(time_interval)
#            first_nul = findfirst(isequal('\0'), key)
#            str = key[1:first_nul-1]
#            xₜ = get_x₀(time_interval) + 5
#            yₜ =  y + 5
#            CImGui.AddText(draw_list,ImVec2(xₜ, yₜ), CImGui.ColorConvertFloat4ToU32(ImVec4(Cfloat[0.4,0.4,0.4, 1.0]...)) , str)
#            # The invisible button will be used to detect mouse hovering events.
#            CImGui.InvisibleButton("###$str", ImVec2(w,height))
#            δms = get_t₁_ms(time_interval ) - get_t₀_ms(time_interval )
#            elapsed_time = Dates.canonicalize(Dates.CompoundPeriod(Dates.Millisecond(δms)))
#            CImGui.IsItemHovered() && CImGui.SetTooltip(string(elapsed_time))
#            # It will also be used to detect click events and to set the main
#            # time_interval widget equal to the scope of the time_interval associated
#            # with this particular event.
#      end
# end

function visualize_data!(time_selector, events, event_name, eda::AbstractArray)
        # We indent all of the plots and widgets to leave space for the
        # EDA values on the y-axis of zoomed eda plot.
        padx₀ = Cfloat(40)
        # Determines the gap between subsequent tick on the y-axis.
        y_tick_spacing = 40
        # Determines the gap between subsequent ticks on the x-axis (the timeline).
        x_tick_spacing = 120
        # Total vertical space allotted for the zoomed eda plot.
        zoomed_plot_height = Cfloat(200)
        # Total vertical space allotted for the overview eda plot
        overview_plot_height = Cfloat(50)
        #
        CImGui.SetCursorPosX(padx₀)
        pos = CImGui.GetCursorPos()
        x = pos.x
        y = pos.y
        width = CImGui.GetWindowContentRegionWidth() - padx₀

        draw_zoomed_eda!(time_selector, eda, x, y, width, zoomed_plot_height, x_tick_spacing, y_tick_spacing)
        # Plots the eda for the entire session and creates a draggable widget which allows
        # the user to select a region of interest to zoom-in on.
        determine_eda_roi(time_selector, eda, x, y, width, overview_plot_height, x_tick_spacing)

end



function determine_eda_roi(ts::TimeSelector, eda, x, y, width, height, spacing)
    CImGui.SetCursorPosX(x)
    #CImGui.SetCursorPosY(x)
    CImGui.PlotLines("###eda_overview", eda, length(eda), 0 , "", minimum(eda), maximum(eda), (width, height))
    ts₂ = TimeSelector(get_interval₀(ts), get_interval₁(ts), get_interval₀(ts), get_interval₁(ts), 1, length(eda), get_timestamps(ts))
    pos = CImGui.GetCursorPos()
    y = pos.y
    draw_timestamps_abscissa(ts₂, x, y, width, height, spacing, CImGui.ColorConvertFloat4ToU32(ImVec4(Cfloat[0.0,0.0,0.0,1.0]...)))
    handle_roi_selection!(ts, x, y, width, height)
end

function handle_roi_selection!(ts::TimeSelector, x, y, width, height)
    draw_list = CImGui.GetWindowDrawList()
    #CImGui.InvisibleButton("Drag Me", ImVec2(x + width, height))
    CImGui.SetCursorPosY(y)
    CImGui.InvisibleButton("Drag Me", ImVec2(x + width, height))
    CImGui.AddRectFilled(draw_list, ImVec2(get_x₀(ts), y), ImVec2(get_x₁(ts),  y + height), CImGui.ColorConvertFloat4ToU32(ImVec4(Cfloat[0.0,0.0,0.99,0.2]...)));
    # Change cursor to indicate that the user can drag the rectangle when they
    # hover the mouse over the endpoints of the rectangle.
    io = CImGui.GetIO()
    if CImGui.IsItemHovered()
        mousepos = io.MousePos
        #@show mousepos.x, get_x₁(time_selector)
        # Relax threshold when dragging to make things smoother
        if (abs(get_x₀(ts) - mousepos.x) <=  25)
            CImGui.SetMouseCursor(CImGui.ImGuiMouseCursor_ResizeEW)
            if CImGui.IsItemActive()
                set_x₀!(ts, io.MousePos.x)
            end
        end
        if (abs(get_x₁(ts) - mousepos.x) <= 25)
            CImGui.SetMouseCursor(CImGui.ImGuiMouseCursor_ResizeEW)
            if CImGui.IsItemActive()
                set_x₁!(ts, io.MousePos.x)
            end
        end
    end
end

function draw_zoomed_eda!(time_selector, eda::AbstractArray, x::Cfloat ,y::Cfloat, width, height::Cfloat, x_tick_spacing, y_tick_spacing)
    # The time selector needs to be reconciled with the width of the window
    # to maintain a proper mapping between pixels on the timeline and eda timestamps.
    map_time_selector_to_window!(time_selector, x, width)
    # The region of interest is mapped to a pair of indices which are used to
    # select the corresponding data stored in the eda array.
    t₀ = get_t₀(time_selector)
    t₁ = get_t₁(time_selector)
    eda′ = eda[t₀:t₁]
    # The total duration of the selected region is computed and displayed in canonical text form.
    δms = get_t₁_ms(time_selector) - get_t₀_ms(time_selector)
    elapsed_time = Dates.canonicalize(Dates.CompoundPeriod(Dates.Millisecond(δms)))
    begin
        CImGui.PlotLines("###microsiemens", eda′ , length(eda′), 0 , string(elapsed_time), minimum(eda′), maximum(eda′), (width, height))
        # Visual guide to make it easier to determine the eda at a particular point in time.
        draw_horizontal_bars(x, y, width, height, y_tick_spacing, CImGui.ColorConvertFloat4ToU32(ImVec4(Cfloat[1.0,0.0,0.4,0.2]...)))
        # Reference EDA values for the y-axis.
        draw_eda_ordinate(eda′, x, y, width, height, y_tick_spacing, CImGui.ColorConvertFloat4ToU32(ImVec4(Cfloat[0.0,0.0,0.0,1.0]...)))
        # Time stamps on the x-axis.
        draw_timestamps_abscissa(time_selector, x, y + height, width, height, x_tick_spacing, CImGui.ColorConvertFloat4ToU32(ImVec4(Cfloat[0.0,0.0,0.0,1.0]...)))
    end
end

function draw_timestamps_abscissa(time_selector, x, y, width, height, spacing, col32)
    # Parameters that determine the look and position of the timeline.
    xoffset = 25
    yoffset = 15
    tick_length = 10
    tick_thickness = Cfloat(1)
    draw_list = CImGui.GetWindowDrawList()

    # Draw the timeline.
    CImGui.AddLine(draw_list, ImVec2(x, y), ImVec2(x + width, y), col32, tick_thickness);
    # Draw the concomitant tick marks.
    for xₙ in range(x, step = spacing, stop = x + width)
        # This line represents the tick mark.
        CImGui.AddLine(draw_list, ImVec2(xₙ, y), ImVec2(xₙ, y + tick_length), col32, tick_thickness);
        # Associate x-coordinates of the timestamp tick marks with actual timestamps.
        t₀_ms = get_t₀_ms(time_selector)
        t₁_ms = get_t₁_ms(time_selector)
        ms = round(stretch_linearly(xₙ, x,  x + width, t₀_ms, t₁_ms))
        timestamp = Dates.epochms2datetime(Dates.value(Millisecond(ms)))
        # Display timestamp.
        timestr = Dates.format(timestamp , dateformat"HH:MM:SS")
        CImGui.AddText(draw_list, ImVec2(xₙ - xoffset, y + yoffset), col32, "$timestr",);
    end
    CImGui.SetCursorPosY(y + 2*yoffset + 5)
end

function draw_horizontal_bars(x, y, width, height, spacing, col32)
    # Draws (almost transparent) horizontal bars which serve as a visual guide.
    draw_list = CImGui.GetWindowDrawList()
    for yₙ in range(y, step = spacing, stop = y + height - spacing)
        CImGui.AddRectFilled(draw_list, ImVec2(x, yₙ), ImVec2(x + width, yₙ + div(spacing, 2)), col32);
    end
end

function draw_eda_ordinate(eda, x, y, width, height, spacing, col32)
    yoffset = 12
    draw_list = CImGui.GetWindowDrawList()
    # Draw EDA values as references on the y-axis.
    for yₙ in range(y + height, step = -div(spacing, 2), stop = y)
        eda_reference = round(stretch_linearly(yₙ, y + height,  y, minimum(eda), maximum(eda)); digits = 3)
        CImGui.AddText(draw_list, ImVec2(x, yₙ - yoffset), col32, "$eda_reference",);
    end
end

function map_time_selector_to_window!(time_selector, x, width)
    i₀ = x
    i₁ = x + width
    # This defines the start and end x-coordinates for drawing the complete timeline.
    set_interval₀!(time_selector, i₀)
    set_interval₁!(time_selector, i₁)

    # The user can drag a region-of-interest within the interval defined above.
    # The relevant sub-interval on the timeline is associated with the
    # x₀ and x₁ coordinates which are stored in the time_selector.
    # We need to ensure that the x₀ and x₁ coordinates never extend beyond the
    # bounds of the complete timeline.
    x₀ = get_x₀(time_selector)
    set_x₀!(time_selector,  x₀ <= i₀ ? i₀ : x₀)
    x₁ = get_x₁(time_selector)
    set_x₁!(time_selector,  x₁ >= i₁ ? i₁ : x₁)
end


function draw_event_overlay()

end

function stretch_linearly(x, A, B, a, b)
    (x-A) * ((b-a) / (B-A)) + a
end#
