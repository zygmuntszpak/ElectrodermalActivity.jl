# TODO: Consider constructor which will automatically set correct values
mutable struct TimeSelector{T₁ <: Number, T₂ <: Number, T₃ <: Integer, T₄ <: Integer,  T₅ <: AbstractRange}
    interval₀::T₁
    interval₁::T₁
    x₀::T₁
    x₁::T₂
    t₀::T₃
    t₁::T₄
    timestamps::T₅
end

function set_interval₀!(ts::TimeSelector, interval₀::Number)
     ts.interval₀= interval₀
end

function set_interval₁!(ts::TimeSelector, interval₁::Number)
     ts.interval₁= interval₁
end

function set_x₀!(ts::TimeSelector, x₀::Number)
    i₀ = get_interval₀(ts)
    i₁ = get_interval₁(ts)
    ts.x₀ = x₀ <= i₀ ? i₀ : x₀
end

function set_x₁!(ts::TimeSelector, x₁::Number)
    i₀ = get_interval₀(ts)
    i₁ = get_interval₁(ts)
    ts.x₁ = x₁ >= i₁ ? i₁ : x₁
end

function set_t₀!(ts::TimeSelector, t₀::Integer)
     ts.t₀ = t₀
end

function set_t₁!(ts::TimeSelector, t₁::Number)
     ts.t₁ = t₁
end

function set_timestamps!(ts::TimeSelector, timestamps::AbstractRange)
     ts.timestampes = timestamps
end

get_x₀(ts::TimeSelector) = ts.x₀
get_x₁(ts::TimeSelector) = ts.x₁

get_interval₀(ts::TimeSelector) = ts.interval₀
get_interval₁(ts::TimeSelector) = ts.interval₁

function get_t₀(ts::TimeSelector)
    # timestamps = get_timestamps(ts)
    # x₀ = get_x₀(ts)
    # i₀ = get_interval₀(ts)
    # i₁ = get_interval₁(ts)
    # t₀_ms = round(stretch_linearly(x₀ , i₀,  i₁, first(timestamps), last(timestamps)))
    # #t₀_ms = stretch_linearly(x₀ , i₀,  i₁, first(timestamps), last(timestamps))
    t₀_ms = get_t₀_ms(ts)
    t₀ = Int.(div(t₀_ms, step(get_timestamps(ts))))
end

function get_t₀_ms(ts::TimeSelector)
    timestamps = get_timestamps(ts)
    x₀ = get_x₀(ts)
    i₀ = get_interval₀(ts)
    i₁ = get_interval₁(ts)
    t₀_ms = round(stretch_linearly(x₀ , i₀,  i₁, first(timestamps), last(timestamps)))
end

function get_t₁(ts::TimeSelector)
    #timestamps = get_timestamps(ts)
    # x₁ = get_x₁(ts)
    # i₀ = get_interval₀(ts)
    # i₁ = get_interval₁(ts)
    # t₁_ms = round(stretch_linearly(x₁ , i₀,  i₁, first(timestamps), last(timestamps)))
    #t₁_ms = stretch_linearly(x₁ , i₀,  i₁, first(timestamps), last(timestamps))
    t₁_ms = get_t₁_ms(ts)
    t₁ = Int.(div(t₁_ms, step(get_timestamps(ts))))
end

function get_t₁_ms(ts::TimeSelector)
    timestamps = get_timestamps(ts)
    x₁ = get_x₁(ts)
    i₀ = get_interval₀(ts)
    i₁ = get_interval₁(ts)
    t₁_ms = round(stretch_linearly(x₁ , i₀,  i₁, first(timestamps), last(timestamps)))
end

get_timestamps(ts::TimeSelector) = ts.timestamps

function Base.copy(ts::TimeSelector)
    i₀ = get_interval₀(ts)
    i₁ = get_interval₁(ts)
    x₀ = get_x₀(ts)
    x₁ = get_x₁(ts)
    t₀ = get_t₀(ts)
    t₁ = get_t₁(ts)
    timestamps = get_timestamps(ts)
    ts₂ = TimeSelector(i₀, i₁, x₀, x₁, t₀, t₁, timestamps)
end
