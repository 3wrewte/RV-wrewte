########################################################################
# run_sim.tcl - Vivado batch simulation script for RV-wrewte
# Usage: vivado -mode batch -source scripts/run_sim.tcl -tclargs <test> [-v]
########################################################################

set VERBOSE 0
set TEST ""
foreach arg $argv {
    if {$arg eq "-v" || $arg eq "--verbose"} { set VERBOSE 1 } \
    elseif {$TEST eq ""} { set TEST $arg }
}
if {$TEST eq ""} { set TEST "read_write" }

set ROOT [file normalize [file dirname [info script]]/..]
set SRC  [file join $ROOT "RV-wrewte.srcs/sources_1/new"]
set VEND [file join $ROOT "RV-wrewte.srcs/sources_1/vendor"]
set SIM  [file join $ROOT "RV-wrewte.srcs/sim_1/new"]
set TMP  [file join $ROOT "tmp"]
set LOG  [file join $ROOT "log"]
set CGF  [file join $ROOT "tests" $TEST "expect.tcl"]

file mkdir $TMP
cd $TMP

set RESULT_FILE [file join $TMP "result.txt"]
set STATUS_FILE [file join $TMP "status.txt"]
catch { file delete $RESULT_FILE }
catch { file delete $STATUS_FILE }

proc log {msg} { global VERBOSE; if {$VERBOSE} { puts $msg } }

proc fail {msg} {
    global RESULT_FILE STATUS_FILE
    set fh [open $STATUS_FILE w]; puts $fh "FAIL"; close $fh
    set fh [open $RESULT_FILE w]; puts $fh $msg;   close $fh
    exit 1
}

proc pass {msg} {
    global RESULT_FILE STATUS_FILE
    set fh [open $STATUS_FILE w]; puts $fh "PASS"; close $fh
    set fh [open $RESULT_FILE w]; puts -nonewline $fh $msg; close $fh
    exit 0
}

#-----------------------------------------------------------------------
# Step 1: xvlog
#-----------------------------------------------------------------------
log "--- xvlog ---"

set src_files [list \
    [file join $SRC "PIPELINE_REG.v"] \
    [file join $SRC "LSB.v"] \
    [file join $SRC "realloc.v"] \
    [file join $SRC "registers32.v"] \
    [file join $SRC "RAM32.v"] \
    [file join $SRC "I_Cache.v"] \
    [file join $SRC "BHT.v"] \
    [file join $VEND "uart_rx.v"] \
    [file join $VEND "uart_tx.v"] \
    [file join $SRC "RV32DEC.v"] \
    [file join $SRC "RV32OPDEC.v"] \
    [file join $SRC "RV32COND.v"] \
    [file join $SRC "RV32ALU.v"] \
    [file join $SRC "ENC.v"] \
    [file join $SRC "DEC.v"] \
    [file join $SRC "cache.v"] \
    [file join $SRC "rob.v"] \
    [file join $SRC "control_unit.v"] \
    [file join $SRC "BUS.v"] \
    [file join $SRC "RV32FETCH.v"] \
    [file join $SRC "RV32DEC_REG.v"] \
    [file join $SRC "RV32EX.v"] \
    [file join $SRC "RV32EX_BRU.v"] \
    [file join $SRC "RV32MEM.v"] \
    [file join $SRC "RV32WB.v"] \
    [file join $SRC "RV32TOP.v"] \
]
lappend src_files [file join $SIM "RV32test.v"]

set xvlog_args [list xvlog --sv]
eval lappend xvlog_args $src_files

if {$VERBOSE} {
    if {[catch {exec {*}$xvlog_args >@ stdout 2>@ stderr} res]} { fail "xvlog: $res" }
} else {
    if {[catch {exec {*}$xvlog_args > /dev/null} res]} { fail "xvlog failed:\n$res" }
}
log "xvlog OK"

#-----------------------------------------------------------------------
# Step 2: xelab
#-----------------------------------------------------------------------
log "--- xelab ---"
set elab_args [list xelab RV32test --debug wave --snapshot sim_snapshot]
if {$VERBOSE} {
    if {[catch {exec {*}$elab_args >@ stdout 2>@ stderr} res]} { fail "xelab: $res" }
} else {
    if {[catch {exec {*}$elab_args > /dev/null} res]} { fail "xelab failed:\n$res" }
}
log "xelab OK"

#-----------------------------------------------------------------------
# Step 3: xsim
#-----------------------------------------------------------------------
log "--- xsim ---"
set xsim_log [file join $TMP "xsim.log"]
set cmd_tcl [file join $TMP "xsim_cmd.tcl"]
set fh [open $cmd_tcl w]
puts $fh "run all"
puts $fh "quit"
close $fh

set xsim_args [list xsim sim_snapshot --tclbatch $cmd_tcl --log $xsim_log]
set xsim_stdout ""
if {[catch {set xsim_stdout [exec {*}$xsim_args 2> /dev/null]} err]} {
    set xsim_stdout $err
}
if {$VERBOSE} { puts $xsim_stdout }
log "xsim OK"

#-----------------------------------------------------------------------
# Step 4: extract output values
#-----------------------------------------------------------------------
set values [list]
foreach line [split $xsim_stdout "\n"] {
    if {[regexp {out=0x[0-9a-fA-F]+ \(([0-9]+)\)} $line -> dec]} {
        lappend values $dec
    }
}
set n [llength $values]

#-----------------------------------------------------------------------
# Step 5: verify (test-specific logic)
#-----------------------------------------------------------------------
if {[file exists $CGF]} {
    source $CGF
} else {
    verify_default $values
}

#-----------------------------------------------------------------------
# Default verification: 32 outputs, monotonically non-decreasing
#-----------------------------------------------------------------------
proc verify_default {values} {
    set n [llength $values]
    if {$n < 32} {
        fail "only $n output values (expected >= 32)"
    }
    set prev -1
    foreach v $values {
        if {$v < $prev} {
            fail "output not monotonic: prev=$prev cur=$v"
        }
        set prev $v
    }
    pass "$n outputs, monotonic, range=[lindex $values 0]..[lindex $values end]"
}
