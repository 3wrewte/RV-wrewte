//FILE RV32COND.v
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/06/2025 12:59:42 PM
// Design Name: 
// Module Name: RV32COND
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


module RV32COND(
    input      [31:0] in1   ,
    input      [31:0] in2   ,
    input      [2:0]  funct3,
    output reg        out
    );
    wire eq, less, less_u;
    assign eq = (in1 == in2);
    assign less = ($signed(in1) < $signed(in2));
    assign less_u = (in1 < in2);
    
    always @(*)begin
        case(funct3)
            3'b000: out <= eq;
            3'b001: out <= !eq;
            3'b100: out <= less;
            3'b101: out <= !less;
            3'b110: out <= less_u;
            3'b111: out <= !less_u;
            default:out <= 1'b0;
        endcase
    end
endmodule
//ENDFILE RV32COND.v
