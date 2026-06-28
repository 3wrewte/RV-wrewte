//FILE RV32TOP.v
`timescale 1ns / 1ps
`include "PIPELINE_REG.v"

module RV32TOP(
    input         clk, rst_n,
    input  [31:0] in,
    output        in_en,
    output [31:0] out,
    output        out_en,
    input         uart_rxd,
    output        uart_txd,

    input         mig_ui_clk,
    input         mig_ui_rst,
    input         mig_init_calib_complete,
    output [27:0] app_addr,
    output [2:0]  app_cmd,
    output        app_en,
    input         app_rdy,
    output [255:0] app_wdf_data,
    output [31:0] app_wdf_mask,
    output        app_wdf_end,
    output        app_wdf_wren,
    input         app_wdf_rdy,
    input  [255:0] app_rd_data,
    input         app_rd_data_valid,
    input         app_rd_data_end
);
    parameter FETCH_NUM = 2;
    parameter LSU_NUM   = 1;
    parameter ALU_NUM   = 1;
    parameter BRU_NUM   = 1;
    localparam ISSUE_NUM = LSU_NUM + ALU_NUM + BRU_NUM;
    localparam IDX_LSU = 0;
    localparam IDX_ALU = LSU_NUM;
    localparam IDX_BRU = LSU_NUM + ALU_NUM;
    
    parameter ROB_SIZE     = 8;
    parameter ISSUE_WINDOW = 8;

    pipe_t FETCH_out[FETCH_NUM-1:0];
    pipe_t DEC_in[FETCH_NUM-1:0], DEC_out[FETCH_NUM-1:0];
    pipe_t EX_in[ISSUE_NUM-1:0], EX_out[ISSUE_NUM-1:0];
    pipe_t MEM_in[LSU_NUM-1:0], MEM_out[LSU_NUM-1:0];
    pipe_t WB_in[ISSUE_NUM-1:0];

    wire stall_frontend, stall_backend, flush_frontend, flush_backend, en_PC;
    wire redirect_valid, rob_alloc_ready, rob_flush;
    wire [31:0] redirect_pc, rob_new_pc;
    wire lsu_ready;

    pipe_t alloc_in[FETCH_NUM-1:0];
    pipe_t issue_out[ISSUE_NUM-1:0];
    pipe_t receive_in[ISSUE_NUM-1:0];
    assign receive_in = WB_in;

    //----------------------------
    // BHT
    //----------------------------
    wire bht_predict_taken[FETCH_NUM-1:0];
    wire bht_update_valid, bht_taken;
    wire [31:0] bht_update_pc;

    BHT #(.ENTRIES(64)) bht_u(
        .clk(clk), .rst_n(rst_n),
        .lookup_pc(FETCH_out[0].pc),
        .predict_taken(bht_predict_taken[0]),
        .update_valid(bht_update_valid), .update_pc(bht_update_pc), .update_taken(bht_taken)
    );
    generate for (genvar b = 1; b < FETCH_NUM; b = b + 1) begin : bht_extra
        BHT #(.ENTRIES(64)) bht_x(
            .clk(clk), .rst_n(rst_n),
            .lookup_pc(FETCH_out[b].pc),
            .predict_taken(bht_predict_taken[b]),
            .update_valid(bht_update_valid), .update_pc(bht_update_pc), .update_taken(bht_taken)
        );
    end endgenerate

    //----------------------------
    // ROB
    //----------------------------
    wire br_mispredict;
    wire [31:0] br_mispredict_rob_id, br_mispredict_target;

    rob#(.ROB_SIZE(ROB_SIZE), .ENTRY(FETCH_NUM), .ISSUE_LSU(LSU_NUM), .ISSUE_ALU(ALU_NUM), .ISSUE_BRU(BRU_NUM), .WINDOW(ISSUE_WINDOW)) rob_u(
        .clk(clk), .rst_n(rst_n),
        .alloc_in(alloc_in), .rob_alloc_ready(rob_alloc_ready),
        .issue_out(issue_out), .receive_in(receive_in),
        .br_mispredict(br_mispredict), .br_mispredict_rob_id(br_mispredict_rob_id), .br_mispredict_target(br_mispredict_target),
        .lsu_ready(lsu_ready),
        .rob_flush(rob_flush), .rob_new_pc(rob_new_pc)
    );

    CU CU_u(
        .clk(clk), .rst_n(rst_n),
        .rob_alloc_ready(rob_alloc_ready), .rob_flush(rob_flush), .rob_new_pc(rob_new_pc),
        .stall_frontend(stall_frontend), .stall_backend(stall_backend),
        .flush_frontend(flush_frontend), .flush_backend(flush_backend),
        .redirect_valid(redirect_valid), .redirect_pc(redirect_pc), .en_pc(en_PC)
    );

    //----------------------------
    // FETCH with BHT prediction
    //----------------------------
    RV32FETCH#(.FETCH_NUM(FETCH_NUM)) u_FETCH(
        .clk(clk), .rst_n(rst_n),
        .write(redirect_valid), .wdata(redirect_pc), .en_PC(en_PC),
        .predict_taken(bht_predict_taken), .fetch_out(FETCH_out)
    );

    genvar k;
    generate for(k = 0; k < FETCH_NUM; k = k + 1) begin
        PIPELINE_REG PREG_FD( .clk(clk), .rst_n(rst_n), .stall(stall_frontend), .flush(flush_frontend), .in(FETCH_out[k]), .out(DEC_in[k]));
        RV32DEC_REG u_DEC( .clk(clk), .rst_n(rst_n), .fetch_in(DEC_in[k]), .dec_out(DEC_out[k]));
        PIPELINE_REG PREG_DR( .clk(clk), .rst_n(rst_n), .stall(stall_frontend), .flush(flush_frontend), .in(DEC_out[k]), .out(alloc_in[k]));
    end endgenerate

    wire Load, Store;
    wire [31:0] bus_addr, bus_data_out, bus_data_in;
    wire [2:0] bus_width;

    // LSU stall/ready
    wire lsu_stall;

    // Cache ↔ wrapper interface
    wire        cache_cpu_ls, cache_cpu_valid;
    wire [31:0] cache_cpu_addr, cache_cpu_data;
    wire [4:0]  cache_cpu_id;
    wire [3:0]  cache_cpu_mask;
    wire        cache_ls_valid;
    wire        cache_submit_valid;
    wire [4:0]  cache_submit_id;
    wire [31:0] cache_submit_data;

    // Cache ↔ bridge (lower_*)
    wire        lower_valid, lower_ls, lower_ls_valid;
    wire [31:0] lower_addr, lower_data;
    wire [4:0]  lower_id;
    wire [3:0]  lower_mask;
    wire        lower_submit_valid;
    wire [4:0]  lower_submit_id;
    wire [31:0] lower_submit_data;

    //===================================================================
    // LSU backend (cache_wrapper replaces RV32MEM)
    //===================================================================
    generate for(k = 0; k < LSU_NUM; k = k + 1) begin : lsu_lane
        localparam idx = IDX_LSU + k;
        PIPELINE_REG PREG1(.clk(clk),.rst_n(rst_n),.stall(stall_backend | lsu_stall),.flush(flush_backend),.in(issue_out[idx]),.out(EX_in[idx]));
        RV32EX U_EX(.dec_in(EX_in[idx]),.ex_out(EX_out[idx]));
        wire lsu_flush = flush_backend & ~lsu_stall;  // protect PREG2/PREG3 during cache processing
        PIPELINE_REG PREG2(.clk(clk),.rst_n(rst_n),.stall(stall_backend | lsu_stall),.flush(lsu_flush),.in(EX_out[idx]),.out(MEM_in[k]));
        cache_wrapper U_CW(
            .clk(clk), .rst_n(rst_n), .flush(flush_backend),
            .ex_in(MEM_in[k]), .mem_out(MEM_out[k]),
            .lsu_stall(lsu_stall), .lsu_ready(lsu_ready),
            .Load(Load), .Store(Store), .addr(bus_addr), .data(bus_data_out),
            .width(bus_width), .D_data(bus_data_in),
            .cpu_ls(cache_cpu_ls), .cpu_addr(cache_cpu_addr), .cpu_data(cache_cpu_data),
            .cpu_valid(cache_cpu_valid), .cpu_id(cache_cpu_id), .cpu_mask(cache_cpu_mask),
            .ls_valid(cache_ls_valid),
            .submit_valid(cache_submit_valid), .submit_id(cache_submit_id),
            .submit_data(cache_submit_data)
        );
        PIPELINE_REG PREG3(.clk(clk),.rst_n(rst_n),.stall(stall_backend | lsu_stall),.flush(lsu_flush),.in(MEM_out[k]),.out(WB_in[idx]));
    end endgenerate

    // BUS: UART MMIO only (RAM removed)
    BUS BUS_u(.clk(clk),.rst_n(rst_n),.Load(Load),.Store(Store),.addr(bus_addr),.data(bus_data_out),.width(bus_width),.D_data(bus_data_in),.in(in),.in_en(in_en),.out(out),.out_en(out_en),.uart_rxd(uart_rxd),.uart_txd(uart_txd));

    //===================================================================
    // D-Cache subsystem: cache → mig_bridge → mock_dram
    //===================================================================
    cache #(.LS_SIZE(4), .CACHE_LINES(32)) cache_u(
        .clk(clk), .rst_n(rst_n),
        .cpu_ls(cache_cpu_ls), .cpu_addr(cache_cpu_addr), .cpu_data(cache_cpu_data),
        .cpu_valid(cache_cpu_valid), .cpu_id(cache_cpu_id), .cpu_mask(cache_cpu_mask),
        .ls_valid(cache_ls_valid),
        .submit_valid(cache_submit_valid), .submit_id(cache_submit_id),
        .submit_data(cache_submit_data),
        .lower_ls(lower_ls), .lower_addr(lower_addr), .lower_data(lower_data),
        .lower_valid(lower_valid), .lower_id(lower_id), .lower_mask(lower_mask),
        .lower_ls_valid(lower_ls_valid),
        .lower_submit_valid(lower_submit_valid),
        .lower_submit_id(lower_submit_id),
        .lower_submit_data(lower_submit_data)
    );

    mig_bridge bridge_u(
        .clk(clk), .rst_n(rst_n),
        .ui_clk(mig_ui_clk), .ui_rst(mig_ui_rst),
        .lower_valid(lower_valid), .lower_ls(lower_ls),
        .lower_addr(lower_addr), .lower_data(lower_data),
        .lower_id(lower_id), .lower_mask(lower_mask),
        .lower_ls_valid(lower_ls_valid),
        .lower_submit_valid(lower_submit_valid),
        .lower_submit_id(lower_submit_id),
        .lower_submit_data(lower_submit_data),
        .app_addr(app_addr), .app_cmd(app_cmd), .app_en(app_en), .app_rdy(app_rdy),
        .app_wdf_data(app_wdf_data), .app_wdf_mask(app_wdf_mask),
        .app_wdf_end(app_wdf_end), .app_wdf_wren(app_wdf_wren), .app_wdf_rdy(app_wdf_rdy),
        .app_rd_data(app_rd_data), .app_rd_data_valid(app_rd_data_valid),
        .app_rd_data_end(app_rd_data_end),
        .init_calib_complete(mig_init_calib_complete)
    );

    //===================================================================
    // ALU backends
    //===================================================================
    generate for(k = 0; k < ALU_NUM; k = k + 1) begin : alu_lane
        localparam idx = IDX_ALU + k;
        PIPELINE_REG PREG1(.clk(clk),.rst_n(rst_n),.stall(stall_backend),.flush(flush_backend),.in(issue_out[idx]),.out(EX_in[idx]));
        RV32EX U_EX(.dec_in(EX_in[idx]),.ex_out(EX_out[idx]));
        PIPELINE_REG PREG2(.clk(clk),.rst_n(rst_n),.stall(stall_backend),.flush(flush_backend),.in(EX_out[idx]),.out(WB_in[idx]));
    end endgenerate

    //===================================================================
    // BRU backends (only if BRU_NUM > 0)
    //===================================================================
    generate
    if (BRU_NUM > 0) begin : gen_bru
        wire [BRU_NUM-1:0] bru_mispredict;
        wire [31:0] bru_correct_pc [BRU_NUM-1:0];
        wire [BRU_NUM-1:0] bru_bht_valid;
        wire [31:0] bru_bht_pc [BRU_NUM-1:0];
        wire [BRU_NUM-1:0] bru_bht_taken;

        for (k = 0; k < BRU_NUM; k = k + 1) begin : bru_lane
            localparam idx = IDX_BRU + k;
            // BRU input register: flushed normally
            PIPELINE_REG PREG1(.clk(clk),.rst_n(rst_n),.stall(stall_backend),.flush(flush_backend),.in(issue_out[idx]),.out(EX_in[idx]));
            RV32EX_BRU U_EX(.dec_in(EX_in[idx]),.ex_out(EX_out[idx]),
                .br_mispredict(bru_mispredict[k]),.br_correct_pc(bru_correct_pc[k]),
                .bht_update_valid(bru_bht_valid[k]),.bht_update_pc(bru_bht_pc[k]),.bht_taken(bru_bht_taken[k]));
            // BRU→WB register: NOT flushed on mispredict (result must reach ROB)
            wire flush_bru_wb = flush_backend & ~bru_mispredict[k];
            PIPELINE_REG PREG2(.clk(clk),.rst_n(rst_n),.stall(stall_backend),.flush(flush_bru_wb),.in(EX_out[idx]),.out(WB_in[idx]));
        end

        assign br_mispredict        = bru_mispredict[0];
        assign br_mispredict_rob_id = EX_in[IDX_BRU].rob_id;
        assign br_mispredict_target = bru_correct_pc[0];
        assign bht_update_valid = bru_bht_valid[0];
        assign bht_update_pc    = bru_bht_pc[0];
        assign bht_taken        = bru_bht_taken[0];
    end else begin : gen_no_bru
        assign br_mispredict        = 1'b0;
        assign br_mispredict_rob_id = 32'b0;
        assign br_mispredict_target = 32'b0;
        assign bht_update_valid = 1'b0;
        assign bht_update_pc    = 32'b0;
        assign bht_taken        = 1'b0;
    end
    endgenerate

endmodule
