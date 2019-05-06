
function run_gui()

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
    window = GLFW.CreateWindow(1280, 720, "ElectroDermal Activity Analysis")
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

    controllers = Dict{String, AbstractController}()
    properties = Dict{String, AbstractDisplayProperties}()
    operations = Dict{String, AbstractOperations}()

    # The controller is responsible for instantiating the dialog GUI,
    # handling user input and tiggering the file importer once the user
    # confirms the selection of a particular file.
    control = FileDialogController(true)
    # The model store the path that the user has confirmed, as well as the
    # path that the user has selected but not necessarily confirmed.
    model = FileDialogModel(Path(pwd(),"hello"), Path(pwd(),"hello"))
    # The display properties include the title of the file dialog and what
    # action string is to be displayed on the button.
    properties = FileDialogDisplayProperties("Open File###CSV", "Open###CSV", ImVec2(0,0), 100, 100)
    # The importer is triggered once the user has confirmed the selection of a
    # particular path.
    load_csv = CSVImporter(false)



    control₂ =  FileDialogController(true)
    model₂ = FileDialogModel(Path(pwd(),"hello"), Path(pwd(),"hello"))
    properties₂ = FileDialogDisplayProperties("Open File###Image", "Open###Image", ImVec2(0,0), 100, 100)
    load_image = ImageImporter(false)

    data = nothing
    while !GLFW.WindowShouldClose(window)
        GLFW.PollEvents()
        # start the Dear ImGui frame
        ImGui_ImplOpenGL3_NewFrame()
        ImGui_ImplGlfw_NewFrame()
        CImGui.NewFrame()

        # Display and handle file dialog interactions.
        isenabled(control) ? control(model, properties, load_csv) : nothing
        isenabled(control₂) ? control₂(model₂, properties₂, load_image) : nothing

        # Load new data based on user selection.
        data = isenabled(load_csv) ? load_csv(get_path(model,ConfirmedStatus())) : data

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
