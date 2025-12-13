`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/13/2025 03:17:27 PM
// Design Name: 
// Module Name: realloc
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


module realloc#(
    parameter WIDTH = 32,
    parameter DEPTH = 32,
    parameter BITS = $clog2(DEPTH)
)(
    input  [BITS-1:0]  head          ,
    input  [WIDTH-1:0] in[DEPTH-1:0] ,
    output [WIDTH-1:0] out[DEPTH-1:0]
    );
    wire [WIDTH-1:0] step[BITS:0][DEPTH-1:0];
    generate
    for(genvar k = 0; k < DEPTH; k++)begin
            assign step[0][k] = in[k];
    end
    endgenerate 
    
    generate
        genvar i;
        genvar j;
        for(i = 0; i < BITS; i++)begin
            for(j = 0; j < DEPTH; j++)begin
                assign step[i+1][j] = (head[i])?step[i][{j + (1 << i)}[BITS-1:0]]:step[i][j];
            end
        end
    endgenerate
    
    generate
    for(genvar k = 0; k < DEPTH; k++)begin
            assign out[k] = step[BITS][k];
    end
    endgenerate 
endmodule
