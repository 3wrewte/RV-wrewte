`timescale 1ns / 1ps
// mock_dram_axi.v - Behavioral single-beat AXI4 memory model.
// For simulation only. Replaced by AXI MIG or BRAM slave on FPGA.

module mock_dram_axi #(
    parameter LATENCY = 8,
    parameter DEPTH = 65536
)(
    input         axi_clk,
    input         axi_rst_n,

    output reg    init_calib_complete,

    // AXI write address
    input  [3:0]  s_axi_awid,
    input  [28:0] s_axi_awaddr,
    input  [7:0]  s_axi_awlen,
    input  [2:0]  s_axi_awsize,
    input  [1:0]  s_axi_awburst,
    input  [0:0]  s_axi_awlock,
    input  [3:0]  s_axi_awcache,
    input  [2:0]  s_axi_awprot,
    input  [3:0]  s_axi_awqos,
    input         s_axi_awvalid,
    output        s_axi_awready,

    // AXI write data
    input  [31:0] s_axi_wdata,
    input  [3:0]  s_axi_wstrb,
    input         s_axi_wlast,
    input         s_axi_wvalid,
    output        s_axi_wready,

    // AXI write response
    input         s_axi_bready,
    output reg [3:0] s_axi_bid,
    output reg [1:0] s_axi_bresp,
    output reg    s_axi_bvalid,

    // AXI read address
    input  [3:0]  s_axi_arid,
    input  [28:0] s_axi_araddr,
    input  [7:0]  s_axi_arlen,
    input  [2:0]  s_axi_arsize,
    input  [1:0]  s_axi_arburst,
    input  [0:0]  s_axi_arlock,
    input  [3:0]  s_axi_arcache,
    input  [2:0]  s_axi_arprot,
    input  [3:0]  s_axi_arqos,
    input         s_axi_arvalid,
    output        s_axi_arready,

    // AXI read data
    input         s_axi_rready,
    output reg [3:0]  s_axi_rid,
    output reg [31:0] s_axi_rdata,
    output reg [1:0]  s_axi_rresp,
    output reg        s_axi_rlast,
    output reg        s_axi_rvalid
);
    reg [31:0] mem [0:DEPTH-1];
    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = 32'b0;
    end

    reg [3:0] calib_cnt;
    always @(posedge axi_clk or negedge axi_rst_n) begin
        if (!axi_rst_n) begin
            calib_cnt <= 4'b0;
            init_calib_complete <= 1'b0;
        end else if (calib_cnt < 4'd5) begin
            calib_cnt <= calib_cnt + 1'b1;
            init_calib_complete <= 1'b0;
        end else begin
            init_calib_complete <= 1'b1;
        end
    end

    reg        aw_seen;
    reg [3:0]  aw_id_q;
    reg [28:0] aw_addr_q;
    reg        w_seen;
    reg [31:0] w_data_q;
    reg [3:0]  w_strb_q;

    reg        rd_pending;
    reg [3:0]  rd_id_q;
    reg [28:0] rd_addr_q;
    reg [7:0]  rd_lat;

    assign s_axi_awready = init_calib_complete && !aw_seen && !s_axi_bvalid;
    assign s_axi_wready  = init_calib_complete && !w_seen  && !s_axi_bvalid;
    assign s_axi_arready = init_calib_complete && !rd_pending && !s_axi_rvalid;

    wire aw_fire = s_axi_awvalid && s_axi_awready;
    wire w_fire  = s_axi_wvalid  && s_axi_wready;
    wire ar_fire = s_axi_arvalid && s_axi_arready;

    integer b;
    integer widx;
    reg [31:0] wr_data_sel;
    reg [3:0]  wr_strb_sel;
    reg [28:0] wr_addr_sel;
    always @(posedge axi_clk or negedge axi_rst_n) begin
        if (!axi_rst_n) begin
            aw_seen <= 1'b0;
            aw_id_q <= 4'b0;
            aw_addr_q <= 29'b0;
            w_seen <= 1'b0;
            w_data_q <= 32'b0;
            w_strb_q <= 4'b0;
            s_axi_bid <= 4'b0;
            s_axi_bresp <= 2'b0;
            s_axi_bvalid <= 1'b0;
            rd_pending <= 1'b0;
            rd_id_q <= 4'b0;
            rd_addr_q <= 29'b0;
            rd_lat <= 8'b0;
            s_axi_rid <= 4'b0;
            s_axi_rdata <= 32'b0;
            s_axi_rresp <= 2'b0;
            s_axi_rlast <= 1'b0;
            s_axi_rvalid <= 1'b0;
        end else begin
            if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
            if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
                s_axi_rlast <= 1'b0;
            end

            if (aw_fire) begin
                aw_seen <= 1'b1;
                aw_id_q <= s_axi_awid;
                aw_addr_q <= s_axi_awaddr;
            end
            if (w_fire) begin
                w_seen <= 1'b1;
                w_data_q <= s_axi_wdata;
                w_strb_q <= s_axi_wstrb;
            end

            if ((aw_seen || aw_fire) && (w_seen || w_fire) && !s_axi_bvalid) begin
                wr_addr_sel = aw_fire ? s_axi_awaddr : aw_addr_q;
                wr_data_sel = w_fire ? s_axi_wdata : w_data_q;
                wr_strb_sel = w_fire ? s_axi_wstrb : w_strb_q;
                widx = (wr_addr_sel >> 2) % DEPTH;
                for (b = 0; b < 4; b = b + 1) begin
                    if (wr_strb_sel[b])
                        mem[widx][b*8 +: 8] <= wr_data_sel[b*8 +: 8];
                end
                s_axi_bid <= aw_fire ? s_axi_awid : aw_id_q;
                s_axi_bresp <= 2'b00;
                s_axi_bvalid <= 1'b1;
                aw_seen <= 1'b0;
                w_seen <= 1'b0;
            end

            if (ar_fire) begin
                rd_pending <= 1'b1;
                rd_id_q <= s_axi_arid;
                rd_addr_q <= s_axi_araddr;
                rd_lat <= LATENCY[7:0];
            end

            if (rd_pending && !s_axi_rvalid) begin
                if (rd_lat > 1) begin
                    rd_lat <= rd_lat - 1'b1;
                end else begin
                    s_axi_rid <= rd_id_q;
                    s_axi_rdata <= mem[(rd_addr_q >> 2) % DEPTH];
                    s_axi_rresp <= 2'b00;
                    s_axi_rlast <= 1'b1;
                    s_axi_rvalid <= 1'b1;
                    rd_pending <= 1'b0;
                end
            end
        end
    end

endmodule
