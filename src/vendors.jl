abstract type AbstractVendor end
abstract type AbstractProduct end
abstract type AbstractData end


struct Empatica <: AbstractVendor end
struct E4 <: AbstractProduct end
struct SkinConductance <: AbstractData end
struct Tags <: AbstractData end
struct IntervalLabels <: AbstractData end
