//FILE top.v
`timescale 1ns / 1ps

module top(
    input         sys_clk,
    input         sys_rst_n,
    input         uart_rxd,
    output        uart_txd,

    inout  [31:0] ddr3_dq,
    inout  [3:0]  ddr3_dqs_n,
    inout  [3:0]  ddr3_dqs_p,
    output [13:0] ddr3_addr,
    output [2:0]  ddr3_ba,
    output        ddr3_ras_n,
    output        ddr3_cas_n,
    output        ddr3_we_n,
    output        ddr3_reset_n,
    output [0:0]  ddr3_ck_p,
    output [0:0]  ddr3_ck_n,
    output [0:0]  ddr3_cke,
    output [0:0]  ddr3_cs_n,
    output [3:0]  ddr3_dm,
    output [0:0]  ddr3_odt
);
    wire clk_200m;
    wire clk_50m;
    wire locked;
    wire rst_n = locked && sys_rst_n;

    wire [27:0] app_addr;
    wire [2:0]  app_cmd;
    wire        app_en;
    wire        app_rdy;
    wire [255:0] app_wdf_data;
    wire [31:0]  app_wdf_mask;
    wire        app_wdf_end;
    wire        app_wdf_wren;
    wire        app_wdf_rdy;
    wire [255:0] app_rd_data;
    wire        app_rd_data_end;
    wire        app_rd_data_valid;
    wire        init_calib_complete;
    wire        ui_clk;
    wire        ui_clk_sync_rst;

    RV32TOP RV32TOP_u(
        .clk     (clk_50m   ),
        .rst_n   (rst_n     ),
        .in      (32'b0     ),
        .in_en   (          ),
        .out     (          ),
        .out_en  (          ),
        .uart_rxd(uart_rxd  ),
        .uart_txd(uart_txd  ),

        .mig_ui_clk(ui_clk),
        .mig_ui_rst(ui_clk_sync_rst | ~rst_n),
        .mig_init_calib_complete(init_calib_complete),
        .app_addr(app_addr),
        .app_cmd(app_cmd),
        .app_en(app_en),
        .app_rdy(app_rdy),
        .app_wdf_data(app_wdf_data),
        .app_wdf_mask(app_wdf_mask),
        .app_wdf_end(app_wdf_end),
        .app_wdf_wren(app_wdf_wren),
        .app_wdf_rdy(app_wdf_rdy),
        .app_rd_data(app_rd_data),
        .app_rd_data_valid(app_rd_data_valid),
        .app_rd_data_end(app_rd_data_end)
    );

    mig_7series_0 u_mig_7series_0 (
        .ddr3_addr           (ddr3_addr),
        .ddr3_ba             (ddr3_ba),
        .ddr3_cas_n          (ddr3_cas_n),
        .ddr3_ck_n           (ddr3_ck_n),
        .ddr3_ck_p           (ddr3_ck_p),
        .ddr3_cke            (ddr3_cke),
        .ddr3_ras_n          (ddr3_ras_n),
        .ddr3_reset_n        (ddr3_reset_n),
        .ddr3_we_n           (ddr3_we_n),
        .ddr3_dq             (ddr3_dq),
        .ddr3_dqs_n          (ddr3_dqs_n),
        .ddr3_dqs_p          (ddr3_dqs_p),
        .ddr3_cs_n           (ddr3_cs_n),
        .ddr3_dm             (ddr3_dm),
        .ddr3_odt            (ddr3_odt),
        .app_addr            (app_addr),
        .app_cmd             (app_cmd),
        .app_en              (app_en),
        .app_wdf_data        (app_wdf_data),
        .app_wdf_end         (app_wdf_end),
        .app_wdf_wren        (app_wdf_wren),
        .app_rd_data         (app_rd_data),
        .app_rd_data_end     (app_rd_data_end),
        .app_rd_data_valid   (app_rd_data_valid),
        .init_calib_complete (init_calib_complete),
        .app_rdy             (app_rdy),
        .app_wdf_rdy         (app_wdf_rdy),
        .app_sr_req          (1'b0),
        .app_ref_req         (1'b0),
        .app_zq_req          (1'b0),
        .app_sr_active       (),
        .app_ref_ack         (),
        .app_zq_ack          (),
        .ui_clk              (ui_clk),
        .ui_clk_sync_rst     (ui_clk_sync_rst),
        .app_wdf_mask        (app_wdf_mask),
        .sys_clk_i           (clk_200m),
        .clk_ref_i           (clk_200m),
        .sys_rst             (rst_n)
    );

    clk_wiz_0 u_clk_wiz(
        .clk_out1(clk_200m),
        .clk_out2(clk_50m),
        .reset(~sys_rst_n),
        .locked(locked),
        .clk_in1(sys_clk)
    );
endmodule
//ENDFILE top.v
