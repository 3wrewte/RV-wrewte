`timescale 1ns / 1ps
`include "PIPELINE_REG.v"
// RV32WB.v -- writeback stage, purely combinational; pipeline regs in TOP


module RV32WB(
    input  pipe_t mem_in,
    output [4:0] rdaddr,
    output [31:0] rd,
    output       jump,
    output [31:0] pc_out
    );

    wire [6:0] opcode = mem_in.opcode;
    wire jal = (opcode == 7'b1101111);
    wire jalr= (opcode == 7'b1100111);
    wire B   = (opcode == 7'b1100011);

    assign rdaddr = mem_in.rd_addr;
    assign rd     = mem_in.result;
    assign jump   = (jal | jalr | (B & mem_in.valid));
    assign pc_out = jump ? mem_in.taddr : 32'b0;

endmodule
