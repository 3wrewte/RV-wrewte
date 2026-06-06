//FILE RV32TOP.v
`timescale 1ns / 1ps
`include "PIPELINE_REG.v"

module RV32TOP(
    input         clk,
    input         rst_n,

    // instruction input port
    input  [31:0] in,
    output        in_en,

    // output port
    output [31:0] out,
    output        out_en
);
    parameter FETCH_NUM = 2;
    parameter LSU_NUM   = 1;
    parameter ALU_NUM   = 1;
    // future: parameter BRU_NUM = 0;
    localparam ISSUE_NUM = LSU_NUM + ALU_NUM;

    //----------------------------
    // Pipeline wires between stages
    //----------------------------
    pipe_t FETCH_out[FETCH_NUM - 1:0];
    pipe_t DEC_in[FETCH_NUM - 1:0];
    pipe_t DEC_out[FETCH_NUM - 1:0];
    pipe_t EX_in  [ISSUE_NUM-1:0];
    pipe_t EX_out [ISSUE_NUM-1:0];
    pipe_t MEM_in [LSU_NUM-1:0];
    pipe_t MEM_out[LSU_NUM-1:0];
    pipe_t WB_in  [ISSUE_NUM-1:0];

    //----------------------------
    // Control Unit signals
    //----------------------------
    wire stall_frontend, stall_backend;
    wire flush_frontend, flush_backend;
    wire en_PC;

    wire redirect_valid ;
    wire [31:0] redirect_pc;
    wire rob_alloc_ready;
    wire rob_flush      ;
    wire [31:0] rob_new_pc     ;

    pipe_t      alloc_in[FETCH_NUM - 1:0];
    pipe_t      issue_out[ISSUE_NUM - 1:0];
    pipe_t      receive_in[ISSUE_NUM - 1:0];

    assign receive_in = WB_in;

    //----------------------------
    // ROB
    //----------------------------
    rob#(
        .ENTRY(FETCH_NUM),
        .ISSUE_LSU(LSU_NUM),
        .ISSUE_ALU(ALU_NUM)
    ) rob_u(
        .clk              (clk              ),
        .rst_n            (rst_n            ),
        .alloc_in         (alloc_in         ),
        .rob_alloc_ready  (rob_alloc_ready  ),
        .issue_out        (issue_out        ),
        .receive_in       (receive_in       ),
        .rob_flush        (rob_flush        ),
        .rob_new_pc       (rob_new_pc       )
    );

    //------------------------------------
    // Control Unit
    //------------------------------------
    CU CU_u(
        .clk            (clk            ),
        .rst_n          (rst_n          ),
        .rob_alloc_ready(rob_alloc_ready),
        .rob_flush      (rob_flush      ),
        .rob_new_pc     (rob_new_pc     ),
        .stall_frontend (stall_frontend ),
        .stall_backend  (stall_backend  ),
        .flush_frontend (flush_frontend ),
        .flush_backend  (flush_backend  ),
        .redirect_valid (redirect_valid ),
        .redirect_pc    (redirect_pc    ),
        .en_pc          (en_PC          )
    );

    //----------------------------
    // FETCH stage
    //----------------------------
    RV32FETCH#(.FETCH_NUM(FETCH_NUM)) u_FETCH(
        .clk       (clk),
        .rst_n     (rst_n),
        .write     (redirect_valid),
        .wdata     (redirect_pc),
        .en_PC     (en_PC),
        .fetch_out (FETCH_out)
    );

    genvar k;
    generate
    for(k = 0; k < FETCH_NUM; k = k + 1)begin
        //----------------------------
        // Pipeline Register: FETCH -> DEC
        //----------------------------
        PIPELINE_REG PIPELINE_REG_FETCH_DEC(
            .clk  (clk),
            .rst_n(rst_n),
            .stall(stall_frontend),
            .flush(flush_frontend),
            .in   (FETCH_out[k]),
            .out  (DEC_in[k])
        );

        //----------------------------
        // DEC stage
        //----------------------------
        RV32DEC_REG u_DEC_REG(
            .clk      (clk),
            .rst_n    (rst_n),
            .fetch_in (DEC_in[k]),
            .dec_out  (DEC_out[k])
        );

        //----------------------------
        // Pipeline Register: DEC -> ROB
        //----------------------------
        PIPELINE_REG PIPELINE_REG_DEC_ROB(
            .clk  (clk),
            .rst_n(rst_n),
            .stall(stall_frontend),
            .flush(flush_frontend),
            .in   (DEC_out[k]),
            .out  (alloc_in[k])
        );
    end
    endgenerate

    //----------------------------
    // BUS wires (shared by all LSU backends)
    //----------------------------
    wire Load, Store;
    wire [31:0] bus_addr;
    wire [31:0] bus_data_out;
    wire [2:0]  bus_width;
    wire [31:0] bus_data_in;

    //===================================================================
    // LSU backends: issue_out[0 .. LSU_NUM-1]
    // Path: ROB -> PIPE_REG -> EX -> PIPE_REG -> MEM -> BUS -> PIPE_REG -> WB
    //===================================================================
    generate
    for(k = 0; k < LSU_NUM; k = k + 1)begin
        localparam lsu_idx = k;

        // ROB -> EX
        PIPELINE_REG PIPELINE_REG_ROB_EX_LSU(
            .clk  (clk),
            .rst_n(rst_n),
            .stall(stall_backend),
            .flush(flush_backend),
            .in   (issue_out[lsu_idx]),
            .out  (EX_in[lsu_idx])
        );

        // EX stage
        RV32EX U_EX_LSU(
            .dec_in (EX_in[lsu_idx]),
            .ex_out (EX_out[lsu_idx])
        );

        // EX -> MEM
        PIPELINE_REG PIPELINE_REG_EX_MEM_LSU(
            .clk  (clk),
            .rst_n(rst_n),
            .stall(stall_backend),
            .flush(flush_backend),
            .in   (EX_out[lsu_idx]),
            .out  (MEM_in[k])
        );

        // MEM stage
        RV32MEM U_MEM_LSU(
            .ex_in  (MEM_in[k]),
            .Load   (Load),
            .Store  (Store),
            .addr   (bus_addr),
            .data   (bus_data_out),
            .width  (bus_width),
            .D_data (bus_data_in),
            .mem_out(MEM_out[k])
        );

        // MEM -> WB
        PIPELINE_REG PIPELINE_REG_MEM_WB_LSU(
            .clk  (clk),
            .rst_n(rst_n),
            .stall(stall_backend),
            .flush(flush_backend),
            .in   (MEM_out[k]),
            .out  (WB_in[lsu_idx])
        );
    end
    endgenerate

    //----------------------------
    // BUS (shared by all LSU backends)
    //----------------------------
    BUS BUS_u(
        .clk   (clk   ),
        .rst_n (rst_n ),
        .Load  (Load  ),
        .Store (Store ),
        .addr  (bus_addr  ),
        .data  (bus_data_out ),
        .width (bus_width ),
        .D_data(bus_data_in),
        .in    (in    ),
        .in_en (in_en ),
        .out   (out   ),
        .out_en(out_en)
    );

    //===================================================================
    // ALU backends: issue_out[LSU_NUM .. ISSUE_NUM-1]
    // Path: ROB -> PIPE_REG -> EX -> PIPE_REG -> WB (no MEM stage)
    //===================================================================
    generate
    for(k = LSU_NUM; k < ISSUE_NUM; k = k + 1)begin
        localparam alu_idx = k;

        // ROB -> EX
        PIPELINE_REG PIPELINE_REG_ROB_EX_ALU(
            .clk  (clk),
            .rst_n(rst_n),
            .stall(stall_backend),
            .flush(flush_backend),
            .in   (issue_out[alu_idx]),
            .out  (EX_in[alu_idx])
        );

        // EX stage
        RV32EX U_EX_ALU(
            .dec_in (EX_in[alu_idx]),
            .ex_out (EX_out[alu_idx])
        );

        // EX -> WB (skip MEM)
        PIPELINE_REG PIPELINE_REG_EX_WB_ALU(
            .clk  (clk),
            .rst_n(rst_n),
            .stall(stall_backend),
            .flush(flush_backend),
            .in   (EX_out[alu_idx]),
            .out  (WB_in[alu_idx])
        );
    end
    endgenerate

endmodule
//ENDFILE RV32TOP.v
