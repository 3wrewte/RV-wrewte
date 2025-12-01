//FILE RV32FETCH.v 
`timescale 1ns / 1ps
`include "PIPELINE_REG.v"

module RV32FETCH(
    input         clk,
    input         rst_n,
    input         write,
    input  [31:0] wdata,
    input         en_PC,
    output pipe_t fetch_out  // to DEC stage (wire)
    );

    // internal fetch
    wire [31:0] instr;
    wire [31:0] pc;

    PC PC_u(
        .clk  (clk),
        .rst_n(rst_n),
        .write(write),
        .wdata(wdata),
        .en   (en_PC), 
        .pc   (pc)
    );

    I_Cache#(.DEPTH(256)) I_Cache_u(
        .clk  (clk),
        .rst_n(rst_n),
        .pc   (pc),
        .rdata(instr)
    );

    // pack into pipe_t
    // only instr and pc are meaningful at this stage; other fields zeroed
    assign fetch_out.instr     = instr;
    assign fetch_out.pc        = pc;
    assign fetch_out.imm       = 32'b0;
    assign fetch_out.rs1_data  = 32'b0;
    assign fetch_out.rs2_data  = 32'b0;
    assign fetch_out.rs1_addr  = 5'b0;
    assign fetch_out.rs2_addr  = 5'b0;
    assign fetch_out.rd_addr   = 5'b0;
    assign fetch_out.opcode    = 7'b0;
    assign fetch_out.funct3    = 3'b0;
    assign fetch_out.funct7    = 7'b0;
    assign fetch_out.result    = 32'b0;
    assign fetch_out.taddr     = 32'b0;
    assign fetch_out.jump      = 1'b0;
    assign fetch_out.valid     = 1'b1;

endmodule
//ENDFILE RV32FETCH.v