module ElectrodermalActivity

using CImGui
using CImGui.CSyntax
using CImGui.CSyntax.CStatic
using CImGui.GLFWBackend
using CImGui.OpenGLBackend
using CImGui.GLFWBackend.GLFW
using CImGui.OpenGLBackend.ModernGL
using CImGui: ImVec2, ImVec4, IM_COL32, ImU32
using Printf
using DataFrames
using CSV
using Dates

include("filedialog.jl")
include("time_selector.jl")
include("event.jl")
include("gui.jl")

export launch

end # module
