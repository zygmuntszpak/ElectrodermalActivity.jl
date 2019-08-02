
# function (load::CSVImporter{CSVSchema{Empatica, E4, SkinConductance}})(path::Path)
#     @show "Inside Empatica Skin Conductance importer..."
#     disable!(load)
# end

function create_import_context(vendor::AbstractVendor, product::AbstractProduct, data::AbstractData, keystr::String)
    # The controller is responsible for instantiating the dialog GUI,
    # handling user input and tiggering the file importer once the user
    # confirms the selection of a particular file.
    control = FileDialogControl(true)
    # The model store the path that the user has confirmed, as well as the
    # path that the user has selected but not necessarily confirmed.
    model = FileDialogModel(Path(pwd(),""), Path(pwd(),""))
    # The display properties include the title of the file dialog and what
    # action string is to be displayed on the button.
    properties = FileDialogDisplayProperties(caption = "Open File###"*keystr, action = "Open###"*keystr, width = Cfloat(640), height = Cfloat(395))
    # The importer is triggered once the user has confirmed the selection of a
    # particular path.
    load_csv = CSVImporter(false, CSVSchema(vendor, product, data))
    # Construct a context and assign roles to complete the requisite import interactions.
    ImportContext(control, model, properties, load_csv)
end

function create_import_context(vendor::Empatica, product::E4, data::SkinConductance, keystr::String)
    # The controller is responsible for instantiating the dialog GUI,
    # handling user input and tiggering the file importer once the user
    # confirms the selection of a particular file.
    control = FileDialogControl(true)
    # The model store the path that the user has confirmed, as well as the
    # path that the user has selected but not necessarily confirmed.
    model = FileDialogModel(Path(pwd(),""), Path(pwd(),""))
    # The display properties include the title of the file dialog and what
    # action string is to be displayed on the button.
    properties = FileDialogDisplayProperties(caption = "Open File###"*keystr, action = "Open###"*keystr, width = Cfloat(640), height = Cfloat(395))
    # The importer is triggered once the user has confirmed the selection of a
    # particular path.
    load_csv = CSVImporter(false, CSVSchema(vendor, product, data))
    # Construct a context and assign roles to complete the requisite import interactions.
    ImportContext(control, model, properties, load_csv)
end

function (load::CSVImporter{<:CSVSchema{<: Empatica, <: E4, <: SkinConductance}})(path::Path)
    disable!(load)
    df = load_dataframe(path, ["EDA"])
    if isnothing(df)
        CImGui.OpenPopup("Have you opened the appropriate file?")
        return nothing
    else
        data = df[:EDA]
        timestamp = data[1]
        sampling_frequency = convert(Int,data[2])
        return ElectrodermalData(timestamp , sampling_frequency, data[3:end], data[3:end])
    end
 end

 function (load::CSVImporter{<:CSVSchema{<: Empatica, <: E4, <: Tags}})(path::Path)
     disable!(load)
     df = load_dataframe(path, ["Tags"])
     if isnothing(df)
         CImGui.OpenPopup("Have you opened the appropriate file?")
         return nothing
     else
         data = df[:,1]
         return data
     end
  end
