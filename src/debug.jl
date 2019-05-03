using CSV
using DataFrames
using DSP

f = CSV.File(joinpath(pwd(),"EDA.csv"), header=["EDA"]) |> DataFrame
eda = Array{Union{Missing, Float64},1}(undef, 0)




ts = 0.0
hz = 4.0
eda = f[:EDA]
ts = eda[1]
hz = eda[2]
eda = Float64.(eda[4:end])





min_val = minimum(eda)
max_val = maximum(eda)

map( x-> Float32(stretch_linearly(x, min_val, max_val, 0, 200)), eda)

interval = range(min_val, max_val, length = 20)


range()

path = pwd()

filter(p->isdir(p), readdir(path))

a = ["ArtificialPotentialFields", "EDA", "ElectrodermalActivity", "HistogramThresholding", "ImageBinarization", "ImageComponentAnalysis", "ImageContrastAdjustment", "ImageFiltering", "ImageTracking", "Images", "IntegralHistograms", "Interpolations", "MultipleViewGeometry", "PictureSegmentation", "SeedAnalysis", "StaticArrays", "TestImages", "TestPkg", "VideoIO"]

filter(isdir,  readdir(path))

function foo()
    f = CSV.File(joinpath(pwd(),"EDA.csv"), header=["EDA"]) |> DataFrame
    eda::Array{Float64,1} = f[:EDA]
end

function stretch_linearly(x, A, B, a, b)
    (x-A) * ((b-a) / (B-A)) + a
end
