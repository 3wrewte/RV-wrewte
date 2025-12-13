//FILE RV32MEM.v 
`timescale 1ns / 1ps
`include "PIPELINE_REG.v"


module RV32MEM(
    input  pipe_t ex_in,     // from EX stage
    // bus interface
    output        Load,
    output        Store,
    output [31:0] addr,
    output [31:0] data,
    output [2:0]  width,
    input  [31:0] D_data,
    output pipe_t mem_out   // to WB stage
    );

    wire [6:0] opcode = ex_in.opcode;
    wire L = (opcode == 7'b0000011);
    wire S = (opcode == 7'b0100011);
    wire B = (opcode == 7'b1100011);

    // memory control signals
    assign Load  = L;
    assign Store = S;
    assign addr  = ex_in.taddr;
    assign data  = ex_in.rs2_data;
    assign width = ex_in.funct3;

    // result selection (load returns memory data)
    wire [31:0] result = L ? D_data : ex_in.result;

    // pack mem_out
    assign mem_out.rob_id    = ex_in.rob_id;
    assign mem_out.instr     = ex_in.instr;
    assign mem_out.pc        = ex_in.pc;
    assign mem_out.imm       = ex_in.imm;
    assign mem_out.rs1_data  = ex_in.rs1_data;
    assign mem_out.rs2_data  = ex_in.rs2_data;
    assign mem_out.rs1_addr  = ex_in.rs1_addr;
    assign mem_out.rs2_addr  = ex_in.rs2_addr;
    assign mem_out.rd_addr   = ex_in.rd_addr;
    assign mem_out.opcode    = ex_in.opcode;
    assign mem_out.funct3    = ex_in.funct3;
    assign mem_out.funct7    = ex_in.funct7;
    assign mem_out.result    = result;
    assign mem_out.taddr     = ex_in.taddr;
    assign mem_out.jump      = ex_in.jump;
    assign mem_out.valid     = ex_in.valid;

endmodule
//ENDFILE RV32MEM.v 