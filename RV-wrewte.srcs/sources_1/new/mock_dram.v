`timescale 1ns / 1ps
// mock_dram.v - Behavioral DRAM model with MIG app_* interface
// For simulation only. Replaced by real MIG IP on FPGA.

module mock_dram #(
    parameter LATENCY = 8   // read latency in ui_clk cycles
)(
    input             ui_clk,
    input             ui_rst,        // active high (MIG convention)

    // MIG User Interface (app_*)
    input  [27:0]     app_addr,
    input  [2:0]      app_cmd,       // 0=write, 1=read
    input             app_en,
    output            app_rdy,
    input  [255:0]    app_wdf_data,
    input  [31:0]     app_wdf_mask,
    input             app_wdf_end,
    input             app_wdf_wren,
    output            app_wdf_rdy,
    output reg [255:0] app_rd_data,
    output            app_rd_data_end,
    output reg        app_rd_data_valid,
    output reg        init_calib_complete
);
    // Storage: 16K entries × 32 bytes = 512 KB
    reg [255:0] mem [0:16383];

    integer k;
    integer b;
    integer idx;
    initial begin
        for (k = 0; k < 16384; k = k + 1)
            mem[k] = 256'b0;
    end

    // Calibration: assert complete after 5 cycles
    reg [2:0] calib_cnt;
    always @(posedge ui_clk or posedge ui_rst) begin
        if (ui_rst) begin
            calib_cnt <= 0;
            init_calib_complete <= 0;
        end else begin
            if (calib_cnt < 5)
                calib_cnt <= calib_cnt + 1;
            else
                init_calib_complete <= 1;
        end
    end

    // Always ready to accept commands and write data
    assign app_rdy = 1'b1;
    assign app_wdf_rdy = 1'b1;

    // Latch write address on command, perform write when data arrives
    reg [27:0] wr_addr_q;
    reg        wr_pending;

    // Read pipeline
    reg [27:0] rd_addr_q;
    reg [3:0]  rd_lat;
    reg        rd_pending;

    always @(posedge ui_clk or posedge ui_rst) begin
        if (ui_rst) begin
            wr_pending       <= 0;
            rd_pending       <= 0;
            app_rd_data_valid <= 0;
            app_rd_data       <= 0;
            rd_lat            <= 0;
        end else begin
            app_rd_data_valid <= 0;  // default

            // --- Write command capture ---
            if (app_en && app_rdy && (app_cmd == 3'd0)) begin
                wr_addr_q  <= app_addr;
                wr_pending <= 1;
            end

            // --- Write data (with byte mask: 0=write, 1=skip) ---
            if (app_wdf_wren) begin
                idx = wr_pending ? wr_addr_q[27:3] : app_addr[27:3];
                for (b = 0; b < 32; b = b + 1) begin
                    if (!app_wdf_mask[b])
                        mem[idx][b*8 +: 8] <= app_wdf_data[b*8 +: 8];
                end
                wr_pending <= 0;
            end

            // --- Read command ---
            if (app_en && app_rdy && (app_cmd == 3'd1) && !rd_pending) begin
                rd_addr_q  <= app_addr;
                rd_lat     <= LATENCY[3:0];
                rd_pending <= 1;
            end

            // --- Read latency countdown ---
            if (rd_pending) begin
                if (rd_lat > 1) begin
                    rd_lat <= rd_lat - 1;
                end else begin
                    app_rd_data       <= mem[rd_addr_q[27:3]];
                    app_rd_data_valid <= 1;
                    rd_pending        <= 0;
                end
            end
        end
    end

    assign app_rd_data_end = app_rd_data_valid;

endmodule
