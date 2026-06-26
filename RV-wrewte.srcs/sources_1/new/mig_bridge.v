`timescale 1ns / 1ps
// mig_bridge.v - Translates cache lower_* interface to MIG native app_*.
// Single outstanding request with a simple toggle handshake across clocks.

module mig_bridge(
    input             clk,
    input             rst_n,

    input             ui_clk,
    input             ui_rst,

    // --- Cache lower_* interface (clk domain) ---
    input             lower_valid,
    input             lower_ls,         // 1=load, 0=store
    input  [31:0]     lower_addr,
    input  [31:0]     lower_data,
    input  [4:0]      lower_id,
    input  [3:0]      lower_mask,
    output            lower_ls_valid,   // bridge can accept
    output reg        lower_submit_valid,
    output reg [4:0]  lower_submit_id,
    output reg [31:0] lower_submit_data,

    // --- MIG app_* interface (ui_clk domain) ---
    output reg [27:0]  app_addr,
    output reg [2:0]   app_cmd,
    output reg         app_en,
    input              app_rdy,
    output reg [255:0] app_wdf_data,
    output reg [31:0]  app_wdf_mask,
    output reg         app_wdf_end,
    output reg         app_wdf_wren,
    input              app_wdf_rdy,
    input  [255:0]     app_rd_data,
    input              app_rd_data_valid,
    input              app_rd_data_end,
    input              init_calib_complete
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

    // These response regs are written in ui_clk and held stable until
    // the next request, so sampling after the toggle sync is safe here.
    reg        resp_toggle;
    reg [4:0]  resp_id;
    reg [31:0] resp_data;

    assign lower_ls_valid = !req_busy && calib_s1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_toggle          <= 1'b0;
            req_busy            <= 1'b0;
            req_ls              <= 1'b0;
            req_addr            <= 32'b0;
            req_data            <= 32'b0;
            req_id              <= 5'b0;
            req_mask            <= 4'b0;
            lower_submit_valid  <= 1'b0;
            lower_submit_id     <= 5'b0;
            lower_submit_data   <= 32'b0;
            resp_toggle_s0      <= 1'b0;
            resp_toggle_s1      <= 1'b0;
            resp_toggle_seen    <= 1'b0;
            calib_s0            <= 1'b0;
            calib_s1            <= 1'b0;
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
    // ui_clk domain MIG FSM
    // =========================================================
    localparam S_IDLE    = 2'd0;
    localparam S_WR      = 2'd1;
    localparam S_RD      = 2'd2;
    localparam S_RD_WAIT = 2'd3;

    reg [1:0] state;
    reg       wr_cmd_done;
    reg       wr_data_done;

    reg req_toggle_u0, req_toggle_u1, req_toggle_seen_u;
    reg        u_req_ls;
    reg [31:0] u_req_addr;
    reg [31:0] u_req_data;
    reg [4:0]  u_req_id;
    reg [3:0]  u_req_mask;

    wire [2:0]  u_word_sel = u_req_addr[4:2];
    wire [27:0] u_mig_addr = {u_req_addr[29:5], 3'b000};
    wire [31:0] u_byte_enable = ({28'b0, u_req_mask} << {u_word_sel, 2'b0});
    wire [255:0] u_wdata256 = {224'b0, u_req_data};

    wire wr_cmd_accept  = (state == S_WR) && !wr_cmd_done  && app_rdy;
    wire wr_data_accept = (state == S_WR) && !wr_data_done && app_wdf_rdy;
    wire wr_done_next   = (wr_cmd_done || wr_cmd_accept) && (wr_data_done || wr_data_accept);

    always @(*) begin
        app_addr     = 28'b0;
        app_cmd      = 3'b0;
        app_en       = 1'b0;
        app_wdf_data = 256'b0;
        app_wdf_mask = 32'hFFFFFFFF;
        app_wdf_end  = 1'b0;
        app_wdf_wren = 1'b0;

        case (state)
            S_WR: begin
                app_addr     = u_mig_addr;
                app_cmd      = 3'd0;
                app_en       = !wr_cmd_done;
                app_wdf_data = u_wdata256 << {u_word_sel, 5'b0};
                app_wdf_mask = ~u_byte_enable;
                app_wdf_end  = !wr_data_done;
                app_wdf_wren = !wr_data_done;
            end
            S_RD: begin
                app_addr = u_mig_addr;
                app_cmd  = 3'd1;
                app_en   = 1'b1;
            end
        endcase
    end

    always @(posedge ui_clk or posedge ui_rst) begin
        if (ui_rst) begin
            state             <= S_IDLE;
            req_toggle_u0     <= 1'b0;
            req_toggle_u1     <= 1'b0;
            req_toggle_seen_u <= 1'b0;
            u_req_ls          <= 1'b0;
            u_req_addr        <= 32'b0;
            u_req_data        <= 32'b0;
            u_req_id          <= 5'b0;
            u_req_mask        <= 4'b0;
            wr_cmd_done       <= 1'b0;
            wr_data_done      <= 1'b0;
            resp_toggle       <= 1'b0;
            resp_id           <= 5'b0;
            resp_data         <= 32'b0;
        end else begin
            req_toggle_u0 <= req_toggle;
            req_toggle_u1 <= req_toggle_u0;

            case (state)
                S_IDLE: begin
                    if ((req_toggle_u1 != req_toggle_seen_u) && init_calib_complete) begin
                        req_toggle_seen_u <= req_toggle_u1;
                        u_req_ls          <= req_ls;
                        u_req_addr        <= req_addr;
                        u_req_data        <= req_data;
                        u_req_id          <= req_id;
                        u_req_mask        <= req_mask;
                        wr_cmd_done       <= 1'b0;
                        wr_data_done      <= 1'b0;
                        state             <= req_ls ? S_RD : S_WR;
                    end
                end

                S_WR: begin
                    if (wr_cmd_accept) begin
                        wr_cmd_done <= 1'b1;
                    end
                    if (wr_data_accept) begin
                        wr_data_done <= 1'b1;
                    end
                    if (wr_done_next) begin
                        resp_id     <= u_req_id;
                        resp_data   <= 32'b0;
                        resp_toggle <= ~resp_toggle;
                        wr_cmd_done <= 1'b0;
                        wr_data_done <= 1'b0;
                        state       <= S_IDLE;
                    end
                end

                S_RD: begin
                    if (app_rdy) begin
                        state <= S_RD_WAIT;
                    end
                end

                S_RD_WAIT: begin
                    if (app_rd_data_valid) begin
                        resp_id     <= u_req_id;
                        resp_data   <= app_rd_data >> {u_word_sel, 5'b0};
                        resp_toggle <= ~resp_toggle;
                        state       <= S_IDLE;
                    end
                end
            endcase
        end
    end

endmodule
