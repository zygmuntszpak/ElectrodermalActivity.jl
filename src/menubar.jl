function menubar!(events::Dict{String, Bool})
    if CImGui.BeginMainMenuBar()
       if CImGui.BeginMenu("File")
           populate_file_menu!(events)
           CImGui.EndMenu()
       end
       if CImGui.BeginMenu("Filters")
        # TODO make sure it is initially always unticked
        @cstatic enabled=false begin
             if @c CImGui.MenuItem("Lowpass 1Hz", "", &enabled)
                   keystr = "Filter Lowpass 1Hz"
                   events[keystr] = true
             end
            CImGui.EndMenu()
        end
       end
       if CImGui.BeginMenu("Settings")
           if CImGui.MenuItem("Select Time Zone")
               keystr = "Select Time Zone"
               events[keystr] = true
           end
           CImGui.EndMenu()
       end
       CImGui.EndMainMenuBar()
   end
end

function populate_file_menu!(events::Dict{String, Bool})
    if CImGui.BeginMenu("Import")
        if CImGui.MenuItem("Interval Labels")
            keystr = "Import Interval Labels"
            events[keystr] = true
        end
        if CImGui.BeginMenu("Empatica E4")
            if CImGui.MenuItem("EDA.csv")
                keystr = "Empatica E4 EDA.csv"
                events[keystr] = true
            end
            # if CImGui.MenuItem("TEMP.csv")
            #
            # end
            if CImGui.MenuItem("tags.csv")
                keystr = "Empatica E4 tags.csv"
                events[keystr] = true
            end
        CImGui.EndMenu()
        end
    CImGui.EndMenu()
    end
    if CImGui.BeginMenu("Export")
        if CImGui.BeginMenu("Empatica")
            if CImGui.MenuItem("Electrodermal Activity")
                keystr = "Export Electrodermal Activity"
                events[keystr] = true
            end
        CImGui.EndMenu()
        end
        if CImGui.BeginMenu("Interval")
            if CImGui.MenuItem("Labels")
                keystr = "Export Interval Labels"
                events[keystr] = true
            end
        CImGui.EndMenu()
        end
    CImGui.EndMenu()
    end
end



# function create_model_view_controller(vendor::Empatica, product::E4, data::SkinConductance, keystr::String)
#     # The controller is responsible for instantiating the dialog GUI,
#     # handling user input and tiggering the file importer once the user
#     # confirms the selection of a particular file.
#     control = FileDialogControl(true)
#     # The model store the path that the user has confirmed, as well as the
#     # path that the user has selected but not necessarily confirmed.
#     model = FileDialogModel(Path(pwd(),""), Path(pwd(),""))
#     # The display properties include the title of the file dialog and what
#     # action string is to be displayed on the button.
#     properties = FileDialogDisplayProperties("Open File###"*keystr, "Open###"*keystr, ImVec2(0,0), 100, 100)
#     # The importer is triggered once the user has confirmed the selection of a
#     # particular path.
#     load_csv = CSVImporter(false, CSVSchema(vendor, product, data))
#
#     ModelViewControl(control, model, properties, load_csv)
# end
