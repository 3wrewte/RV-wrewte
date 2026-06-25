//FILE top.v
`timescale 1ns / 1ps

module top(
    input         sys_clk,
    input         sys_rst_n,
    input         uart_rxd,
    output        uart_txd
);
    RV32TOP RV32TOP_u(
        .clk     (sys_clk   ),
        .rst_n   (sys_rst_n ),
        .in      (32'b0     ),
        .in_en   (          ),
        .out     (          ),
        .out_en  (          ),
        .uart_rxd(uart_rxd  ),
        .uart_txd(uart_txd  )
    );
endmodule
//ENDFILE top.v
