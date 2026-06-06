########################################################################
# run_sim.tcl - Vivado batch simulation script for RV-wrewte
# Usage: vivado -mode batch -source scripts/run_sim.tcl -tclargs [-v]
# Writes result to $TMP/result.txt for the shell wrapper to display.
########################################################################

set VERBOSE 0
foreach arg $argv {
    if {$arg eq "-v" || $arg eq "--verbose"} { set VERBOSE 1 }
}

set ROOT [file normalize [file dirname [info script]]/..]
set SRC  [file join $ROOT "RV-wrewte.srcs/sources_1/new"]
set SIM  [file join $ROOT "RV-wrewte.srcs/sim_1/new"]
set TMP  [file join $ROOT "tmp"]

file mkdir $TMP
cd $TMP

set RESULT_FILE [file join $TMP "result.txt"]
set STATUS_FILE [file join $TMP "status.txt"]
catch { file delete $RESULT_FILE }
catch { file delete $STATUS_FILE }

proc log {msg} {
    global VERBOSE
    if {$VERBOSE} { puts $msg }
}

proc fail {msg} {
    global RESULT_FILE STATUS_FILE
    set fh [open $STATUS_FILE w]; puts $fh "FAIL"; close $fh
    set fh [open $RESULT_FILE w]; puts $fh $msg; close $fh
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
    [file join $SRC "RV32MEM.v"] \
    [file join $SRC "RV32WB.v"] \
    [file join $SRC "RV32TOP.v"] \
]
lappend src_files [file join $SIM "RV32test.v"]

set xvlog_args [list xvlog --sv]
eval lappend xvlog_args $src_files

if {$VERBOSE} {
    if {[catch {exec {*}$xvlog_args >@ stdout 2>@ stderr} res]} {
        fail "xvlog: $res"
    }
} else {
    if {[catch {exec {*}$xvlog_args > /dev/null} res]} {
        fail "xvlog failed:\n$res"
    }
}
log "xvlog OK"

#-----------------------------------------------------------------------
# Step 2: xelab
#-----------------------------------------------------------------------
log "--- xelab ---"
set elab_args [list xelab RV32test --debug wave --snapshot sim_snapshot]
if {$VERBOSE} {
    if {[catch {exec {*}$elab_args >@ stdout 2>@ stderr} res]} {
        fail "xelab: $res"
    }
} else {
    if {[catch {exec {*}$elab_args > /dev/null} res]} {
        fail "xelab failed:\n$res"
    }
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
# Step 4: verify output
#-----------------------------------------------------------------------
set values [list]
foreach line [split $xsim_stdout "\n"] {
    if {[regexp {out=0x[0-9a-fA-F]+ \(([0-9]+)\)} $line -> dec]} {
        lappend values $dec
    }
}

set n [llength $values]
set expect_min 32

if {$n < $expect_min} {
    fail "only $n output values (expected >= $expect_min)\n  Got: $values"
}
if {$n > $expect_min} {
    set values [lrange $values 0 [expr {$expect_min - 1}]]
    set n $expect_min
}

set deltas [list]
for {set i 1} {$i < $n} {incr i} {
    lappend deltas [expr {[lindex $values $i] - [lindex $values [expr {$i-1}]]}]
}

set delta_ref [lindex $deltas 0]
set ok 1
foreach d $deltas {
    if {$d != $delta_ref} { set ok 0; break }
}

if {$ok} {
    pass "$n outputs, delta=$delta_ref values=[lrange $values 0 4]..."
} else {
    fail "inconsistent deltas: $deltas\n  Values: $values"
}
