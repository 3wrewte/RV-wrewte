`timescale 1ns / 1ps

module RV32WB(
    input         clk        ,
    input         rst_n      ,
    
    input [6:0]   opcode_in  ,
    input [31:0]  rs1_in     ,
    input [31:0]  rs2_in     ,
    input [4:0]   rdaddr_in  ,
    input [2:0]   funct3_in  ,
    input [6:0]   funct7_in  ,
    input [31:0]  imm_in     ,
    input [31:0]  pc_in      ,
    input [31:0]  res_in     ,
    input [31:0]  taddr_in   ,
    input         branch_in  ,
    
    input  [31:0] ocu       ,
    output        en_out    ,
    
    
    output [4:0]  rdaddr    ,
    output [31:0] rd        ,
    output        jump      ,
    output [31:0] pc  
    );
    
    
    RV32OPDEC RV32OPDEC_u(
        .opcode(opcode_in),
        .lui   (lui   ),
        .auipc (auipc ),
        .jal   (jal   ),
        .jalr  (jalr  ),
        .B     (B     ),
        .L     (L     ),
        .S     (S     ),
        .I     (I     ),
        .R     (R     ),
        .fence (fence ),
        .csr   (csr   )
    );
    
    assign rdaddr = rdaddr_in;
    assign rd     = res_in   ;
    assign jump   = jal | jalr | (B & branch_in);
    assign pc     = jump? taddr_in  : 32'b0;
    
    
    wire conflict_n;
    assign conflict_n = ((ocu & (1 << rdaddr_in)) == 32'b0);
    assign en_out = !(jal | jalr | B) & conflict_n;
    
    
    
    
endmodule