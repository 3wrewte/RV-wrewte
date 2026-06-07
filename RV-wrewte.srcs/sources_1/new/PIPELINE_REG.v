//FILE PIPELINE_REG.v
`ifndef __PIPE_DEFS_SV__
`define __PIPE_DEFS_SV__
`timescale 1ns / 1ps


typedef struct packed {
    logic [31:0] rob_id     ;
    logic [31:0] instr      ;
    logic [31:0] pc         ;
    logic [31:0] imm        ;
    logic [31:0] rs1_data   ;
    logic [31:0] rs2_data   ;
    logic [4:0]  rs1_addr   ;
    logic [4:0]  rs2_addr   ;
    logic [4:0]  rd_addr    ;
    logic [6:0]  opcode     ;
    logic [2:0]  funct3     ;
    logic [6:0]  funct7     ;
    logic [31:0] result     ; //alu result
    logic [31:0] taddr      ; //target mem addr or target PC
    logic        jump       ;
    logic        valid      ; //1 if the pipe_t stores a real command 
    logic        pred_taken ; //branch prediction at fetch: 1=taken
    logic [31:0] pred_pc    ; //predicted next PC after this instr
} pipe_t;


module PIPELINE_REG (
    input        clk,
    input        rst_n,
    input        stall,
    input        flush,
    input  pipe_t in,
    output pipe_t out
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            out <= '0;
        else if (flush)
            out <= '0;
        else if (stall)
            out <= out;
        else
            out <= in;
    end

endmodule
`endif
//ENDFILE PIPELINE_REG.v
