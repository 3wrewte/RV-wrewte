//FILE RV32ALU.v
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/05/2025 06:47:14 PM
// Design Name: 
// Module Name: RV32IALU
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


module RV32ALU(
    input [31:0]      in1   ,
    input [31:0]      in2   ,
    input [2:0]       funct3,
    input [6:0]       funct7,
    output reg [31:0] out
    );
    wire [31:0] SUM  ;
    wire [31:0] DIF  ;
    wire [31:0] SHL  ;
    wire [31:0] SLT  ;
    wire [31:0] SLTU ;
    wire [31:0] XOR  ;
    wire [31:0] SHR  ;
    wire [31:0] ASHR ;
    wire [31:0] OR   ;
    wire [31:0] AND  ;
    
    assign SUM  = in1 + in2;
    assign DIF  = in1 - in2;
    assign SHL  = in1 << in2[4:0];
    assign SLT  = {31'b0, $signed(in1) < $signed(in2)};
    assign SLTU = {31'b0, in1 < in2};
    assign XOR  = in1 ^ in2;
    assign SHR  = in1 >> in2[4:0];
    assign ASHR = $signed(in1) >>> in2[4:0];
    assign OR   = in1 | in2;
    assign AND  = in1 & in2;
    
    always @(*) begin
        case (funct3)
            3'b000: out = (funct7[5]) ? DIF : SUM;// ADD/SUB
            3'b001: out = SHL;// 移位左逻辑
            3'b010: out = SLT;// 有符号比较
            3'b011: out = SLTU;// 无符号比较
            3'b100: out = XOR;// 异或
            3'b101: out = (funct7[5]) ? ASHR : SHR;// 移位右逻辑/算术
            3'b110: out = OR;// 或
            3'b111: out = AND;// 与
            default: out = 32'd0;
        endcase
    end
endmodule
//ENDFILE RV32ALU.v
