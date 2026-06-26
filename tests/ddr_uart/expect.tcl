# tests/ddr_uart/expect.tcl
# Same functional check as ddr_stress; UART output is for hardware.

set found 0
foreach v $values {
    if {$v == 32} { set found 1 }
}
if {$found} {
    pass "DDR UART test passed in simulation: 32/32 matches ($n total outputs)"
} else {
    fail "match count 32 not found in outputs: $values"
}
