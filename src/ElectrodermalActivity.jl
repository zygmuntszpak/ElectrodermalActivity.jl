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
using DSP

include("electrodermal.jl")
include("tags.jl")
include("control.jl")
include("vendors.jl")
include("duration.jl")
include("timestamps.jl")
include("importers.jl")
include("exporters.jl")
include("menubar.jl")
include("main.jl")


export run_gui,
       ModelViewControl



end # module
