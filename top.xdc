#############################################################################################################
# Pin locations and I/O standards
#############################################################################################################

## External clock signal (connected to 100 MHz oscillator)
set_property -dict {PACKAGE_PIN V13  IOSTANDARD LVCMOS33}                                    [get_ports {clk}]

## Reset signal (Active low. From MAX10)
set_property -dict {PACKAGE_PIN M13  IOSTANDARD LVCMOS33}                                    [get_ports {reset_n}]

## HyperRAM (connected to IS66WVH8M8BLL-100B1LI, 64 Mbit, 100 MHz, 3.0 V, single-ended clock).
## SLEW and DRIVE set to maximum performance to reduce rise and fall times, and therefore
## give better timing margins.
set_property -dict {PACKAGE_PIN B22  IOSTANDARD LVCMOS33  PULLUP FALSE}                      [get_ports {hr_resetn}]
set_property -dict {PACKAGE_PIN C22  IOSTANDARD LVCMOS33  PULLUP FALSE}                      [get_ports {hr_csn}]
set_property -dict {PACKAGE_PIN D22  IOSTANDARD LVCMOS33  PULLUP FALSE  SLEW FAST  DRIVE 16} [get_ports {hr_ck}]
set_property -dict {PACKAGE_PIN B21  IOSTANDARD LVCMOS33  PULLUP FALSE  SLEW FAST  DRIVE 16} [get_ports {hr_rwds}]
set_property -dict {PACKAGE_PIN A21  IOSTANDARD LVCMOS33  PULLUP FALSE  SLEW FAST  DRIVE 16} [get_ports {hr_dq[0]}]
set_property -dict {PACKAGE_PIN D21  IOSTANDARD LVCMOS33  PULLUP FALSE  SLEW FAST  DRIVE 16} [get_ports {hr_dq[1]}]
set_property -dict {PACKAGE_PIN C20  IOSTANDARD LVCMOS33  PULLUP FALSE  SLEW FAST  DRIVE 16} [get_ports {hr_dq[2]}]
set_property -dict {PACKAGE_PIN A20  IOSTANDARD LVCMOS33  PULLUP FALSE  SLEW FAST  DRIVE 16} [get_ports {hr_dq[3]}]
set_property -dict {PACKAGE_PIN B20  IOSTANDARD LVCMOS33  PULLUP FALSE  SLEW FAST  DRIVE 16} [get_ports {hr_dq[4]}]
set_property -dict {PACKAGE_PIN A19  IOSTANDARD LVCMOS33  PULLUP FALSE  SLEW FAST  DRIVE 16} [get_ports {hr_dq[5]}]
set_property -dict {PACKAGE_PIN E21  IOSTANDARD LVCMOS33  PULLUP FALSE  SLEW FAST  DRIVE 16} [get_ports {hr_dq[6]}]
set_property -dict {PACKAGE_PIN E22  IOSTANDARD LVCMOS33  PULLUP FALSE  SLEW FAST  DRIVE 16} [get_ports {hr_dq[7]}]

## Keyboard interface (connected to MAX10)
set_property -dict {PACKAGE_PIN A14  IOSTANDARD LVCMOS33}                                    [get_ports {kb_io0}]
set_property -dict {PACKAGE_PIN A13  IOSTANDARD LVCMOS33}                                    [get_ports {kb_io1}]
set_property -dict {PACKAGE_PIN C13  IOSTANDARD LVCMOS33}                                    [get_ports {kb_io2}]

# HDMI output
set_property -dict {PACKAGE_PIN Y1   IOSTANDARD TMDS_33}  [get_ports {hdmi_clk_n}]
set_property -dict {PACKAGE_PIN W1   IOSTANDARD TMDS_33}  [get_ports {hdmi_clk_p}]
set_property -dict {PACKAGE_PIN AB1  IOSTANDARD TMDS_33}  [get_ports {hdmi_data_n[0]}]
set_property -dict {PACKAGE_PIN AA1  IOSTANDARD TMDS_33}  [get_ports {hdmi_data_p[0]}]
set_property -dict {PACKAGE_PIN AB2  IOSTANDARD TMDS_33}  [get_ports {hdmi_data_n[1]}]
set_property -dict {PACKAGE_PIN AB3  IOSTANDARD TMDS_33}  [get_ports {hdmi_data_p[1]}]
set_property -dict {PACKAGE_PIN AB5  IOSTANDARD TMDS_33}  [get_ports {hdmi_data_n[2]}]
set_property -dict {PACKAGE_PIN AA5  IOSTANDARD TMDS_33}  [get_ports {hdmi_data_p[2]}]

## VGA via VDAC
set_property -dict {PACKAGE_PIN U15  IOSTANDARD LVCMOS33} [get_ports {vga_red[0]}]
set_property -dict {PACKAGE_PIN V15  IOSTANDARD LVCMOS33} [get_ports {vga_red[1]}]
set_property -dict {PACKAGE_PIN T14  IOSTANDARD LVCMOS33} [get_ports {vga_red[2]}]
set_property -dict {PACKAGE_PIN Y17  IOSTANDARD LVCMOS33} [get_ports {vga_red[3]}]
set_property -dict {PACKAGE_PIN Y16  IOSTANDARD LVCMOS33} [get_ports {vga_red[4]}]
set_property -dict {PACKAGE_PIN AB17 IOSTANDARD LVCMOS33} [get_ports {vga_red[5]}]
set_property -dict {PACKAGE_PIN AA16 IOSTANDARD LVCMOS33} [get_ports {vga_red[6]}]
set_property -dict {PACKAGE_PIN AB16 IOSTANDARD LVCMOS33} [get_ports {vga_red[7]}]

set_property -dict {PACKAGE_PIN Y14  IOSTANDARD LVCMOS33} [get_ports {vga_green[0]}]
set_property -dict {PACKAGE_PIN W14  IOSTANDARD LVCMOS33} [get_ports {vga_green[1]}]
set_property -dict {PACKAGE_PIN AA15 IOSTANDARD LVCMOS33} [get_ports {vga_green[2]}]
set_property -dict {PACKAGE_PIN AB15 IOSTANDARD LVCMOS33} [get_ports {vga_green[3]}]
set_property -dict {PACKAGE_PIN Y13  IOSTANDARD LVCMOS33} [get_ports {vga_green[4]}]
set_property -dict {PACKAGE_PIN AA14 IOSTANDARD LVCMOS33} [get_ports {vga_green[5]}]
set_property -dict {PACKAGE_PIN AA13 IOSTANDARD LVCMOS33} [get_ports {vga_green[6]}]
set_property -dict {PACKAGE_PIN AB13 IOSTANDARD LVCMOS33} [get_ports {vga_green[7]}]

set_property -dict {PACKAGE_PIN W10  IOSTANDARD LVCMOS33} [get_ports {vga_blue[0]}]
set_property -dict {PACKAGE_PIN Y12  IOSTANDARD LVCMOS33} [get_ports {vga_blue[1]}]
set_property -dict {PACKAGE_PIN AB12 IOSTANDARD LVCMOS33} [get_ports {vga_blue[2]}]
set_property -dict {PACKAGE_PIN AA11 IOSTANDARD LVCMOS33} [get_ports {vga_blue[3]}]
set_property -dict {PACKAGE_PIN AB11 IOSTANDARD LVCMOS33} [get_ports {vga_blue[4]}]
set_property -dict {PACKAGE_PIN Y11  IOSTANDARD LVCMOS33} [get_ports {vga_blue[5]}]
set_property -dict {PACKAGE_PIN AB10 IOSTANDARD LVCMOS33} [get_ports {vga_blue[6]}]
set_property -dict {PACKAGE_PIN AA10 IOSTANDARD LVCMOS33} [get_ports {vga_blue[7]}]

set_property -dict {PACKAGE_PIN W12  IOSTANDARD LVCMOS33} [get_ports vga_hs]
set_property -dict {PACKAGE_PIN V14  IOSTANDARD LVCMOS33} [get_ports vga_vs]

set_property -dict {PACKAGE_PIN AA9  IOSTANDARD LVCMOS33} [get_ports vdac_clk]
set_property -dict {PACKAGE_PIN V10  IOSTANDARD LVCMOS33} [get_ports vdac_sync_n]
set_property -dict {PACKAGE_PIN W11  IOSTANDARD LVCMOS33} [get_ports vdac_blank_n]

set_property -dict {PACKAGE_PIN L6   IOSTANDARD LVCMOS33} [get_ports pwm_l]
set_property -dict {PACKAGE_PIN F4   IOSTANDARD LVCMOS33} [get_ports pwm_r]




############################################################################################################
# Clocks
############################################################################################################

## Primary clock input
create_clock -period 10.000 -name clk [get_ports clk]


########### HypeRAM timing #################
# Rename autogenerated clocks
create_generated_clock -name clk_x2     [get_pins i_framework/i_clk/i_clk_hyperram/CLKOUT1]
create_generated_clock -name clk_x2_del [get_pins i_framework/i_clk/i_clk_hyperram/CLKOUT2]
create_generated_clock -name clk_x1     [get_pins i_framework/i_clk/i_clk_hyperram/CLKOUT3]

# Set location (based on closest to I/O pad).
# This forces the placement of the entire HyperRAM controller.
set_property LOC SLICE_X0Y205 [get_cells -hier hr_ck_o_reg]
set_property LOC SLICE_X0Y207 [get_cells -hier hr_rwds_oe_o_reg]
set_property LOC SLICE_X1Y207 [get_cells -hier rwds_in_x2_reg]
set_property LOC SLICE_X0Y209 [get_cells -hier hr_dq_oe_o_reg]

create_generated_clock -name vga_clk   -source [get_pins i_democore/i_democore_clk/i_clk_108/CLKOUT0] -divide_by 4    [get_pins i_democore/i_democore_clk/vga_counter_reg[1]/Q]
create_generated_clock -name audio_clk -source [get_pins i_democore/i_democore_clk/i_clk_108/CLKOUT0] -divide_by 2250 [get_pins i_democore/i_democore_clk/audio_counter_reg[11]/Q]


########### MEGA65 timing ################
# Rename autogenerated clocks
create_generated_clock -name o_clk      [get_pins i_framework/i_clk/i_clk_hdmi/CLKOUT1]
create_generated_clock -name hdmi_clk   [get_pins i_framework/i_clk/i_clk_hdmi/CLKOUT2]
create_generated_clock -name kbd_clk    [get_pins i_framework/i_clk/i_clk_hyperram/CLKOUT1]

# MEGA65 I/O timing is ignored (considered asynchronous)
set_false_path -from [get_ports reset_n]
set_false_path   -to [get_ports hdmi_data_p[*]]
set_false_path   -to [get_ports hdmi_clk_p]
set_false_path   -to [get_ports kb_io0]
set_false_path   -to [get_ports kb_io1]
set_false_path -from [get_ports kb_io2]

# Timing between ascal and HyperRAM is asynchronous
set_false_path -from [get_clocks clk_x1]    -to [get_clocks vga_clk]
set_false_path   -to [get_clocks clk_x1]  -from [get_clocks vga_clk]
set_false_path -from [get_clocks clk_x1]    -to [get_clocks o_clk]
set_false_path   -to [get_clocks clk_x1]  -from [get_clocks o_clk]
set_false_path -from [get_clocks vga_clk]   -to [get_clocks o_clk]
set_false_path   -to [get_clocks vga_clk] -from [get_clocks o_clk]

# Timing from keyboard to ascal is asynchronous
set_clock_groups -asynchronous -group [get_clocks kbd_clk] -group [get_clocks vga_clk]
set_clock_groups -asynchronous -group [get_clocks kbd_clk] -group [get_clocks o_clk]


#############################################################################################################
# Configuration and Bitstream properties
#############################################################################################################

set_property CONFIG_VOLTAGE                  3.3   [current_design]
set_property CFGBVS                          VCCO  [current_design]
set_property BITSTREAM.GENERAL.COMPRESS      TRUE  [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE     66    [current_design]
set_property CONFIG_MODE                     SPIx4 [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES   [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH   4     [current_design]

