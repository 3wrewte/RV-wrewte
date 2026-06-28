`timescale 1ns / 1ps
// axi_bram_slave.v - Minimal single-beat AXI4 slave around blk_mem_gen_0.

module axi_bram_slave(
    input         axi_clk,
    input         axi_rst_n,

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

    input  [31:0] s_axi_wdata,
    input  [3:0]  s_axi_wstrb,
    input         s_axi_wlast,
    input         s_axi_wvalid,
    output        s_axi_wready,

    input         s_axi_bready,
    output reg [3:0] s_axi_bid,
    output reg [1:0] s_axi_bresp,
    output reg    s_axi_bvalid,

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

    input         s_axi_rready,
    output reg [3:0]  s_axi_rid,
    output reg [31:0] s_axi_rdata,
    output reg [1:0]  s_axi_rresp,
    output reg        s_axi_rlast,
    output reg        s_axi_rvalid
);
    reg        aw_seen;
    reg [3:0]  aw_id_q;
    reg [31:0] aw_addr_q;
    reg        w_seen;
    reg [31:0] w_data_q;
    reg [3:0]  w_strb_q;

    reg        bram_en;
    reg [3:0]  bram_we;
    reg [31:0] bram_addr;
    reg [31:0] bram_din;
    wire [31:0] bram_dout;
    wire        bram_busy;

    reg        rd_pending;
    reg [3:0]  rd_id_q;

    assign s_axi_awready = !aw_seen && !s_axi_bvalid && !bram_busy;
    assign s_axi_wready  = !w_seen  && !s_axi_bvalid && !bram_busy;
    assign s_axi_arready = !rd_pending && !s_axi_rvalid && !bram_busy;

    wire aw_fire = s_axi_awvalid && s_axi_awready;
    wire w_fire  = s_axi_wvalid  && s_axi_wready;
    wire ar_fire = s_axi_arvalid && s_axi_arready;

    always @(posedge axi_clk or negedge axi_rst_n) begin
        if (!axi_rst_n) begin
            aw_seen <= 1'b0;
            aw_id_q <= 4'b0;
            aw_addr_q <= 32'b0;
            w_seen <= 1'b0;
            w_data_q <= 32'b0;
            w_strb_q <= 4'b0;
            s_axi_bid <= 4'b0;
            s_axi_bresp <= 2'b0;
            s_axi_bvalid <= 1'b0;
            rd_pending <= 1'b0;
            rd_id_q <= 4'b0;
            s_axi_rid <= 4'b0;
            s_axi_rdata <= 32'b0;
            s_axi_rresp <= 2'b0;
            s_axi_rlast <= 1'b0;
            s_axi_rvalid <= 1'b0;
            bram_en <= 1'b0;
            bram_we <= 4'b0;
            bram_addr <= 32'b0;
            bram_din <= 32'b0;
        end else begin
            bram_en <= 1'b0;
            bram_we <= 4'b0;

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
                aw_addr_q <= {3'b0, s_axi_awaddr};
            end
            if (w_fire) begin
                w_seen <= 1'b1;
                w_data_q <= s_axi_wdata;
                w_strb_q <= s_axi_wstrb;
            end

            if ((aw_seen || aw_fire) && (w_seen || w_fire) && !s_axi_bvalid) begin
                bram_en <= 1'b1;
                bram_we <= w_fire ? s_axi_wstrb : w_strb_q;
                bram_addr <= aw_fire ? {3'b0, s_axi_awaddr} : aw_addr_q;
                bram_din <= w_fire ? s_axi_wdata : w_data_q;
                s_axi_bid <= aw_fire ? s_axi_awid : aw_id_q;
                s_axi_bresp <= 2'b00;
                s_axi_bvalid <= 1'b1;
                aw_seen <= 1'b0;
                w_seen <= 1'b0;
            end

            if (ar_fire) begin
                bram_en <= 1'b1;
                bram_we <= 4'b0;
                bram_addr <= {3'b0, s_axi_araddr};
                rd_id_q <= s_axi_arid;
                rd_pending <= 1'b1;
            end else if (rd_pending && !s_axi_rvalid) begin
                s_axi_rid <= rd_id_q;
                s_axi_rdata <= bram_dout;
                s_axi_rresp <= 2'b00;
                s_axi_rlast <= 1'b1;
                s_axi_rvalid <= 1'b1;
                rd_pending <= 1'b0;
            end
        end
    end

    blk_mem_gen_0 u_bram(
        .clka(axi_clk),
        .rsta(~axi_rst_n),
        .ena(bram_en),
        .wea(bram_we),
        .addra(bram_addr),
        .dina(bram_din),
        .douta(bram_dout),
        .rsta_busy(bram_busy)
    );

endmodule
