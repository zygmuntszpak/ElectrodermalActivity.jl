using ElectrodermalActivity

# Specify the folder containing the raw Empatica data.
# input_directory = "/home/zygmunt/Downloads/edadata/EDA LAB DATA/107/experiment"
# output_directory = "/home/zygmunt/Downloads/edadata/EDA LAB DATA/107/experiment/processed"
input_directory = "C:/Users/Spock/Documents/Empatica Data/"
output_directory = "C:/Users/Spock/Documents/Empatica Data/processed"


# Create the output_directory if it doesn't already exist.
mkpath(output_directory)

#=
 The marked interval starts a specified number of seconds prior to the
 first marker and ends at the first marker.
=#
interval_name_1 = "Interval 1"
seconds_prior_marker_1 = 60

#=
  The second marked interval starts at the first marker and continues for a specified
  number of seconds.
=#
interval_name_2 = "Interval 2"
seconds_after_marker_1 = 60

#=
 The third marked interval starts a specified number of seconds prior to the
 second marker and ends at the second marker.
=#
interval_name_3 = "Interval 3"
seconds_prior_marker_2 = 60

#=
  The fourth marked interval starts at the second marker and continues for a specified
  number of seconds.
=#
interval_name_4 = "Interval 4"
seconds_after_marker_2 = 60

interval_names = (name_1 = interval_name_1,
                  name_2 = interval_name_2,
                  name_3 = interval_name_3,
                  name_4 = interval_name_4)
offsets = (offset_1 = seconds_prior_marker_1,
           offset_2 = seconds_after_marker_1,
           offset_3 = seconds_prior_marker_2,
           offset_4 = seconds_after_marker_2)

a = prepare_empatica(input_directory, output_directory, interval_names, offsets)

a
b
