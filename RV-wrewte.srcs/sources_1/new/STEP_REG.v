`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/06/2025 01:15:35 PM
// Design Name: 
// Module Name: STEP_REG
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


module STEP_REG#(
    parameter WIDTH = 32
)(
    input                     clk  ,
    input                     rst_n,
    input                     en   ,
    input                     setz ,
    input [WIDTH - 1: 0]      in   ,
    output reg [WIDTH - 1: 0] out
    );
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n | setz)
            out <= 0;
        else begin
            if(en)
                out <= in;
            else
                out <= out;
        end
    end
endmodule
