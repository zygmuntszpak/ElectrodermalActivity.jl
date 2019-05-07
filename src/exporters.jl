function create_export_context(vendor::AbstractVendor, product::AbstractProduct, data::AbstractData, keystr::String)
    # The controller is responsible for instantiating the dialog GUI,
    # handling user input and tiggering the file importer once the user
    # confirms the selection of a particular file.
    control = FileDialogControl(true)
    # The model store the path that the user has confirmed, as well as the
    # path that the user has selected but not necessarily confirmed.
    model = FileDialogModel(Path(pwd(),""), Path(pwd(),""))
    # The display properties include the title of the file dialog and what
    # action string is to be displayed on the button.
    properties = FileDialogDisplayProperties(caption = "Save File###"*keystr, action = "Save###"*keystr)
    # The importer is triggered once the user has confirmed the selection of a
    # particular path.
    store_csv = CSVExporter(false, CSVSchema(vendor, product, data))
    # Construct a context and assign roles to complete the requisite export interactions.
    ExportContext(control, model, properties, store_csv)
end


function (store::CSVExporter{<:AbstractSchema})(path::Path, eda::ElectrodermalData, li::LabelledIntervals)
    @show "Storing Electrodermal Data"
    df = DataFrame(Data=String[])
    timestamp = get_timestamp(eda)
    frequency = get_sampling_frequency(eda)
    raw_eda = get_unprocessed_eda(eda)
    df = DataFrame(Raw = vcat(timestamp, frequency, raw_eda))
    labelled_intervals = get_labelled_intervals(li)
    for (key, labelled_interval) in pairs(labelled_intervals)
        nested_interval = labelled_interval.nested_interval
        start = get_start(nested_interval)
        stop = get_stop(nested_interval)
        indicator = [ start <= i <= stop ? 1.0 : 0.0 for i = 1:length(raw_eda)]
        df = hcat(df, DataFrame([vcat(timestamp, frequency, indicator)], [Symbol(key)]))
    end
    store(path, df)
end
