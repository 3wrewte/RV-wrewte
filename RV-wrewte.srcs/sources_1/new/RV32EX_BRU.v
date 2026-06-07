//FILE RV32EX_BRU.v
`timescale 1ns / 1ps
`include "PIPELINE_REG.v"

module RV32EX_BRU(
    input  pipe_t dec_in,
    output pipe_t ex_out,

    output        br_mispredict,
    output [31:0] br_correct_pc,
    output        bht_update_valid,
    output [31:0] bht_update_pc,
    output        bht_taken
);

    wire [6:0] opcode = dec_in.opcode;
    wire [2:0] funct3 = dec_in.funct3;
    wire [6:0] funct7 = dec_in.funct7;
    wire [31:0] rs1 = dec_in.rs1_data;
    wire [31:0] rs2 = dec_in.rs2_data;
    wire [31:0] imm = dec_in.imm;
    wire [31:0] pc  = dec_in.pc;
    wire pred    = dec_in.pred_taken;

    wire jal  = (opcode == 7'b1101111);
    wire jalr = (opcode == 7'b1100111);
    wire B    = (opcode == 7'b1100011);

    wire [31:0] alu_in1 = (jal || jalr) ? pc  : rs1;
    wire [31:0] alu_in2 = (jal || jalr) ? 32'h4 : imm;

    wire [31:0] res;
    RV32ALU RV32ALU_u(
        .in1(alu_in1), .in2(alu_in2),
        .funct3(funct3), .funct7(funct7), .out(res)
    );

    reg [31:0] taddr;
    always @(*) begin
        if (jal)       taddr = pc + imm;
        else if (jalr) taddr = (rs1 + imm) & (~1);
        else if (B)    taddr = pc + imm;
        else           taddr = 32'b0;
    end

    wire branch;
    RV32COND RV32COND_u(
        .in1(rs1), .in2(rs2), .funct3(funct3), .out(branch)
    );

    wire jump = (jal | jalr | (B & branch));

    wire mispredict = (jump != pred);
    wire [31:0] correct_pc = jump ? taddr : (pc + 32'd4);

    assign br_mispredict   = mispredict && dec_in.valid;
    assign br_correct_pc   = correct_pc;
    assign bht_update_valid = B && dec_in.valid;
    assign bht_update_pc   = pc;
    assign bht_taken       = jump;

    assign ex_out.rob_id    = dec_in.rob_id;
    assign ex_out.instr     = dec_in.instr;
    assign ex_out.pc        = pc;
    assign ex_out.imm       = imm;
    assign ex_out.rs1_data  = rs1;
    assign ex_out.rs2_data  = rs2;
    assign ex_out.rs1_addr  = dec_in.rs1_addr;
    assign ex_out.rs2_addr  = dec_in.rs2_addr;
    assign ex_out.rd_addr   = dec_in.rd_addr;
    assign ex_out.opcode    = opcode;
    assign ex_out.funct3    = funct3;
    assign ex_out.funct7    = funct7;
    assign ex_out.result    = res;
    assign ex_out.taddr     = taddr;
    assign ex_out.jump      = jump;
    assign ex_out.valid     = dec_in.valid;
    assign ex_out.pred_taken = pred;
    assign ex_out.pred_pc   = dec_in.pred_pc;

endmodule
//ENDFILE RV32EX_BRU.v
