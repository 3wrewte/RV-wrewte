`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/05/2025 04:25:34 PM
// Design Name: 
// Module Name: RV32OPDEC
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


module RV32OPDEC(
    input [6:0] opcode,
    output      lui   ,
    output      auipc ,
    output      jal   ,
    output      jalr  ,
    output      B     ,
    output      L     ,
    output      S     ,
    output      I     ,
    output      R     ,
    output      fence ,
    output      csr
    );
    assign lui   = (opcode == 7'b0110111)? 1: 0;
    assign auipc = (opcode == 7'b0010111)? 1: 0;
    assign jal   = (opcode == 7'b1101111)? 1: 0;
    assign jalr  = (opcode == 7'b1100111)? 1: 0;
    assign B     = (opcode == 7'b1100011)? 1: 0;
    assign L     = (opcode == 7'b0000011)? 1: 0;
    assign S     = (opcode == 7'b0100011)? 1: 0;
    assign I     = (opcode == 7'b0010011)? 1: 0;
    assign R     = (opcode == 7'b0110011)? 1: 0;
    assign fence = (opcode == 7'b0001111)? 1: 0;
    assign csr   = (opcode == 7'b1110011)? 1: 0;
endmodule

//RV32OPDEC RV32OPDEC_u(
//        .opcode(opcode),
//        .lui   (   lui),
//        .auipc ( auipc),
//        .jal   (   jal),
//        .jalr  (  jalr),
//        .B     (     B),
//        .L     (     L),
//        .S     (     S),
//        .I     (     I),
//        .R     (     R),
//        .fence ( fence),
//        .csr   (   csr)
//    );