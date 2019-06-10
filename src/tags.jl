import CImGuiExtensions.get_layout
import CImGuiExtensions.get_padding
#import CImGuiExtensions.is_new_window

struct TagsModel{T₁ <: Real, T₂ <: Real, T₃ <: Real, T₄ <: AbstractVector} <: AbstractModel
    unix_start_time::T₁
    start_time::T₂
    stop_time::T₃
    tagged_timestamps::T₄
end

function get_unix_start_time(m::TagsModel)
    m.unix_start_time
end

function get_start_time(m::TagsModel)
    m.start_time
end

function get_stop_time(m::TagsModel)
    m.stop_time
end

function get_timestamps(m::TagsModel)
    m.tagged_timestamps
end

mutable struct TagsControl <: AbstractControl
    isenabled::Bool
end

struct TagsContext{T₁ <: AbstractControl,   T₂ <: AbstractModel,  T₃ <: AbstractDisplayProperties} <: AbstractPlotContext
    control::T₁
    model::T₂
    display_properties::T₃
end

Base.@kwdef struct TagsDisplayProperties{T₁ <: Function, T₂ <: NTuple} <: AbstractDisplayProperties
    id::String
    caption::T₁
    col::ImVec4 = ImVec4(0, 0, 0, 1)
    createwindow::Bool = true
    layout::RectangularLayout
    padding::T₂ = (0, 0, 0 ,0)
end

function (context::TagsContext{<: TagsControl,   <: TagsModel,  <: TagsDisplayProperties})()
    control = context.control
    model = context.model
    display_properties = context.display_properties
    id = get_id(display_properties)
    captioner = get_captioner(display_properties)
    caption = captioner(nothing)
    is_new_window(display_properties) ? CImGui.Begin(caption*id,C_NULL, CImGui.ImGuiWindowFlags_NoBringToFrontOnFocus) : nothing
    isenabled(control) ? control(model, display_properties) : nothing
    is_new_window(display_properties) ? CImGui.End() : nothing
end

function (control::TagsControl)(model::TagsModel, properties::TagsDisplayProperties)
    draw_list = CImGui.GetWindowDrawList()
    id = get_id(properties)
    captioner = get_captioner(properties)
    caption = captioner(nothing)
    col = get_col(properties)
    rectangle = get_layout(properties)
    totalwidth = get_width(rectangle)
    totalheight = get_height(rectangle)
    padding = get_padding(properties)
    tagged_timestamps = get_timestamps(model)
    unix_start_timestamp = get_unix_start_time(model)
    time₀ = get_start_time(model)
    time₁ = get_stop_time(model)
    CImGui.Dummy(ImVec2(0, padding[1]))
    CImGui.Indent(padding[2])
    pos = CImGui.GetCursorScreenPos()
    yoffset = 0
    width = totalwidth - padding[2]
    height = totalheight
    for stamp in tagged_timestamps
        # Convert the difference in unix timestamps to milliseconds
        Δms = (stamp - unix_start_timestamp) * 1000
        xₙ = stretch_linearly(Δms, time₀, time₁, pos.x, pos.x + width)
        CImGui.AddLine(draw_list, ImVec2(xₙ, pos.y + yoffset), ImVec2(xₙ , pos.y + height + yoffset), Base.convert(ImU32, ImVec4(0.9, 0.0, 0.0, 0.9)), Cfloat(2));
    end
    CImGui.Unindent(padding[2])
end

function get_id(p::TagsDisplayProperties)
    p.id
end

function get_captioner(p::TagsDisplayProperties)
    p.caption
end

function get_col(p::TagsDisplayProperties)
    p.col
end

function is_new_window(p::TagsDisplayProperties)
    p.createwindow
end

function get_layout(p::TagsDisplayProperties)
     p.layout
end

function get_padding(p::TagsDisplayProperties)
     p.padding
end
