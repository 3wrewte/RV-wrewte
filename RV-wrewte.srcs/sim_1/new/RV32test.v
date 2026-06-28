`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/06/2025 10:57:55 PM
// Design Name: 
// Module Name: RV32test
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module RV32test(
    output reg sys_clk,
    output reg sys_rst_n,
    output [31:0]  out   ,
    output         out_en
    );
    initial begin
        sys_clk = 0;
        sys_rst_n = 0;
        #50;
            sys_rst_n = 1;
    end
    always #50 sys_clk = ~sys_clk;
    
    initial begin
        #1000000;
        $display("Simulation timeout at %t", $time);
        $finish;
    end
    
    reg  [31:0]   in    ;
    wire          in_en ;
    wire [3:0]    m_axi_awid;
    wire [28:0]   m_axi_awaddr;
    wire [7:0]    m_axi_awlen;
    wire [2:0]    m_axi_awsize;
    wire [1:0]    m_axi_awburst;
    wire [0:0]    m_axi_awlock;
    wire [3:0]    m_axi_awcache;
    wire [2:0]    m_axi_awprot;
    wire [3:0]    m_axi_awqos;
    wire          m_axi_awvalid;
    wire          m_axi_awready;
    wire [31:0]   m_axi_wdata;
    wire [3:0]    m_axi_wstrb;
    wire          m_axi_wlast;
    wire          m_axi_wvalid;
    wire          m_axi_wready;
    wire          m_axi_bready;
    wire [3:0]    m_axi_bid;
    wire [1:0]    m_axi_bresp;
    wire          m_axi_bvalid;
    wire [3:0]    m_axi_arid;
    wire [28:0]   m_axi_araddr;
    wire [7:0]    m_axi_arlen;
    wire [2:0]    m_axi_arsize;
    wire [1:0]    m_axi_arburst;
    wire [0:0]    m_axi_arlock;
    wire [3:0]    m_axi_arcache;
    wire [2:0]    m_axi_arprot;
    wire [3:0]    m_axi_arqos;
    wire          m_axi_arvalid;
    wire          m_axi_arready;
    wire          m_axi_rready;
    wire [3:0]    m_axi_rid;
    wire [31:0]   m_axi_rdata;
    wire [1:0]    m_axi_rresp;
    wire          m_axi_rlast;
    wire          m_axi_rvalid;
    wire          init_calib_complete;
    always @(posedge sys_clk or negedge sys_rst_n)begin
        if(!sys_rst_n)
            in <= 32'b0;
        else 
            in <= in + 1;
    end
    
    integer out_cnt;
    initial out_cnt = 0;
    always @(posedge sys_clk) begin
        if (out_en) begin
            out_cnt = out_cnt + 1;
            $display("[%t] out=0x%h (%0d), cnt=%0d", $time, out, out, out_cnt);
        end
    end
    
    
    RV32TOP RV32TOP_u(
        .clk   (sys_clk   ),
        .rst_n (sys_rst_n ),
        .in    (in    ),
        .in_en (in_en ),
        .out   (out   ),
        .out_en(out_en),
        .uart_rxd(1'b1),
        .uart_txd(),
        .axi_clk(sys_clk),
        .axi_rst_n(sys_rst_n),
        .mig_init_calib_complete(init_calib_complete),
        .m_axi_awid(m_axi_awid), .m_axi_awaddr(m_axi_awaddr),
        .m_axi_awlen(m_axi_awlen), .m_axi_awsize(m_axi_awsize),
        .m_axi_awburst(m_axi_awburst), .m_axi_awlock(m_axi_awlock),
        .m_axi_awcache(m_axi_awcache), .m_axi_awprot(m_axi_awprot),
        .m_axi_awqos(m_axi_awqos), .m_axi_awvalid(m_axi_awvalid),
        .m_axi_awready(m_axi_awready),
        .m_axi_wdata(m_axi_wdata), .m_axi_wstrb(m_axi_wstrb),
        .m_axi_wlast(m_axi_wlast), .m_axi_wvalid(m_axi_wvalid),
        .m_axi_wready(m_axi_wready),
        .m_axi_bready(m_axi_bready), .m_axi_bid(m_axi_bid),
        .m_axi_bresp(m_axi_bresp), .m_axi_bvalid(m_axi_bvalid),
        .m_axi_arid(m_axi_arid), .m_axi_araddr(m_axi_araddr),
        .m_axi_arlen(m_axi_arlen), .m_axi_arsize(m_axi_arsize),
        .m_axi_arburst(m_axi_arburst), .m_axi_arlock(m_axi_arlock),
        .m_axi_arcache(m_axi_arcache), .m_axi_arprot(m_axi_arprot),
        .m_axi_arqos(m_axi_arqos), .m_axi_arvalid(m_axi_arvalid),
        .m_axi_arready(m_axi_arready),
        .m_axi_rready(m_axi_rready), .m_axi_rid(m_axi_rid),
        .m_axi_rdata(m_axi_rdata), .m_axi_rresp(m_axi_rresp),
        .m_axi_rlast(m_axi_rlast), .m_axi_rvalid(m_axi_rvalid)
    );

    mock_dram_axi #(.LATENCY(8)) dram_u(
        .axi_clk(sys_clk),
        .axi_rst_n(sys_rst_n),
        .init_calib_complete(init_calib_complete),
        .s_axi_awid(m_axi_awid), .s_axi_awaddr(m_axi_awaddr),
        .s_axi_awlen(m_axi_awlen), .s_axi_awsize(m_axi_awsize),
        .s_axi_awburst(m_axi_awburst), .s_axi_awlock(m_axi_awlock),
        .s_axi_awcache(m_axi_awcache), .s_axi_awprot(m_axi_awprot),
        .s_axi_awqos(m_axi_awqos), .s_axi_awvalid(m_axi_awvalid),
        .s_axi_awready(m_axi_awready),
        .s_axi_wdata(m_axi_wdata), .s_axi_wstrb(m_axi_wstrb),
        .s_axi_wlast(m_axi_wlast), .s_axi_wvalid(m_axi_wvalid),
        .s_axi_wready(m_axi_wready),
        .s_axi_bready(m_axi_bready), .s_axi_bid(m_axi_bid),
        .s_axi_bresp(m_axi_bresp), .s_axi_bvalid(m_axi_bvalid),
        .s_axi_arid(m_axi_arid), .s_axi_araddr(m_axi_araddr),
        .s_axi_arlen(m_axi_arlen), .s_axi_arsize(m_axi_arsize),
        .s_axi_arburst(m_axi_arburst), .s_axi_arlock(m_axi_arlock),
        .s_axi_arcache(m_axi_arcache), .s_axi_arprot(m_axi_arprot),
        .s_axi_arqos(m_axi_arqos), .s_axi_arvalid(m_axi_arvalid),
        .s_axi_arready(m_axi_arready),
        .s_axi_rready(m_axi_rready), .s_axi_rid(m_axi_rid),
        .s_axi_rdata(m_axi_rdata), .s_axi_rresp(m_axi_rresp),
        .s_axi_rlast(m_axi_rlast), .s_axi_rvalid(m_axi_rvalid)
    );
endmodule
