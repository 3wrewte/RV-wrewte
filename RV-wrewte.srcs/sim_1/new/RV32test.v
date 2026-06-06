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
        .out_en(out_en)
    );
endmodule
