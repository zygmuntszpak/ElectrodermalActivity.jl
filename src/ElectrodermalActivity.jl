module ElectrodermalActivity

using CImGui
using CImGui.CSyntax
using CImGui.CSyntax.CStatic
using CImGui.GLFWBackend
using CImGui.OpenGLBackend
using CImGui.GLFWBackend.GLFW
using CImGui.OpenGLBackend.ModernGL
using CImGui: ImVec2, ImVec4, IM_COL32, ImU32
using CImGuiExtensions
using DataFrames
using Dates
using TimeZones
using LinearAlgebra
using DSP
using CSV # Temporarily needed for prepare_heartrate fix.

include("electrodermal.jl")
include("tags.jl")
include("control.jl")
include("vendors.jl")
include("duration.jl")
include("timestamps.jl")
include("timezones.jl")
include("importers.jl")
include("exporters.jl")
include("menubar.jl")
include("main.jl")
include("utility.jl")


export launch,
       prepare_heartrate,
       prepare_empatica

end # module
