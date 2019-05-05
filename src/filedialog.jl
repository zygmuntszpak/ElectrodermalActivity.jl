abstract type AbstractDialog end
abstract type AbstractStatus end
mutable struct FileDialog <: AbstractDialog
    action_string::String
    action_button_string::String
    directory::String
    file::String
    unconfirmed_directory::String
    unconfirmed_file::String
    visible::Bool
    unprocessed_action::Bool
end

struct ConfirmedStatus <: AbstractStatus end
struct UnconfirmedStatus <: AbstractStatus end

function get_action_string(dialog::FileDialog)
    dialog.action_string
end

function set_action_string!(dialog::FileDialog, action_string::String)
    dialog.action_string = action_string
end

function get_action_button_string(dialog::FileDialog)
    dialog.action_button_string
end

function set_action_button_string!(dialog::FileDialog, action_button_string::String)
    dialog.action_button_string = action_button_string
end


function get_directory(dialog::FileDialog, status::UnconfirmedStatus)
    dialog.unconfirmed_directory
end

function get_directory(dialog::FileDialog, status::ConfirmedStatus)
    dialog.directory
end

function get_file(dialog::FileDialog, status::ConfirmedStatus)
    dialog.file
end

function get_file(dialog::FileDialog, status::UnconfirmedStatus)
    dialog.unconfirmed_file
end

function set_directory!(dialog::FileDialog, directory_path::String, status::ConfirmedStatus)
    dialog.directory = directory_path
end

function set_directory!(dialog::FileDialog, directory_path::String, status::UnconfirmedStatus)
    dialog.unconfirmed_directory = directory_path
end

function set_file!(dialog::FileDialog, file_name::String, status::ConfirmedStatus)
    dialog.file = file_name
end
function set_file!(dialog::FileDialog, file_name::String, status::UnconfirmedStatus)
    dialog.unconfirmed_file = file_name
end

function isvisible(dialog::FileDialog)
    dialog.visible
end

function isconfirmed(dialog::FileDialog)
    dialog.confirmed
end

function set_visibility!(dialog::FileDialog, flag::Bool)
    dialog.visible = flag
end

function has_pending_action(dialog::FileDialog)
    dialog.unprocessed_action
end

function signal_action!(dialog::FileDialog)
    dialog.unprocessed_action = true
end

function consume_action!(dialog::FileDialog)
    dialog.unprocessed_action = false
end

function display_dialog!(dialog::FileDialog)
    str = get_action_string(dialog)
    @c CImGui.Begin(str, &dialog.visible)
        display_path!(dialog)
        display_directory_file_listing!(dialog)
        handle_unconfirmed_file!(dialog)
        deal_with_file_confirmation!(dialog)
        handle_file_error_messaging()
    CImGui.End()
end

function display_path!(dialog::FileDialog)
    path_directories = splitpath(get_directory(dialog, UnconfirmedStatus()))
    selected_directory = Cint(length(path_directories))
    # Draw a button for each directory that constitutes the current path.
    for (index, d) in enumerate(path_directories)
        CImGui.Button(d) && (selected_directory = Cint(index);)
        CImGui.SameLine()
    end
    # If a button is clicked then we keep only the path up-to and including the clicked button.
    path = selected_directory == 1 ? joinpath(first(path_directories)) : joinpath(path_directories[1:selected_directory]...)
    set_directory!(dialog, path, UnconfirmedStatus())
end

function display_directory_file_listing!(dialog::FileDialog)
    # Make a list of directories that are visibile from the current directory.
    CImGui.NewLine()
    CImGui.BeginChild("Directory and File Listing", CImGui.ImVec2(CImGui.GetWindowWidth() * 0.98, -CImGui.GetWindowHeight() * 0.2))
        CImGui.Columns(1)
        deal_with_directory_selection!(dialog)
        deal_with_file_selection!(dialog)
    CImGui.EndChild()
end

function handle_unconfirmed_file!(dialog::FileDialog)
    CImGui.Text("File Name:")
    CImGui.SameLine()
    file_name₀ = get_file(dialog, UnconfirmedStatus())
    file_name₁ = file_name₀*"\0"^(1)
    # Allow up to 255 characters for the filename.
    pad_nul = max(0, 255 - length(file_name₁) + 1)
    buffer = file_name₁*"\0"^(pad_nul)
    CImGui.InputText("",buffer, length(buffer))
    file_name₂ = extract_string(buffer)
    set_file!(dialog, file_name₂, UnconfirmedStatus())
end

function extract_string(buffer)
    first_nul = findfirst(isequal('\0'), buffer) - 1
    buffer[1:first_nul]
end

function deal_with_directory_selection!(dialog::FileDialog)
    path = get_directory(dialog, UnconfirmedStatus())
    visible_directories = filter(p->is_readable_dir(joinpath(path, p)), readdir(path))
    for (n, folder_name) in enumerate(visible_directories)
        # When the user clicks on a directory then change directory by appending the selected directory to the current path.
        if CImGui.Selectable("[Dir] " * "$folder_name")
            set_directory!(dialog, joinpath(path, folder_name), UnconfirmedStatus())
            set_file!(dialog, "", UnconfirmedStatus())
        end
    end
end

# The isdir function might not have permissions to query certan folders and
# will thus throw an ERROR: "IOError: stat: permission denied (EACCES)"
function is_readable_dir(path)
    flag = false
    try
        flag = isdir(path)
    catch x
        flag = false
    end
    return flag
end

function deal_with_file_selection!(dialog::FileDialog)
    path = get_directory(dialog, UnconfirmedStatus())
    visible_files = filter(p->is_queryable_file(joinpath(path, p)), readdir(path))
    selected_file = Cint(0)
    for (n, file_name) in enumerate(visible_files)
        if CImGui.Selectable("[File] " * "$file_name")
            set_file!(dialog, file_name, UnconfirmedStatus())
        end
    end
end

# The isfile function might not have permissions to query certan files and
# will thus throw an ERROR: "IOError: stat: permission denied (EACCES)"
function is_queryable_file(path)
    flag = false
    try
        flag = isfile(path)
    catch x
        flag = false
    end
    return flag
end

function deal_with_file_confirmation!(dialog::FileDialog)
    CImGui.Button("Cancel") && (deal_with_cancellation!(dialog);)
    CImGui.SameLine()
    str = get_action_button_string(dialog)
    CImGui.Button(str) && (deal_with_confirmation!(dialog);)
end

function deal_with_cancellation!(dialog::FileDialog)
    set_visibility!(dialog, false)
end

function deal_with_confirmation!(dialog::FileDialog)
    directory = get_directory(dialog, UnconfirmedStatus())
    file_name = get_file(dialog, UnconfirmedStatus())
    path = joinpath(directory, file_name)
    if is_queryable_file(path)
        set_visibility!(dialog, false)
        set_directory!(dialog, get_directory(dialog, UnconfirmedStatus()), ConfirmedStatus())
        set_file!(dialog, get_file(dialog, UnconfirmedStatus()), ConfirmedStatus())
        signal_action!(dialog)
    else
        CImGui.OpenPopup("Does the file exist?")
    end
end

function handle_file_error_messaging()
    if CImGui.BeginPopupModal("Does the file exist?", C_NULL, CImGui.ImGuiWindowFlags_AlwaysAutoResize)
        CImGui.Text("Unable to access the specified file.\nPlease verify that: \n   (1) the file exists; \n   (2) you have permission to access the file.\n\n")
        CImGui.Separator()
        CImGui.Button("OK", (120, 0)) && CImGui.CloseCurrentPopup()
        CImGui.SetItemDefaultFocus()
        CImGui.EndPopup()
    end

    if CImGui.BeginPopupModal("Do you have permission to read the file?", C_NULL, CImGui.ImGuiWindowFlags_AlwaysAutoResize)
        CImGui.Text("Unable to access the specified file.\nPlease verify that: \n   (1) the file exists; \n   (2) you have permission to read the file.\n\n")
        CImGui.Separator()
        CImGui.Button("OK", (120, 0)) && CImGui.CloseCurrentPopup()
        CImGui.SetItemDefaultFocus()
        CImGui.EndPopup()
    end

    if CImGui.BeginPopupModal("Do you have permission to modify the file?", C_NULL, CImGui.ImGuiWindowFlags_AlwaysAutoResize)
        CImGui.Text("Unable to write to the specified file.\nPlease verify that: \n   (1) the file exists; \n   (2) you have permission to modify the file.\n\n")
        CImGui.Separator()
        CImGui.Button("OK", (120, 0)) && CImGui.CloseCurrentPopup()
        CImGui.SetItemDefaultFocus()
        CImGui.EndPopup()
    end

    if CImGui.BeginPopupModal("Has the file been corrupted?", C_NULL, CImGui.ImGuiWindowFlags_AlwaysAutoResize)
        CImGui.Text("Unable to open the specified file.\nPlease verify that: \n   (1) the file has not been corrupted; \n   (2) you have permission to access the file.\n\n")
        CImGui.Separator()
        CImGui.Button("OK", (120, 0)) && CImGui.CloseCurrentPopup()
        CImGui.SetItemDefaultFocus()
        CImGui.EndPopup()
    end
end

function is_openable_file(path)
    try
        open(identity, path)
        return true
    catch
        return false
    end
end

function is_readable_file(path)
    if is_queryable_file(path)
        return (uperm(path) & 0x04 > 0) ? true :  false
    else
        return false
    end
end

function is_writeable_file(path)
    if is_queryable_file(path)
        return (uperm(path) & 0x02 > 0) ?  true :  false
    else
        return false
    end
end

# function is_valid_selection(dialog::AbstractDialog)
#     directory = get_directory(dialog, UnconfirmedStatus())
#     file_name = get_file(dialog, UnconfirmedStatus())
#     path = joinpath(directory, file_name)
#     if is_readable_file(path)
#         #return true
#     else
#         CImGui.OpenPopup("Delete?")
#         @show "opened popup"
#          # if CImGui.BeginPopupModal("Delete?", C_NULL, CImGui.ImGuiWindowFlags_AlwaysAutoResize)
#          #    @show "inside"
#          #    CImGui.EndPopup()
#          # end
#         # CImGui.OpenPopup("Delete?")
#         # if CImGui.BeginPopupModal("Delete?", C_NULL, CImGui.ImGuiWindowFlags_AlwaysAutoResize)
#         #     CImGui.Text("All those beautiful files will be deleted.\nThis operation cannot be undone!\n\n")
#         #     CImGui.Separator()
#         #
#         #     # @cstatic dummy_i=Cint(0) @c CImGui.Combo("Combo", &dummy_i, "Delete\0Delete harder\0")
#         #
#         #     @cstatic dont_ask_me_next_time=false begin
#         #         CImGui.PushStyleVar(CImGui.ImGuiStyleVar_FramePadding, (0, 0))
#         #         @c CImGui.Checkbox("Don't ask me next time", &dont_ask_me_next_time)
#         #         CImGui.PopStyleVar()
#         #     end
#         #
#         #     CImGui.Button("OK", (120, 0)) && CImGui.CloseCurrentPopup()
#         #     CImGui.SetItemDefaultFocus()
#         #     CImGui.SameLine()
#         #     CImGui.Button("Cancel",(120, 0)) && CImGui.CloseCurrentPopup()
#         #     CImGui.EndPopup()
#         # end
#         #return false
#     end
#     return true
# end
