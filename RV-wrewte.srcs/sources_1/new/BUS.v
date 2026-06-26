//FILE BUS.v
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/06/2025 06:27:28 PM
// Design Name: 
// Module Name: BUS
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


module BUS(
    input          clk   ,
    input          rst_n ,
    input          Load  ,
    input          Store ,
    input  [31:0]  addr  ,
    input  [31:0]  data  ,
    input  [2:0]   width ,
    output [31:0]  D_data,
    
    input [31:0]   in    ,
    output         in_en ,
    output [31:0]  out   ,
    output         out_en,

    input          uart_rxd,
    output         uart_txd
    );
    reg [31:0] bus;

    assign out_en = (addr == 32'd4) && Store;
    assign out = out_en? bus : 32'b0;

    assign D_data = Load? bus: 32'b0;

    //---------------------------------
    // UART MMIO
    // 0x080 (W): UART_TX data byte
    // 0x084 (R): UART_RX data byte (read clears rx_valid)
    // 0x088 (R): status {30'b0, rx_valid, tx_ready}
    //---------------------------------
    wire        rx_done;
    wire [7:0]  rx_byte;
    reg         rx_valid;
    reg  [7:0]  rx_latch;
    wire        tx_busy;

    uart_rx #(.CLK_FREQ(50000000), .UART_BPS(115200)) u_rx(
        .clk(clk), .rst_n(rst_n),
        .uart_rxd(uart_rxd),
        .uart_rx_done(rx_done),
        .uart_rx_data(rx_byte)
    );

    wire tx_wr = Store && (addr == 32'h80);
    uart_tx #(.CLK_FREQ(50000000), .UART_BPS(115200)) u_tx(
        .clk(clk), .rst_n(rst_n),
        .uart_tx_en(tx_wr),
        .uart_tx_data(data[7:0]),
        .uart_txd(uart_txd),
        .uart_tx_busy(tx_busy)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_valid <= 1'b0;
            rx_latch <= 8'b0;
        end else if (rx_done) begin
            rx_valid <= 1'b1;
            rx_latch <= rx_byte;
        end else if (Load && (addr == 32'h84)) begin
            rx_valid <= 1'b0;
        end
    end

    always @(*)begin
        if(Load)begin
            if(addr == 0)begin
                bus <= in;
            end else if(addr == 32'h84)begin
                bus <= {24'b0, rx_latch};
            end else if(addr == 32'h88)begin
                bus <= {30'b0, rx_valid, ~tx_busy};
            end else begin
                bus <= 32'b0;
            end
        end else begin
            bus <= data;
        end
    end
endmodule
//ENDFILE BUS.v
