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


function prepare_empatica(in_directory::String, out_directory::String, names::NamedTuple, offsets::NamedTuple)
    eda_path = joinpath(in_directory, "EDA.csv")
    hr_path = joinpath(in_directory, "HR.csv")
    tags_path = joinpath(in_directory, "tags.csv")
    ibi_path = joinpath(in_directory, "IBI.csv")


    eda = CSV.File(eda_path; header = ["EDA"]) |> DataFrame
    hr = CSV.File(hr_path; header = ["HR"]) |> DataFrame
    tags = CSV.File(tags_path; header = ["TAGS"]) |> DataFrame
    ibi = CSV.File(ibi_path; header = ["Timestamps", "IBI"]) |> DataFrame

    eda_timestamp = eda[1,1]
    eda_frequency = eda[2,1]

    Δt = (1 / eda_frequency) * 1000
    time₀ = Δt
    time₁ = Δt * length(eda[3:end,1])

    hr_timestamp = hr[1,1]
    hr_frequency = hr[2,1]
    hr_data = hr[3:end,1]

    ibi_timestamp = ibi[1,1]
    ibi_data = ibi[2:end,:]

    #tags

    eda_data = eda[3:end,1]

    eda_processed = prepare_eda(eda_data, eda_timestamp, eda_frequency, tags, names, offsets)
    CSV.write(joinpath(out_directory, "EDA_annotated.csv"), eda_processed)

    ibi_processed = prepare_ibi(ibi_data, ibi_timestamp, tags, names, offsets)
    CSV.write(joinpath(out_directory, "IBI_annotated.csv"), ibi_processed)

    hr_processed = prepare_heart_rate(hr_data, hr_timestamp, hr_frequency, tags, names, offsets)
    CSV.write(joinpath(out_directory, "HR_annotated.csv"), hr_processed)

    # Compute summary statistics (mean and variance) for each condition.
    eda_summary = summarize_eda(eda_processed)
    CSV.write(joinpath(out_directory, "EDA_summarized.csv"), eda_summary)

    hr_summary = summarize_hr(hr_processed)
    CSV.write(joinpath(out_directory, "HR_summarized.csv"), hr_summary)

    eda_processed
    #time₀, time₁, timestamps
end

function extract_tags(tags::DataFrame)
    tag_data = tags.TAGS
    if length(tag_data) != 2
        error("There need to be exactly two entries in tags.csv")
    end
    return tag_data[1], tag_data[2]
end

function prepare_eda(eda, unix_start, eda_frequency, tags::DataFrame, names::NamedTuple, offsets::NamedTuple)
    tag₁, tag₂ = extract_tags(tags)
    seconds_to_tag₁ = tag₁ - unix_start
    seconds_to_tag₂ = tag₂ - unix_start

    #@show seconds_to_tag₁,  seconds_to_tag₂

    interval₁, interval₂, interval₃, interval₄ = determine_intervals(seconds_to_tag₁, seconds_to_tag₂, offsets)

    N = length(eda)
    #@show N
    # Timestep expressed in fractions of a second.
    Δt = (1 / eda_frequency)
    timestamps = range(Δt, step = Δt, length = N)

    indicator₁ = [interval₁.start <= i <= interval₁.stop ? 1.0 : 0.0 for i in timestamps]
    indicator₂ = [interval₂.start <= i <= interval₂.stop ? 1.0 : 0.0 for i in timestamps]
    indicator₃ = [interval₃.start <= i <= interval₃.stop ? 1.0 : 0.0 for i in timestamps]
    indicator₄ = [interval₄.start <= i <= interval₄.stop ? 1.0 : 0.0 for i in timestamps]

    response_type = Lowpass(1; fs = eda_frequency)
    design_method = Butterworth(2)
    eda_filtered = filt(digitalfilter(response_type, design_method), eda)

    # TODO add filtered EDA
    df = DataFrame(Raw = vcat(unix_start, eda_frequency, eda))
    df = hcat(df, DataFrame(Filtered = vcat(unix_start, eda_frequency, eda_filtered)))
    df = hcat(df, DataFrame([vcat(unix_start, eda_frequency, indicator₁)], [Symbol(names.name_1)]))
    df = hcat(df, DataFrame([vcat(unix_start, eda_frequency, indicator₂)], [Symbol(names.name_2)]))
    df = hcat(df, DataFrame([vcat(unix_start, eda_frequency, indicator₃)], [Symbol(names.name_3)]))
    df = hcat(df, DataFrame([vcat(unix_start, eda_frequency, indicator₄)], [Symbol(names.name_4)]))

    return df
end

function prepare_ibi(ibi_data, unix_start, tags::DataFrame, names::NamedTuple, offsets::NamedTuple)
    tag₁, tag₂ = extract_tags(tags)
    seconds_to_tag₁ = tag₁ - unix_start
    seconds_to_tag₂ = tag₂ - unix_start

    interval₁, interval₂, interval₃, interval₄ = determine_intervals(seconds_to_tag₁, seconds_to_tag₂, offsets)

    N = size(ibi_data,2)
    #@show N
    timestamps = ibi_data[:,1]
    interbeat_intervals = ibi_data[:,2]

    indicator₁ = [interval₁.start <= i <= interval₁.stop ? 1.0 : 0.0 for i in timestamps]
    indicator₂ = [interval₂.start <= i <= interval₂.stop ? 1.0 : 0.0 for i in timestamps]
    indicator₃ = [interval₃.start <= i <= interval₃.stop ? 1.0 : 0.0 for i in timestamps]
    indicator₄ = [interval₄.start <= i <= interval₄.stop ? 1.0 : 0.0 for i in timestamps]


    df = DataFrame(Timestamp = vcat(unix_start, timestamps))
    df = hcat(df, DataFrame(IBI = vcat("IBI", interbeat_intervals)))
    df = hcat(df, DataFrame([vcat(unix_start, indicator₁)], [Symbol(names.name_1)]))
    df = hcat(df, DataFrame([vcat(unix_start, indicator₂)], [Symbol(names.name_2)]))
    df = hcat(df, DataFrame([vcat(unix_start, indicator₃)], [Symbol(names.name_3)]))
    df = hcat(df, DataFrame([vcat(unix_start, indicator₄)], [Symbol(names.name_4)]))

    return df
end

function prepare_heart_rate(hr_data, unix_start, hr_frequency, tags::DataFrame, names::NamedTuple, offsets::NamedTuple)
    tag₁, tag₂ = extract_tags(tags)
    seconds_to_tag₁ = tag₁ - unix_start
    seconds_to_tag₂ = tag₂ - unix_start

    #@show seconds_to_tag₁,  seconds_to_tag₂

    interval₁, interval₂, interval₃, interval₄ = determine_intervals(seconds_to_tag₁, seconds_to_tag₂, offsets)

    N = length(hr_data)
    #@show N
    # Timestep expressed in fractions of a second.
    Δt = (1 / hr_frequency)
    timestamps = range(Δt, step = Δt, length = N)

    indicator₁ = [interval₁.start <= i <= interval₁.stop ? 1.0 : 0.0 for i in timestamps]
    indicator₂ = [interval₂.start <= i <= interval₂.stop ? 1.0 : 0.0 for i in timestamps]
    indicator₃ = [interval₃.start <= i <= interval₃.stop ? 1.0 : 0.0 for i in timestamps]
    indicator₄ = [interval₄.start <= i <= interval₄.stop ? 1.0 : 0.0 for i in timestamps]

    df = DataFrame(Raw = vcat(unix_start, hr_frequency, hr_data))
    df = hcat(df, DataFrame([vcat(unix_start, hr_frequency, indicator₁)], [Symbol(names.name_1)]))
    df = hcat(df, DataFrame([vcat(unix_start, hr_frequency, indicator₂)], [Symbol(names.name_2)]))
    df = hcat(df, DataFrame([vcat(unix_start, hr_frequency, indicator₃)], [Symbol(names.name_3)]))
    df = hcat(df, DataFrame([vcat(unix_start, hr_frequency, indicator₄)], [Symbol(names.name_4)]))

    return df
end

function determine_intervals(seconds_to_tag₁::Number, seconds_to_tag₂::Number, offsets::NamedTuple)
    interval₁ = (start = seconds_to_tag₁ - offsets.offset_1,
                 stop =  seconds_to_tag₁)

    interval₂ = (start = seconds_to_tag₁,
                 stop =  seconds_to_tag₁ + offsets.offset_2)

    interval₃ = (start = seconds_to_tag₂ - offsets.offset_3,
                 stop =  seconds_to_tag₂)

    interval₄ = (start = seconds_to_tag₂,
                 stop =  seconds_to_tag₂ + offsets.offset_4)

    return interval₁, interval₂, interval₃, interval₄
end

function summarize_eda(df::AbstractDataFrame)
    interval_1 = df[!, Symbol("Interval 1")] .== 1
    interval_2 = df[!, Symbol("Interval 2")] .== 1
    interval_3 = df[!, Symbol("Interval 3")] .== 1
    interval_4 = df[!, Symbol("Interval 4")] .== 1

    eda = df[!, Symbol("Filtered")]
    eda₁ = eda[interval_1]
    eda₂ = eda[interval_2]
    eda₃ = eda[interval_3]
    eda₄ = eda[interval_4]
    μ₁ = mean(eda₁)
    σ²₁ = var(eda₁)

    μ₂ = mean(eda₂)
    σ²₂ = var(eda₂)

    μ₃ = mean(eda₃)
    σ²₃ = var(eda₃)

    μ₄ = mean(eda₄)
    σ²₄ = var(eda₄)

    df = DataFrame(Labels = vcat("Mean", "Variance", "Log Mean"),
                   Interval_1 = vcat(μ₁, σ²₁, log(μ₁)),
                   Interval_2 = vcat(μ₂, σ²₂, log(μ₂)),
                   Interval_3 = vcat(μ₃, σ²₃, log(μ₃)),
                   Interval_4 = vcat(μ₄, σ²₄, log(μ₄)))

    return df
end

function summarize_hr(df::AbstractDataFrame)
    interval_1 = df[!, Symbol("Interval 1")] .== 1
    interval_2 = df[!, Symbol("Interval 2")] .== 1
    interval_3 = df[!, Symbol("Interval 3")] .== 1
    interval_4 = df[!, Symbol("Interval 4")] .== 1

    hr = df[!, Symbol("Raw")]
    hr₁ = hr[interval_1]
    hr₂ = hr[interval_2]
    hr₃ = hr[interval_3]
    hr₄ = hr[interval_4]
    μ₁ = mean(hr₁)
    σ²₁ = var(hr₁)

    μ₂ = mean(hr₂)
    σ²₂ = var(hr₂)

    μ₃ = mean(hr₃)
    σ²₃ = var(hr₃)

    μ₄ = mean(hr₄)
    σ²₄ = var(hr₄)

    df = DataFrame(Labels = vcat("Mean", "Variance", "Log Mean"),
                   Interval_1 = vcat(μ₁, σ²₁, log(μ₁)),
                   Interval_2 = vcat(μ₂, σ²₂, log(μ₂)),
                   Interval_3 = vcat(μ₃, σ²₃, log(μ₃)),
                   Interval_4 = vcat(μ₄, σ²₄, log(μ₄)))

    return df
end

# offsets = (offset_1 = seconds_prior_marker_1,
#            offset_2 = seconds_after_marker_1,
#            offset_3 = seconds_prior_marker_2,
#            offset_4 = seconds_after_marker_2)
