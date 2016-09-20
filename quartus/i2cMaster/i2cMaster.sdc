## Generated SDC file "cordic.sdc"

## Copyright (C) 1991-2015 Altera Corporation. All rights reserved.
## Your use of Altera Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Altera Program License 
## Subscription Agreement, the Altera Quartus Prime License Agreement,
## the Altera MegaCore Function License Agreement, or other 
## applicable license agreement, including, without limitation, 
## that your use is for the sole purpose of programming logic 
## devices manufactured by Altera and sold by Altera or its 
## authorized distributors.  Please refer to the applicable 
## agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 15.1.0 Build 185 10/21/2015 SJ Standard Edition"

## DATE    "Fri May 20 17:18:08 2016"

##
## DEVICE  "5CSXFC6D6F31C8"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3


#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {clk} -period 5.000 -waveform { 0.000 2.500 } [get_ports {clk}]


#**************************************************************
# Create Generated Clock
#**************************************************************



#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************


#**************************************************************
# Set Input Delay
#**************************************************************
set_input_delay -add_delay  -clock [get_clocks {clk}]  1.000 [get_ports {reset}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  1.000 [get_ports {avsAdr[*]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  1.000 [get_ports {avsWr}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  1.000 [get_ports {avsWrData[*]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  1.000 [get_ports {avsRd}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  1.000 [get_ports {sdat}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  1.000 [get_ports {sclk}]

#**************************************************************
# Set Output Delay
#**************************************************************


#**************************************************************
# Set Clock Groups
#**************************************************************


#**************************************************************
# Set False Path
#**************************************************************
set_false_path -from [get_clocks {clk}] -to [get_ports {avsRdData[*]}]
set_false_path -from [get_clocks {clk}] -to [get_ports {insIrq}]
set_false_path -from [get_clocks {clk}] -to [get_ports {sdat}]
set_false_path -from [get_clocks {clk}] -to [get_ports {sclk}]


#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

