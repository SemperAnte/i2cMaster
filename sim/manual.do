transcript on

if {[file exists rtl_work]} {
   vdel -lib rtl_work -all
}

vlib rtl_work
vmap work rtl_work

vlog     -work work {../rtl/i2cTick.sv}
vlog     -work work {../rtl/i2cLine.sv}
vlog     -work work {../rtl/i2cAvs.sv}
vlog     -work work {../rtl/i2cControl.sv}
vlog     -work work {../rtl/i2cMaster.sv}
vlog     -work work {i2cSlave.sv}
vlog     -work work {tb_i2cMaster.sv}

vsim -t 1ns -L work -voptargs="+acc" tb_i2cMaster

add wave *

view structure
view signals
run 200 us
wave zoomfull