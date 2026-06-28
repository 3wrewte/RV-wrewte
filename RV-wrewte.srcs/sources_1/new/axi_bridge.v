`timescale 1ns / 1ps
// axi_bridge.v - Translates cache lower_* interface to single-beat AXI4.
// Single outstanding request with a toggle handshake across clk/axi_clk.

module axi_bridge(
    input             clk,
    input             rst_n,

    input             axi_clk,
    input             axi_rst_n,

    // --- Cache lower_* interface (clk domain) ---
    input             lower_valid,
    input             lower_ls,         // 1=load, 0=store
    input  [31:0]     lower_addr,
    input  [31:0]     lower_data,
    input  [4:0]      lower_id,
    input  [3:0]      lower_mask,
    output            lower_ls_valid,
    output reg        lower_submit_valid,
    output reg [4:0]  lower_submit_id,
    output reg [31:0] lower_submit_data,

    input             init_calib_complete,

    // --- AXI4 master interface (axi_clk domain) ---
    output reg [3:0]  m_axi_awid,
    output reg [28:0] m_axi_awaddr,
    output reg [7:0]  m_axi_awlen,
    output reg [2:0]  m_axi_awsize,
    output reg [1:0]  m_axi_awburst,
    output reg [0:0]  m_axi_awlock,
    output reg [3:0]  m_axi_awcache,
    output reg [2:0]  m_axi_awprot,
    output reg [3:0]  m_axi_awqos,
    output reg        m_axi_awvalid,
    input             m_axi_awready,

    output reg [31:0] m_axi_wdata,
    output reg [3:0]  m_axi_wstrb,
    output reg        m_axi_wlast,
    output reg        m_axi_wvalid,
    input             m_axi_wready,

    output reg        m_axi_bready,
    input      [3:0]  m_axi_bid,
    input      [1:0]  m_axi_bresp,
    input             m_axi_bvalid,

    output reg [3:0]  m_axi_arid,
    output reg [28:0] m_axi_araddr,
    output reg [7:0]  m_axi_arlen,
    output reg [2:0]  m_axi_arsize,
    output reg [1:0]  m_axi_arburst,
    output reg [0:0]  m_axi_arlock,
    output reg [3:0]  m_axi_arcache,
    output reg [2:0]  m_axi_arprot,
    output reg [3:0]  m_axi_arqos,
    output reg        m_axi_arvalid,
    input             m_axi_arready,

    output reg        m_axi_rready,
    input      [3:0]  m_axi_rid,
    input      [31:0] m_axi_rdata,
    input      [1:0]  m_axi_rresp,
    input             m_axi_rlast,
    input             m_axi_rvalid
);

    // =========================================================
    // clk domain request/response handshake
    // =========================================================
    reg        req_toggle;
    reg        req_busy;
    reg        req_ls;
    reg [31:0] req_addr;
    reg [31:0] req_data;
    reg [4:0]  req_id;
    reg [3:0]  req_mask;

    reg resp_toggle_s0, resp_toggle_s1, resp_toggle_seen;
    reg calib_s0, calib_s1;

    // Written in axi_clk and held stable until the next request.
    reg        resp_toggle;
    reg [4:0]  resp_id;
    reg [31:0] resp_data;

    assign lower_ls_valid = !req_busy && calib_s1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_toggle         <= 1'b0;
            req_busy           <= 1'b0;
            req_ls             <= 1'b0;
            req_addr           <= 32'b0;
            req_data           <= 32'b0;
            req_id             <= 5'b0;
            req_mask           <= 4'b0;
            lower_submit_valid <= 1'b0;
            lower_submit_id    <= 5'b0;
            lower_submit_data  <= 32'b0;
            resp_toggle_s0     <= 1'b0;
            resp_toggle_s1     <= 1'b0;
            resp_toggle_seen   <= 1'b0;
            calib_s0           <= 1'b0;
            calib_s1           <= 1'b0;
        end else begin
            lower_submit_valid <= 1'b0;

            resp_toggle_s0 <= resp_toggle;
            resp_toggle_s1 <= resp_toggle_s0;
            calib_s0       <= init_calib_complete;
            calib_s1       <= calib_s0;

            if (resp_toggle_s1 != resp_toggle_seen) begin
                resp_toggle_seen   <= resp_toggle_s1;
                lower_submit_valid <= 1'b1;
                lower_submit_id    <= resp_id;
                lower_submit_data  <= resp_data;
                req_busy           <= 1'b0;
            end else if (!req_busy && lower_valid && calib_s1) begin
                req_ls     <= lower_ls;
                req_addr   <= lower_addr;
                req_data   <= lower_data;
                req_id     <= lower_id;
                req_mask   <= lower_mask;
                req_busy   <= 1'b1;
                req_toggle <= ~req_toggle;
            end
        end
    end

    // =========================================================
    // axi_clk domain AXI master FSM
    // =========================================================
    localparam S_IDLE    = 3'd0;
    localparam S_WR      = 3'd1;
    localparam S_WR_RESP = 3'd2;
    localparam S_RD_ADDR = 3'd3;
    localparam S_RD_RESP = 3'd4;

    reg [2:0] state;
    reg       wr_addr_done;
    reg       wr_data_done;

    reg req_toggle_a0, req_toggle_a1, req_toggle_seen_a;
    reg        a_req_ls;
    reg [31:0] a_req_addr;
    reg [31:0] a_req_data;
    reg [4:0]  a_req_id;
    reg [3:0]  a_req_mask;

    wire wr_addr_accept = (state == S_WR) && !wr_addr_done && m_axi_awready;
    wire wr_data_accept = (state == S_WR) && !wr_data_done && m_axi_wready;
    wire wr_done_next = (wr_addr_done || wr_addr_accept) &&
                        (wr_data_done || wr_data_accept);

    always @(*) begin
        m_axi_awid     = a_req_id[3:0];
        m_axi_awaddr   = a_req_addr[28:0];
        m_axi_awlen    = 8'd0;
        m_axi_awsize   = 3'd2;      // 4 bytes
        m_axi_awburst  = 2'b01;     // INCR
        m_axi_awlock   = 1'b0;
        m_axi_awcache  = 4'b0011;
        m_axi_awprot   = 3'b000;
        m_axi_awqos    = 4'b0000;
        m_axi_awvalid  = (state == S_WR) && !wr_addr_done;

        m_axi_wdata    = a_req_data;
        m_axi_wstrb    = a_req_mask;
        m_axi_wlast    = 1'b1;
        m_axi_wvalid   = (state == S_WR) && !wr_data_done;

        m_axi_bready   = (state == S_WR_RESP);

        m_axi_arid     = a_req_id[3:0];
        m_axi_araddr   = a_req_addr[28:0];
        m_axi_arlen    = 8'd0;
        m_axi_arsize   = 3'd2;      // 4 bytes
        m_axi_arburst  = 2'b01;     // INCR
        m_axi_arlock   = 1'b0;
        m_axi_arcache  = 4'b0011;
        m_axi_arprot   = 3'b000;
        m_axi_arqos    = 4'b0000;
        m_axi_arvalid  = (state == S_RD_ADDR);

        m_axi_rready   = (state == S_RD_RESP);
    end

    always @(posedge axi_clk or negedge axi_rst_n) begin
        if (!axi_rst_n) begin
            state             <= S_IDLE;
            req_toggle_a0     <= 1'b0;
            req_toggle_a1     <= 1'b0;
            req_toggle_seen_a <= 1'b0;
            a_req_ls          <= 1'b0;
            a_req_addr        <= 32'b0;
            a_req_data        <= 32'b0;
            a_req_id          <= 5'b0;
            a_req_mask        <= 4'b0;
            wr_addr_done      <= 1'b0;
            wr_data_done      <= 1'b0;
            resp_toggle       <= 1'b0;
            resp_id           <= 5'b0;
            resp_data         <= 32'b0;
        end else begin
            req_toggle_a0 <= req_toggle;
            req_toggle_a1 <= req_toggle_a0;

            case (state)
                S_IDLE: begin
                    wr_addr_done <= 1'b0;
                    wr_data_done <= 1'b0;
                    if ((req_toggle_a1 != req_toggle_seen_a) && init_calib_complete) begin
                        req_toggle_seen_a <= req_toggle_a1;
                        a_req_ls          <= req_ls;
                        a_req_addr        <= req_addr;
                        a_req_data        <= req_data;
                        a_req_id          <= req_id;
                        a_req_mask        <= req_mask;
                        state             <= req_ls ? S_RD_ADDR : S_WR;
                    end
                end

                S_WR: begin
                    if (wr_addr_accept) begin
                        wr_addr_done <= 1'b1;
                    end
                    if (wr_data_accept) begin
                        wr_data_done <= 1'b1;
                    end
                    if (wr_done_next) begin
                        wr_addr_done <= 1'b0;
                        wr_data_done <= 1'b0;
                        state        <= S_WR_RESP;
                    end
                end

                S_WR_RESP: begin
                    if (m_axi_bvalid) begin
                        resp_id     <= a_req_id;
                        resp_data   <= 32'b0;
                        resp_toggle <= ~resp_toggle;
                        state       <= S_IDLE;
                    end
                end

                S_RD_ADDR: begin
                    if (m_axi_arready) begin
                        state <= S_RD_RESP;
                    end
                end

                S_RD_RESP: begin
                    if (m_axi_rvalid) begin
                        resp_id     <= a_req_id;
                        resp_data   <= m_axi_rdata;
                        resp_toggle <= ~resp_toggle;
                        state       <= S_IDLE;
                    end
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule
