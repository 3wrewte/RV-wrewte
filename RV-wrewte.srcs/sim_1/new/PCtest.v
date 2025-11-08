`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/06/2025 11:36:09 AM
// Design Name: 
// Module Name: PCtest
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


module PCtest(
output reg sys_clk,
    output reg sys_rst_n
    );
    reg en, write;
    wire [31:0] pc;
    initial begin
        en=0;
        write=0;
        sys_clk = 0;
        sys_rst_n = 0;
        #25;
            sys_rst_n = 1;
        #50;en=1;
        #50;write=1;
        #50;en=0;
        #50;write=0;
    end
    always #25 sys_clk = ~sys_clk;
    wire [31:0]din;
    assign din = 32'h2b1a3d4b;
    PC PC_u(
        .clk(sys_clk),
        .rst_n(sys_rst_n),
        .write(write),
        .din  (din  ),
        .en   (en   ),
        .pc   (pc   )
    );

endmodule
