# expect.tcl for tests/read_write
# Source from run_sim.tcl; $values, $n, fail, pass are in scope
proc verify {vals} {
    set n [llength $vals]
    if {$n < 32} {
        fail "only $n outputs (expected >= 32)"
    }
    set prev -1
    foreach v $vals {
        if {$v < $prev} {
            fail "output not monotonic: prev=$prev cur=$v"
        }
        set prev $v
    }
    pass "$n outputs, monotonic, range=[lindex $vals 0]..[lindex $vals end]"
}
verify $values
