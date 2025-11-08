`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/06/2025 11:23:56 AM
// Design Name: 
// Module Name: PC
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


module PC(
    input             clk  ,
    input             rst_n,
    input             write,
    input      [31:0] wdata,
    input             en   ,
    output reg [31:0] pc
    );
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)
            pc <= 32'b0;
        else begin
            case({write, en})
                2'b00:pc <= pc;
                2'b01:pc <= pc + 4;
                2'b10:pc <= wdata;
                2'b11:pc <= wdata;
                default: pc <= pc;
            endcase
        end
    end
endmodule
