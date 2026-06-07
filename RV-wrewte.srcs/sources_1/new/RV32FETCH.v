//FILE RV32FETCH.v 
`timescale 1ns / 1ps
`include "PIPELINE_REG.v"

module RV32FETCH#(
    parameter FETCH_NUM = 1
)(
    input         clk, rst_n, write, en_PC,
    input  [31:0] wdata,
    input         predict_taken[FETCH_NUM-1:0],
    output pipe_t fetch_out[FETCH_NUM-1:0]
);

    wire [31:0] instr[FETCH_NUM-1:0];
    reg  [31:0] pc;

    wire slot_pred_taken[FETCH_NUM-1:0];
    wire [31:0] target[FETCH_NUM-1:0];
    wire [FETCH_NUM-1:0] slot_valid;

    wire slot0_taken = slot_pred_taken[0];
    wire slot1_taken = (FETCH_NUM > 1) ? slot_pred_taken[1] : 1'b0;

    assign slot_valid[0] = 1'b1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)            pc <= 32'b0;
        else if (write)        pc <= wdata;
        else if (!en_PC)       pc <= pc;
        else if (slot0_taken)  pc <= target[0];
        else if (slot1_taken)  pc <= target[1];
        else                   pc <= pc + (FETCH_NUM << 2);
    end

    I_Cache#(.DEPTH(256),.ISSUE(FETCH_NUM)) I_Cache_u(
        .clk(clk), .rst_n(rst_n), .pc(pc), .rdata(instr));

    genvar k;
    generate for (k = 0; k < FETCH_NUM; k = k + 1) begin : gen_slot
        wire [6:0] op = instr[k][6:0];
        wire is_branch = (op == 7'b1100011);
        wire is_jal    = (op == 7'b1101111);

        wire [31:0] b_imm = {{20{instr[k][31]}}, instr[k][7], instr[k][30:25], instr[k][11:8], 1'b0};
        wire [31:0] j_imm = {{12{instr[k][31]}}, instr[k][19:12], instr[k][20], instr[k][30:21], 1'b0};
        wire [31:0] slot_pc = pc + (k << 2);
        assign target[k] = is_branch ? (slot_pc + b_imm) : (slot_pc + j_imm);

        assign slot_pred_taken[k] = (is_branch & predict_taken[k]) | is_jal;
        if (k > 0) assign slot_valid[k] = !slot_pred_taken[k-1];

        assign fetch_out[k].rob_id     = 32'b0;
        assign fetch_out[k].instr      = instr[k];
        assign fetch_out[k].pc         = slot_pc;
        assign fetch_out[k].imm        = 32'b0;
        assign fetch_out[k].rs1_data   = 32'b0;
        assign fetch_out[k].rs2_data   = 32'b0;
        assign fetch_out[k].rs1_addr   = 5'b0;
        assign fetch_out[k].rs2_addr   = 5'b0;
        assign fetch_out[k].rd_addr    = 5'b0;
        assign fetch_out[k].opcode     = 7'b0;
        assign fetch_out[k].funct3     = 3'b0;
        assign fetch_out[k].funct7     = 7'b0;
        assign fetch_out[k].result     = 32'b0;
        assign fetch_out[k].taddr      = 32'b0;
        assign fetch_out[k].jump       = 1'b0;
        assign fetch_out[k].pred_taken = slot_pred_taken[k];
        assign fetch_out[k].pred_pc    = slot_pred_taken[k] ? target[k] : (slot_pc + 32'd4);
        assign fetch_out[k].valid      = slot_valid[k];
    end endgenerate

endmodule
