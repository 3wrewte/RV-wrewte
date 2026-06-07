//FILE RV32DEC_REG.v 
`timescale 1ns / 1ps
`include "PIPELINE_REG.v"


module RV32DEC_REG(
    input         clk,
    input         rst_n,
    input  pipe_t fetch_in,   // from FETCH stage (combinational)
    output pipe_t dec_out    // to EX stage
    );

    // decode instruction
    wire [31:0] instr = fetch_in.instr;
    wire [31:0] pc    = fetch_in.pc;
    wire [6:0]  opcode;
    wire [4:0]  rs1addr;
    wire [4:0]  rs2addr;
    wire [4:0]  rdaddr;
    wire [2:0]  funct3;
    wire [6:0]  funct7;
    wire [31:0] imm;

    RV32DEC RV32DEC_u(
        .instr  (instr),
        .opcode (opcode),
        .rs1addr(rs1addr),
        .rs2addr(rs2addr),
        .rdaddr (rdaddr),
        .funct3 (funct3),
        .funct7 (funct7),
        .imm    (imm)
    );

    // registers32 module provides register file read (keeps its internal clocks)
    wire [31:0] rs1;
    wire [31:0] rs2;

    // fill dec_out pipe_t
    assign dec_out.rob_id    = 32'b0;
    assign dec_out.instr     = instr;
    assign dec_out.pc        = pc;
    assign dec_out.imm       = imm;
    assign dec_out.rs1_data  = 32'b0;
    assign dec_out.rs2_data  = 32'b0;
    assign dec_out.rs1_addr  = rs1addr;
    assign dec_out.rs2_addr  = rs2addr;
    assign dec_out.rd_addr   = rdaddr;
    assign dec_out.opcode    = opcode;
    assign dec_out.funct3    = funct3;
    assign dec_out.funct7    = funct7;
    assign dec_out.result    = 32'b0;
    assign dec_out.taddr     = 32'b0;
    assign dec_out.jump      = 1'b0;
    assign dec_out.valid     = fetch_in.valid;
    assign dec_out.pred_taken = fetch_in.pred_taken;
    assign dec_out.pred_pc   = fetch_in.pred_pc;



endmodule
//ENDFILE RV32DEC_REG.v 