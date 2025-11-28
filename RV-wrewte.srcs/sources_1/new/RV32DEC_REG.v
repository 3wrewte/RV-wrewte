`timescale 1ns / 1ps
`include "PIPELINE_REG.v"
// RV32DEC_REG.v -- now purely combinational decode + regfile read, pipeline regs moved to TOP


module RV32DEC_REG(
    input         clk,
    input         rst_n,
    input  pipe_t fetch_in,   // from FETCH stage (combinational)
    input  [4:0]  waddr,      // writeback port to regfile
    input  [31:0] wdata,
    output pipe_t dec_out,    // to EX stage
    output [31:0] ocu,        // one-hot rs1/rs2 decode for CU usage
    output [6:0] opcode_pre   // combinational opcode (for CU)
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
    registers32#(.depth(5)) registers32_u(
        .clk   (clk),
        .rst_n (rst_n),
        .r1addr(rs1addr),
        .r2addr(rs2addr),
        .waddr (waddr),
        .rdata1(rs1),
        .rdata2(rs2),
        .wdata (wdata)
    );

    // fill dec_out pipe_t
    assign dec_out.instr     = instr;
    assign dec_out.pc        = pc;
    assign dec_out.imm       = imm;
    assign dec_out.rs1_data  = rs1;
    assign dec_out.rs2_data  = rs2;
    assign dec_out.rs1_addr  = rs1addr;
    assign dec_out.rs2_addr  = rs2addr;
    assign dec_out.rd_addr   = rdaddr;
    assign dec_out.opcode    = opcode;
    assign dec_out.funct3    = funct3;
    assign dec_out.funct7    = funct7;
    assign dec_out.result    = 32'b0;
    assign dec_out.taddr     = 32'b0;
    assign dec_out.valid     = 1'b1; // indicate valid instruction in pipeline

    // ocu: one-hot of rs1/rs2 (preserve previous behavior)
    wire [31:0] ocu1;
    wire [31:0] ocu2;
    DEC #(.WIDTH(5)) DEC_1(.in(rs1addr), .out(ocu1));
    DEC #(.WIDTH(5)) DEC_2(.in(rs2addr), .out(ocu2));
    assign ocu = (ocu1 | ocu2) & (~32'b1);

    assign opcode_pre = opcode; // expose pre-registered opcode for CU

endmodule
