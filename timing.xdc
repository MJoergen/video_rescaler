############################################################################################################
## Democore timing constraints
############################################################################################################
create_generated_clock -name vga_clk   -source [get_pins i_democore/i_democore_clk/i_clk_108/CLKOUT0] -divide_by 4    [get_pins i_democore/i_democore_clk/vga_counter_reg[1]/Q]
create_generated_clock -name audio_clk -source [get_pins i_democore/i_democore_clk/i_clk_108/CLKOUT0] -divide_by 2250 [get_pins i_democore/i_democore_clk/audio_counter_reg[11]/Q]


############################################################################################################
## MEGA65 timing
############################################################################################################

## Primary clock input
create_clock -period 10.000 -name clk [get_ports clk]

# Rename autogenerated clocks
create_generated_clock -name kbd_clk    [get_pins i_framework/i_clk/i_clk_hyperram/CLKOUT0]
create_generated_clock -name clk_x2     [get_pins i_framework/i_clk/i_clk_hyperram/CLKOUT1]
create_generated_clock -name clk_x2_del [get_pins i_framework/i_clk/i_clk_hyperram/CLKOUT2]
create_generated_clock -name clk_x1     [get_pins i_framework/i_clk/i_clk_hyperram/CLKOUT3]
create_generated_clock -name o_clk      [get_pins i_framework/i_clk/i_clk_hdmi/CLKOUT1]
create_generated_clock -name hdmi_clk   [get_pins i_framework/i_clk/i_clk_hdmi/CLKOUT2]

## Set location (based on closest to I/O pad).
## This forces the placement of the entire HyperRAM controller.
#set_property LOC SLICE_X0Y205 [get_cells -hier hr_ck_o_reg]
#set_property LOC SLICE_X0Y207 [get_cells -hier hr_rwds_oe_o_reg]
#set_property LOC SLICE_X1Y207 [get_cells -hier rwds_in_x2_reg]
#set_property LOC SLICE_X0Y209 [get_cells -hier hr_dq_oe_o_reg]
#
## Timing from keyboard to ascal is asynchronous
#set_clock_groups -asynchronous -group [get_clocks kbd_clk] -group [get_clocks vga_clk]
#set_clock_groups -asynchronous -group [get_clocks kbd_clk] -group [get_clocks o_clk]
#
#set_clock_groups -group [get_clocks kbd_clk] -group [get_clocks vga_clk]
#
## MEGA65 I/O timing is ignored (considered asynchronous)
#set_false_path -from [get_ports reset_n]
#set_false_path   -to [get_ports hdmi_data_p[*]]
#set_false_path   -to [get_ports hdmi_clk_p]
#set_false_path   -to [get_ports kb_io0]
#set_false_path   -to [get_ports kb_io1]
#set_false_path -from [get_ports kb_io2]
#
## Timing between ascal and HyperRAM is asynchronous
#set_false_path -from [get_clocks clk_x1]    -to [get_clocks vga_clk]
#set_false_path   -to [get_clocks clk_x1]  -from [get_clocks vga_clk]
#set_false_path -from [get_clocks clk_x1]    -to [get_clocks o_clk]
#set_false_path   -to [get_clocks clk_x1]  -from [get_clocks o_clk]
#set_false_path -from [get_clocks vga_clk]   -to [get_clocks o_clk]
#set_false_path   -to [get_clocks vga_clk] -from [get_clocks o_clk]
#
