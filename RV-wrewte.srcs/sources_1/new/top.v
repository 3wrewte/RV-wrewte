`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/07/2025 03:11:03 PM
// Design Name: 
// Module Name: top
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


module top(
    input sys_clk,
    input sys_rst_n,
    input [3:0] key,
    output [3:0] led
    );
    RV32TOP RV32TOP_u(
        .clk   (sys_clk   ),
        .rst_n (sys_rst_n ),
        .in    (key   ),
        .in_en (),
        .out   (led   ),
        .out_en()
    );
endmodule
