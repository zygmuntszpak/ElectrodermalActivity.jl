struct DurationResolver{T₁ <: Number} <: Function
    intersample_duration::T₁
    nested_interval::NestedInterval
end

function (resolve_duration::DurationResolver)(n::Nothing)
    # All times are in milliseconds
    nested_interval = resolve_duration.nested_interval
    tₛ = (get_stop(nested_interval) - get_start(nested_interval)) * resolve_duration.intersample_duration
    # Display timestamp.
    #timestamp = Dates.epochms2datetime(Dates.value(Millisecond(tₛ)))
    #timestr = Dates.format(timestamp , dateformat"HH:MM:SS")
    timestr = Dates.canonicalize(Dates.CompoundPeriod(Dates.Millisecond(tₛ)))
    string(timestr)
end
