proc verify {vals} {
    set n [llength $vals]
    if {$n != 0} {
        fail "uart_loopback sim expected no MMIO output, got $n outputs"
    }
    pass "uart_loopback idle poll, no MMIO outputs"
}
verify $values
