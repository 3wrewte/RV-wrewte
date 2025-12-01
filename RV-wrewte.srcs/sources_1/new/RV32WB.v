//FILE RV32WB.v 
`timescale 1ns / 1ps
`include "PIPELINE_REG.v"


module RV32WB(
    input  pipe_t mem_in,
    output [4:0] rdaddr,
    output [31:0] rd,
    output       jump,
    output [31:0] pc_out
    );

    wire [6:0] opcode = mem_in.opcode;

    assign rdaddr = mem_in.rd_addr;
    assign rd     = mem_in.result;
    assign jump   = mem_in.jump;
    assign pc_out = jump ? mem_in.taddr : 32'b0;

endmodule
//ENDFILE RV32WB.v 