`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/05/2025 05:45:00 PM
// Design Name: 
// Module Name: dectest
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


module dectest(

    );
    reg [31:0] instr;
    wire[6:0]  opcode ;
    wire[4:0]  rs1addr;
    wire[4:0]  rs2addr;
    wire[4:0]  rdaddr ;
    wire[2:0]  funct3 ;
    wire[6:0]  funct7 ;
    wire[31:0] imm    ;
    RV32DEC RV32DEC_u(
        .instr  (instr  ),
        .opcode (opcode ),
        .rs1addr(rs1addr),
        .rs2addr(rs2addr),
        .rdaddr (rdaddr ),
        .funct3 (funct3 ),
        .funct7 (funct7 ),
        .imm    (imm    )
    );
    initial begin
             instr <= 32'b00000000_00000000_00000000_00000000;
        #100;instr <= 32'b00000000_01000000_01001011_00110111;//lui 1028
        #100;instr <= 32'b00000000_01000000_01001011_00010111;///auipc1028
        #100;instr <= 32'b10000000_00010000_00001011_01101111;//jal -523264
        #100;instr <= 32'b01000000_01001000_11011011_01100111;//jalr 1028
        #100;instr <= 32'b10000011_00101000_11011000_11100011;//B -1000
        #100;instr <= 32'b01000000_01001000_11011011_00000011;//Load 1028
        #100;instr <= 32'b10000011_00101000_11011000_10100011;//Store -999
        #100;instr <= 32'b01000000_01001000_11011011_00010011;//I 1028
        #100;instr <= 32'b01000001_00101000_11011011_00110011;//R
        #100;instr <= 32'b00000000_00000000_01010000_00001111;//fence
        #100;instr <= 32'b00000000_00001000_11011011_01110011;//csr
    end
endmodule
