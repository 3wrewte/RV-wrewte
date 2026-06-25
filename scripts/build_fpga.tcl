########################################################################
# build_fpga.tcl - Vivado synthesis + implementation + bitstream
# Usage: vivado -mode batch -source scripts/build_fpga.tcl -tclargs [-v]
########################################################################

set VERBOSE 0
foreach arg $argv {
    if {$arg eq "-v" || $arg eq "--verbose"} { set VERBOSE 1 }
}

set ROOT [file normalize [file dirname [info script]]/..]
set SRC  [file join $ROOT "RV-wrewte.srcs/sources_1/new"]
set VEND [file join $ROOT "RV-wrewte.srcs/sources_1/vendor"]
set XDC  [file join $ROOT "RV-wrewte.srcs/constrs_1/new/uart_test.xdc"]
set MEM  [file join $SRC "init_data.mem"]
set OUT  [file join $ROOT "build/fpga"]

file mkdir [file join $ROOT "log"]

if {!$VERBOSE} {
    namespace eval tcl { set procDummy 1 }
    proc log {msg} {}
    rename puts _puts
    proc puts {args} {}
} else {
    proc log {msg} { puts $msg }
}

#-----------------------------------------------------------------------
# Create project
#-----------------------------------------------------------------------
log "--- create_project ---"
create_project -force rv32_fpga $OUT -part xc7a35tfgg484-2

#-----------------------------------------------------------------------
# Add sources
#-----------------------------------------------------------------------
log "--- add_files ---"
set src_files [glob -directory $SRC *.v]
add_files $src_files
add_files [glob -directory $VEND *.v]
add_files -fileset constrs_1 $XDC

# Treat .v files as SystemVerilog (for typedef struct, array ports)
set v_files [get_files -of_objects [get_filesets sources_1] *.v]
foreach f $v_files {
    set_property file_type SystemVerilog $f
}

# init_data.mem for $readmemh in I_Cache
add_files -norecurse $MEM
set_property include_dirs $SRC [get_filesets sources_1]

#-----------------------------------------------------------------------
# Set top module
#-----------------------------------------------------------------------
set_property top top [current_fileset]

#-----------------------------------------------------------------------
# Synthesis
#-----------------------------------------------------------------------
log "--- synthesis ---"
launch_runs synth_1 -jobs 4
wait_on_run synth_1
log "synth done"

#-----------------------------------------------------------------------
# Implementation + bitstream
#-----------------------------------------------------------------------
log "--- implementation ---"
launch_runs impl_1 -jobs 4 -to_step write_bitstream
wait_on_run impl_1
log "impl done"

#-----------------------------------------------------------------------
# Report
#-----------------------------------------------------------------------
set bit [file join $OUT "rv32_fpga.runs/impl_1/top.bit"]
if {![file exists $bit]} {
    _puts "ERROR: bitstream not found at $bit"
    exit 1
}

# Timing summary
set wns [get_property STATS.WNS [get_runs impl_1]]
if {$wns ne ""} {
    _puts "Timing WNS: ${wns} ns"
}

_puts "BITSTREAM: $bit"

if {!$VERBOSE} {
    rename puts {}
    rename _puts puts
}
