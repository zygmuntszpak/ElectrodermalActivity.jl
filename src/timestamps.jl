struct TimestampResolver{T₁ <: Number, T₂ <: Number} <: Function
    timestamp::T₁
    intersample_duration::T₂
    nested_interval::NestedInterval
end

function (resolve_timestamp::TimestampResolver)(x::Number)
    # All times are in milliseconds
    nested_interval = resolve_timestamp.nested_interval
    t₀ = resolve_timestamp.timestamp
    tₛ = get_start(nested_interval) * resolve_timestamp.intersample_duration
    tₙ = x * resolve_timestamp.intersample_duration
    # Display timestamp.
    #timestamp₀ = Dates.epochms2datetime(Dates.value(Millisecond(t₀ + tₛ + tₙ)))
    timestamp₀ = Dates.unix2datetime(Dates.value(Second(t₀) + round(Millisecond(tₛ + tₙ), Dates.Second)))
    # TODO Make the timezone a parameter of the TimestampResolver
    timestamp₁ = ZonedDateTime(timestamp₀, tz"Australia/Adelaide"; from_utc = true)
    timestr = Dates.format(timestamp₁ , dateformat"HH:MM:SS")
end
