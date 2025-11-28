//FILE test.v
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/23/2025 09:48:33 PM
// Design Name: 
// Module Name: test
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


module test(
    output reg sys_clk,
    output reg sys_rst_n
    );
    initial begin
        sys_clk = 0;
        sys_rst_n = 0;
        #100;
            sys_rst_n = 1;
    end
    always #25 sys_clk = ~sys_clk;
    wire [31:0]dout;
regtest regtest_u(
    .clk(sys_clk),
    .rst_n(sys_rst_n),
    .dout(dout)
    );

endmodule
//ENDFILE test.v
