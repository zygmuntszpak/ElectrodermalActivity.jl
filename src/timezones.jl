import CImGuiExtensions.enable!
import CImGuiExtensions.disable!
import CImGuiExtensions.isenabled
import CImGuiExtensions.isrunning

Base.@kwdef mutable struct TimeZoneModel{T₁ <: AbstractString, T₂ <: Vector{String}} <: AbstractModel
    zone::T₁
    possible_zones::T₂
end

function get_zone(model::TimeZoneModel)
    model.zone
end

function get_possible_zones(model::TimeZoneModel)
    model.possible_zones
end

function set_zone!(model::TimeZoneModel, zone::AbstractString)
    model.zone = zone
end

Base.@kwdef struct TimeZoneDisplayProperties <: AbstractDisplayProperties
end

mutable struct TimeZoneControl <: AbstractControl
    isenabled::Bool
end

mutable struct SelectTimeZone <: AbstractOperation
    isenabled::Bool
end

struct TimeZoneContext{T₁ <: AbstractControl,   T₂ <: AbstractModel,  T₃ <: AbstractDisplayProperties, T₄ <: SelectTimeZone} <: AbstractPlotContext
    control::T₁
    model::T₂
    display_properties::T₃
    action::T₄
end

function isenabled(ctrl::SelectTimeZone)
    return ctrl.isenabled
end

function isenabled(ctrl::TimeZoneControl)
    return ctrl.isenabled
end

function enable!(ctrl::SelectTimeZone)
    ctrl.isenabled = true
end

function enable!(ctrl::TimeZoneControl)
    ctrl.isenabled = true
end

function disable!(ctrl::TimeZoneControl)
    ctrl.isenabled  = false
end

function disable!(ctrl::SelectTimeZone)
    ctrl.isenabled  = false
end

function (context::TimeZoneContext)()
        control = context.control
        model = context.model
        display_properties = context.display_properties
        action = context.action
        isenabled(control) ? control(model, display_properties, action) : nothing
        data = isenabled(action) ? action(get_zone(model)) : nothing
end

function (control::TimeZoneControl)(model::TimeZoneModel, properties::TimeZoneDisplayProperties, action::SelectTimeZone)
    if CImGui.BeginPopupModal("Select Time Zone", C_NULL, CImGui.ImGuiWindowFlags_AlwaysAutoResize)
        items = get_possible_zones(model)
        item_current = get_zone(model)
        # here our selection is a single pointer stored outside the object.
        if CImGui.BeginCombo("", item_current) # the second parameter is the label previewed before opening the combo.
            for n = 0:length(items)-1
                is_selected = item_current == items[n+1]
                CImGui.Selectable(items[n+1], is_selected) && (item_current = items[n+1];)
                is_selected && CImGui.SetItemDefaultFocus() # set the initial focus when opening the combo (scrolling + for keyboard navigation support in the upcoming navigation branch)
            end
            CImGui.EndCombo()
        end
        set_zone!(model, item_current)
        CImGui.Separator()
        CImGui.Button("OK", (120, 0)) && enable!(action) && disable!(control) && CImGui.CloseCurrentPopup()
        CImGui.SetItemDefaultFocus()
        CImGui.EndPopup()
    end
end

function (select::SelectTimeZone)(zone::AbstractString)
    disable!(select)
    zone
end


function isrunning(context::TimeZoneContext)
    isenabled(context.control) || isenabled(context.action)
end

function enable!(context::TimeZoneContext)
    enable!(context.control)
    CImGui.OpenPopup("Select Time Zone")
end
