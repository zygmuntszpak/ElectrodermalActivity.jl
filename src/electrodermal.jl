import Base.isempty
mutable struct ElectrodermalData{T₁ <: Number} <: AbstractModel
    timestamp::Float64
    sampling_frequency::Int
    unprocessed_eda::Vector{T₁}
    eda::Vector{T₁}
end

function get_timestamp(e::ElectrodermalData)
    e.timestamp
end

function set_timestamp!(e::ElectrodermalData, timestamp::Float64)
    e.timestamp = timestamp
end

function get_sampling_frequency(e::ElectrodermalData)
    e.sampling_frequency
end

function set_sampling_frequency!(e::ElectrodermalData, sampling_frequency::Int)
    e.sampling_frequency = sampling_frequency
end

function get_unprocessed_eda(e::ElectrodermalData)
    e.unprocessed_eda
end

function set_unprocessed_eda!(e::ElectrodermalData, eda::AbstractVector)
    e.unprocessed_eda = eda
end

function get_eda(e::ElectrodermalData)
    e.eda
end

function set_eda!(e::ElectrodermalData, eda::AbstractVector)
    e.eda = eda
end

function isempty(e::ElectrodermalData)
    isempty(get_unprocessed_eda(e))
end
