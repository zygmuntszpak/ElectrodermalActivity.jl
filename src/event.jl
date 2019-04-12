abstract type AbstractDuration end
mutable struct MarkedInterval <: AbstractDuration
    label::String
    time_interval::TimeSelector
end

function set_label!(i::MarkedInterval, str::String)
    i.label = str
end


function get_label(i::MarkedInterval)
    i.label
end

function get_time_interval(i::MarkedInterval)
    i.time_interval
end

function set_time_interval!(i::MarkedInterval, ts::TimeSelector)
    i.time_interval =  ts
end
