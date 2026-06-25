# UART Loopback Test
# MMIO Map:
#   0x080 (W) : UART_TX  - write byte to send
#   0x084 (R) : UART_RX  - read received byte (clears rx_valid)
#   0x088 (R) : UART_STAT - [0]=tx_ready  [1]=rx_valid

loop:
        lw   x5, 0x088(x0)       # x5 = status
        andi x5, x5, 0x2          # rx_valid?
        beq  x5, x0, loop         # spin until data arrives

        lw   x5, 0x084(x0)       # x5 = rx_data (clears rx_valid)

tx_wait:
        lw   x6, 0x088(x0)       # x6 = status
        andi x6, x6, 0x1          # tx_ready?
        beq  x6, x0, tx_wait      # spin until TX idle

        sw   x5, 0x080(x0)       # TX = rx_data

        jal  x0, loop             # repeat forever
