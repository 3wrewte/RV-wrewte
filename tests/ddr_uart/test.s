# DDR3 hardware UART test
# Writes 32 pseudo-random words to DDR3 (0x1000+), reads them back,
# writes match_count to OUT_PORT (0x004) for simulation, then sends:
#   'P' + '\n' on pass, 'F' + '\n' on fail.

    # --- Setup ---
    lui   x2, 0x1             # x2 = 0x1000 (DDR3 base)
    addi  x3, x0, 0x371       # LFSR seed = 881

    # --- Write phase ---
    addi  x1, x0, 0           # i = 0
write_loop:
    andi  x4, x3, 1           # bit 0
    sub   x4, x0, x4          # -(bit0) = 0 or -1
    lui   x5, 0x0B            # 0xB000
    addi  x5, x5, 0x400       # 0xB400
    and   x4, x4, x5          # -(bit0) & 0xB400
    srli  x3, x3, 1           # x3 >>= 1
    xor   x3, x3, x4          # x3 = next LFSR

    slli  x5, x1, 2           # i * 4
    add   x5, x2, x5          # addr = base + i*4
    sw    x3, 0(x5)

    addi  x1, x1, 1
    addi  x7, x0, 32
    bne   x1, x7, write_loop

    # --- Read/verify phase ---
    addi  x3, x0, 0x371       # reset LFSR
    addi  x1, x0, 0
    addi  x6, x0, 0           # match_count = 0

read_loop:
    andi  x4, x3, 1
    sub   x4, x0, x4
    lui   x5, 0x0B
    addi  x5, x5, 0x400
    and   x4, x4, x5
    srli  x3, x3, 1
    xor   x3, x3, x4          # x3 = expected

    slli  x5, x1, 2
    add   x5, x2, x5
    lw    x7, 0(x5)           # x7 = actual

    beq   x3, x7, match
    jal   x0, read_next
match:
    addi  x6, x6, 1
read_next:
    addi  x1, x1, 1
    addi  x7, x0, 32
    bne   x1, x7, read_loop

    # Simulation-visible result
    sw    x6, 4(x0)

    # Hardware-visible result over UART
    addi  x7, x0, 32
    beq   x6, x7, pass
fail:
    addi  x5, x0, 70          # 'F'
    jal   x0, send_result
pass:
    addi  x5, x0, 80          # 'P'

send_result:
wait_tx0:
    lw    x4, 0x088(x0)       # UART status
    andi  x4, x4, 0x1         # tx_ready?
    beq   x4, x0, wait_tx0
    sw    x5, 0x080(x0)       # send 'P'/'F'

    addi  x5, x0, 10          # '\n'
wait_tx1:
    lw    x4, 0x088(x0)
    andi  x4, x4, 0x1
    beq   x4, x0, wait_tx1
    sw    x5, 0x080(x0)

halt:
    jal   x0, halt
