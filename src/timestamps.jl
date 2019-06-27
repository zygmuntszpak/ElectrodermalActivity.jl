struct TimestampResolver{T₁ <: AbstractString, T₂ <: Number, T₃ <: Number} <: Function
    timezone::T₁
    timestamp::T₂
    intersample_duration::T₃
    nested_interval::NestedInterval
end

function get_timezone(resolver::TimestampResolver)
    resolver.timezone
end

function get_timestamp(resolver::TimestampResolver)
    resolver.timestamp
end

function get_intersample_duration(resolver::TimestampResolver)
    resolver.intersample_duration
end

function get_nested_interval(resolver::TimestampResolver)
    resolver.nested_interval
end




function (resolve_timestamp::TimestampResolver)(x::Number)
    # All times are in milliseconds
    timezone = resolve_timestamp.timezone
    nested_interval = resolve_timestamp.nested_interval
    t₀ = resolve_timestamp.timestamp
    tₛ = get_start(nested_interval) * resolve_timestamp.intersample_duration
    tₙ = x * resolve_timestamp.intersample_duration
    # Display timestamp.
    timestamp₀ = Dates.unix2datetime(Dates.value(Second(t₀) + round(Millisecond(tₛ + tₙ), Dates.Second)))
    # TODO Make the timezone a parameter of the TimestampResolver
    timestamp₁ = ZonedDateTime(timestamp₀, TimeZone(timezone, TimeZones.Class(:ALL)); from_utc = true)
    timestr = Dates.format(timestamp₁ , dateformat"HH:MM:SS")
end
