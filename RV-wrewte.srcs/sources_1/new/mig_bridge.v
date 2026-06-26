`timescale 1ns / 1ps
// mig_bridge.v - Translates cache lower_* interface to MIG app_* interface
// Single outstanding request. Simple handshake CDC (clk = ui_clk in sim).

module mig_bridge(
    input             clk,
    input             rst_n,

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

    // --- MIG app_* interface ---
    output reg [27:0] app_addr,
    output reg [2:0]  app_cmd,
    output reg        app_en,
    input             app_rdy,
    output reg [255:0] app_wdf_data,
    output reg [31:0] app_wdf_mask,
    output reg        app_wdf_end,
    output reg        app_wdf_wren,
    input             app_wdf_rdy,
    input  [255:0]   app_rd_data,
    input             app_rd_data_valid,
    input             app_rd_data_end,
    input             init_calib_complete
);

    // FSM
    localparam S_IDLE = 2'd0,
               S_WR   = 2'd1,   // send write command + data
               S_RD   = 2'd2,   // send read command
               S_RD_WAIT = 2'd3; // wait for read data
    reg [1:0] state;

    // Latched request
    reg        req_ls;
    reg [31:0] req_addr;
    reg [31:0] req_data;
    reg [4:0]  req_id;

    // Ready when idle and calibrated
    assign lower_ls_valid = (state == S_IDLE) && init_calib_complete;

    // Address conversion: byte addr -> MIG word addr
    wire [27:0] mig_addr = req_addr[29:2];   // 28-bit word address
    wire [2:0]  word_sel = req_addr[4:2];    // which 32-bit word in 256-bit beat

    // Combinational MIG outputs
    wire [255:0] wdata256 = {224'b0, req_data};
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
                app_addr     = mig_addr;
                app_cmd      = 3'd0;       // write
                app_en       = 1'b1;
                app_wdf_data = wdata256 << {word_sel, 5'b0};
                app_wdf_mask = ~(32'hF << {word_sel, 2'b0});
                app_wdf_end  = 1'b1;
                app_wdf_wren = 1'b1;
            end
            S_RD: begin
                app_addr = mig_addr;
                app_cmd  = 3'd1;           // read
                app_en   = 1'b1;
            end
        endcase
    end

    // FSM sequential
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state              <= S_IDLE;
            lower_submit_valid <= 0;
            lower_submit_id    <= 0;
            lower_submit_data  <= 0;
            req_ls             <= 0;
            req_addr           <= 0;
            req_data           <= 0;
            req_id             <= 0;
        end else begin
            lower_submit_valid <= 0;  // default: pulse

            case (state)
                S_IDLE: begin
                    if (lower_valid && init_calib_complete) begin
                        req_ls   <= lower_ls;
                        req_addr <= lower_addr;
                        req_data <= lower_data;
                        req_id   <= lower_id;
                        state    <= lower_ls ? S_RD : S_WR;
                    end
                end

                S_WR: begin
                    if (app_rdy && app_wdf_rdy) begin
                        lower_submit_valid <= 1;
                        lower_submit_id    <= req_id;
                        lower_submit_data  <= 32'b0;
                        state              <= S_IDLE;
                    end
                end

                S_RD: begin
                    if (app_rdy) begin
                        state <= S_RD_WAIT;
                    end
                end

                S_RD_WAIT: begin
                    if (app_rd_data_valid) begin
                        lower_submit_valid <= 1;
                        lower_submit_id    <= req_id;
                        lower_submit_data  <= app_rd_data >> {word_sel, 5'b0};
                        state              <= S_IDLE;
                    end
                end
            endcase
        end
    end

endmodule
