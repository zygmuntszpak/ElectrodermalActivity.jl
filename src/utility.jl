function prepare_heartrate(directory::String, annotations_filename::String)
    annotations_path = joinpath(directory, annotations_filename)
    eda_path = joinpath(directory, "EDA.csv")
    hr_path = joinpath(directory, "HR.csv")

    #data = CSV.File(annotations_path; header = ["label","start","stop","first","step","last"]) |> DataFrame
    annotations = CSV.File(annotations_path) |> DataFrame
    eda = CSV.File(eda_path; header = ["EDA"]) |> DataFrame
    hr = CSV.File(hr_path; header = ["HR"]) |> DataFrame

    eda_timestamp = eda[1,1]
    eda_frequency = eda[2,1]

    hr_timestamp = hr[1,1]
    hr_frequency = hr[2,1]

    # Difference between the start of heart rate measurement versus eda measurement
    Δ = Int(hr_timestamp - eda_timestamp)


    # Number of actual heartrate samples
    N = size(hr,1) - 2
    # Number of annotations
    L, _ = size(annotations)

    for l = 1:L
        eda_start_index = annotations[l,:start]
        eda_stop_index = annotations[l,:stop]

        eda_start_seconds = floor(Int, eda_start_index / 4)
        eda_stop_seconds = floor(Int, eda_stop_index / 4)

        hr_start_seconds = eda_start_seconds - Δ
        hr_stop_seconds = eda_stop_seconds - Δ

        hr_start_index = Int(hr_start_seconds * hr_frequency)
        hr_stop_index = Int(hr_stop_seconds * hr_frequency)

        indicator = [hr_start_index <= i <= hr_stop_index ? 1 : 0 for i = 1:N]
        key = annotations[l,:label]
        hr = hcat(hr, DataFrame([vcat(hr_timestamp, hr_frequency, indicator)], [Symbol(key)]))
    end
    hr
    CSV.write(joinpath(directory, "HR_annotated.csv"), hr)
    #hr

    #eda
    #annotations
    #hr

    #hr[3:end,:]
    #hr = hr[3:end]


    #df = load_dataframe(annotations_path, ["EDA"])
end
