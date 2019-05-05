# struct OpenEmpaticaFileDialog{T₁ <: AbstractProduct, T₂ <: AbstractData}
#     product::T₁
#     data::T₂
#     dialog::OpenFileDialog
# end
#
# function get_dialog(dispatch::OpenEmpaticaFileDialog)
#     dispatch.dialog
# end
#
# function get_data(dispatch::OpenEmpaticaFileDialog)
#     dispatch.data
# end
