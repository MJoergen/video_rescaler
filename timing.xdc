############################################################################################################
# Define clocks
############################################################################################################

## Primary clock input
create_clock -period 10.000 -name clk [get_ports clk]

## MEGA65 clocks
create_generated_clock -name kbd_clk    [get_pins i_framework/i_clk/i_clk_hyperram/CLKOUT0]
create_generated_clock -name clk_x2     [get_pins i_framework/i_clk/i_clk_hyperram/CLKOUT1]
create_generated_clock -name clk_x2_del [get_pins i_framework/i_clk/i_clk_hyperram/CLKOUT2]
create_generated_clock -name clk_x1     [get_pins i_framework/i_clk/i_clk_hyperram/CLKOUT3]
create_generated_clock -name video_clk  [get_pins i_framework/i_clk/i_clk_hdmi/CLKOUT1]
create_generated_clock -name hdmi_clk   [get_pins i_framework/i_clk/i_clk_hdmi/CLKOUT2]

## Democore clocks
create_generated_clock -name clk_108    [get_pins i_democore/i_democore_clk/i_clk_108/CLKOUT0]
create_generated_clock -name vga_clk    -source [get_pins i_democore/i_democore_clk/vga_counter_reg[1]/C]    -divide_by 4    [get_pins i_democore/i_democore_clk/vga_counter_reg[1]/Q]
create_generated_clock -name audio_clk  -source [get_pins i_democore/i_democore_clk/audio_counter_reg[11]/C] -divide_by 2250 [get_pins i_democore/i_democore_clk/audio_counter_reg[11]/Q]


############################################################################################################
## MEGA65 timing
############################################################################################################

# Timing between ascal.vhd and HyperRAM is asynchronous.
set_false_path -from [get_clocks clk_x1]    -to [get_clocks vga_clk]
set_false_path   -to [get_clocks clk_x1]  -from [get_clocks vga_clk]
set_false_path -from [get_clocks clk_x1]    -to [get_clocks video_clk]
set_false_path   -to [get_clocks clk_x1]  -from [get_clocks video_clk]
set_false_path -from [get_clocks vga_clk]   -to [get_clocks video_clk]
set_false_path   -to [get_clocks vga_clk] -from [get_clocks video_clk]

# Place HyperRAM close to I/O pins
startgroup
create_pblock pblock_i_hyperram
resize_pblock pblock_i_hyperram -add {SLICE_X0Y200:SLICE_X7Y224}
add_cells_to_pblock pblock_i_hyperram [get_cells [list i_framework/i_hyperram_wrapper/i_hyperram]]
endgroup

## MEGA65 I/O timing is ignored (considered asynchronous)
#set_false_path -from [get_ports reset_n]
#set_false_path   -to [get_ports hdmi_data_p[*]]
#set_false_path   -to [get_ports hdmi_clk_p]
#set_false_path   -to [get_ports kb_io0]
#set_false_path   -to [get_ports kb_io1]
#set_false_path -from [get_ports kb_io2]


############################################################################################################
## Democore timing constraints
############################################################################################################

set_false_path -from [get_clocks audio_clk] -to [get_clocks clk_108]

