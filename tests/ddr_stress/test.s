# DDR3 Stress Test
# Writes 32 pseudo-random values to DDR3, reads back and verifies.
# Outputs match count (should be 32) via output port (addr 4).
#
# LFSR: x = (x >> 1) ^ (-(x & 1) & 0xB400)
#
# Register usage:
#   x1 = loop counter i
#   x2 = DDR3 base address (0x1000)
#   x3 = LFSR state
#   x4 = temp
#   x5 = computed address
#   x6 = match count
#   x7 = read-back value / limit

    # --- Setup ---
    lui   x2, 0x1             # x2 = 0x1000 (DDR3 base)
    addi  x3, x0, 0x371       # LFSR seed = 881

    # --- Write phase ---
    addi  x1, x0, 0           # i = 0
write_loop:
    # LFSR step
    andi  x4, x3, 1           # bit 0
    sub   x4, x0, x4          # -(bit0) = 0 or -1
    lui   x5, 0x0B            # 0xB000
    addi  x5, x5, 0x400       # 0xB400
    and   x4, x4, x5          # -(bit0) & 0xB400
    srli  x3, x3, 1           # x3 >>= 1
    xor   x3, x3, x4          # x3 = next LFSR

    # Store to DDR3
    slli  x5, x1, 2           # i * 4
    add   x5, x2, x5          # addr = base + i*4
    sw    x3, 0(x5)

    addi  x1, x1, 1
    addi  x7, x0, 32
    bne   x1, x7, write_loop

    # --- Read phase ---
    addi  x3, x0, 0x371       # reset LFSR
    addi  x1, x0, 0
    addi  x6, x0, 0           # match_count = 0

read_loop:
    # LFSR step (same as write)
    andi  x4, x3, 1
    sub   x4, x0, x4
    lui   x5, 0x0B
    addi  x5, x5, 0x400
    and   x4, x4, x5
    srli  x3, x3, 1
    xor   x3, x3, x4          # x3 = expected

    # Load from DDR3
    slli  x5, x1, 2
    add   x5, x2, x5
    lw    x7, 0(x5)           # x7 = actual

    # Compare
    beq   x3, x7, match
    sw    x1, 4(x0)           # mismatch: output index
    jal   x0, read_next
match:
    addi  x6, x6, 1
read_next:
    addi  x1, x1, 1
    addi  x7, x0, 32
    bne   x1, x7, read_loop

    # Output match count
    sw    x6, 4(x0)           # 32 = all pass

halt:
    jal   x0, halt
