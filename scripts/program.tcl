########################################################################
# program.tcl - Program FPGA via JTAG (Vivado Hardware Manager)
# Usage: vivado -mode batch -source scripts/program.tcl -tclargs [top|top_dram]
########################################################################

set TOP "top"
foreach arg $argv {
    if {$arg ne ""} { set TOP $arg }
}

set ROOT [file normalize [file dirname [info script]]/..]
set BIT  [file join $ROOT "build/fpga/rv32_fpga.runs/impl_1/${TOP}.bit"]

if {![file exists $BIT]} {
    puts "ERROR: bitstream not found: $BIT"
    puts "Run 'make fpga' or 'make fpga-dram' first."
    exit 1
}

open_hw_manager

# Connect to local hardware server
connect_hw_server -quiet

# Open the first available target
set targets [get_hw_targets]
if {[llength $targets] == 0} {
    puts "ERROR: no JTAG target found. Check cable connection."
    exit 1
}
open_hw_target [lindex $targets 0]

# Find the FPGA device
set devices [get_hw_devices]
if {[llength $devices] == 0} {
    puts "ERROR: no device found on JTAG chain."
    exit 1
}

set dev [lindex $devices 0]
set_property PROGRAM.FILE $BIT $dev

puts "Programming $dev with $BIT ..."
program_hw_devices $dev
puts "Programmed OK."

close_hw_target [lindex $targets 0]
disconnect_hw_server -quiet
