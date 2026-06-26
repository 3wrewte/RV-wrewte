addi x1, x0, 0x000          
lui  x2, 0x1                # x2 = 0x1000 (DDR3 base)
addi x4, x0, 0x000   
addi x5, x0, 0x004



read_loop:
        lw x3, 0(x4)              # x3 = mem[0x0] (input)
        slli x6, x1, 2            # x6 = i * 4
        add x6, x2, x6            # x6 = base + i*4
        sw x3, 0(x6)              # mem[base + i*4] = x3
        addi x1, x1, 1            # i++
        addi x7, x0, 32
        bne x1, x7, read_loop     # if i != 32, continue


addi x1, x0, 0x000
write_loop:
        slli x6, x1, 2            # x6 = i * 4
        add x6, x2, x6            # x6 = base + i*4
        lw x3, 0(x6)              # x3 = mem[base + i*4]
        sw x3, 0(x5)              # mem[0x1] = x3 (output)
        addi x1, x1, 1
        addi x7, x0, 32
        bne x1, x7, write_loop
halt:
        jal x0, halt
