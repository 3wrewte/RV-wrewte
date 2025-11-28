`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module RV32DEC_REG(
    input         clk       ,
    input         rst_n     ,
    input [31:0]  instr_in  ,
    input [31:0]  pc_in     ,
    input         en1       , // en_ex from CU
    input         en2       , // en_mem from CU
    input         setz_dec  , // flush from CU (replaces local en2^en1)
    input [4:0]   waddr     ,
    input [31:0]  wdata     ,
    output [31:0] ocu       ,
    // note: en_out removed (CU drives en signals centrally)
    output [6:0]  opcode_out,
    output [31:0] rs1_out   ,
    output [31:0] rs2_out   ,
    output [4:0]  rdaddr_out,
    output [2:0]  funct3_out,
    output [6:0]  funct7_out,
    output [31:0] imm_out   ,
    output [31:0] pc_out   ,
    // expose the pre-STEP_REG opcode (combinational) so CU can use it
    output [6:0]  opcode_pre
    );
    wire[6:0]  opcode  ;
    wire[4:0]  rs1addr ;
    wire[4:0]  rs2addr ;
    wire[4:0]  rdaddr  ;
    wire[2:0]  funct3  ;
    wire[6:0]  funct7  ;
    wire[31:0] imm     ;
    wire[31:0] rs1     ;
    wire[31:0] rs2     ;
    RV32DEC RV32DEC_u(
        .instr  (instr_in),
        .opcode (opcode  ),
        .rs1addr(rs1addr ),
        .rs2addr(rs2addr ),
        .rdaddr (rdaddr  ),
        .funct3 (funct3  ),
        .funct7 (funct7  ),
        .imm    (imm     )
    );
    registers32#(            
        .depth(5)        
    ) registers32_u(     
        .clk   (clk    ), 
        .rst_n (rst_n  ), 
        .r1addr(rs1addr), 
        .r2addr(rs2addr), 
        .waddr (waddr  ), 
        .rdata1(rs1    ), 
        .rdata2(rs2    ), 
        .wdata (wdata  )  
    );                   
    
    wire en;
    assign en = en2; // pipeline register enable is en2 as before (driving the STEP_REG)
    // setz is provided by CU now
    STEP_REG#(.WIDTH(7 ))STEP_REG_opcode(.clk(clk),.rst_n(rst_n),.en(en),.setz(setz_dec),.in(opcode),.out(opcode_out));
    STEP_REG#(.WIDTH(32))STEP_REG_rs1   (.clk(clk),.rst_n(rst_n),.en(en),.setz(setz_dec),.in(rs1   ),.out(rs1_out   ));
    STEP_REG#(.WIDTH(32))STEP_REG_rs2   (.clk(clk),.rst_n(rst_n),.en(en),.setz(setz_dec),.in(rs2   ),.out(rs2_out   ));
    STEP_REG#(.WIDTH(5 ))STEP_REG_rdaddr(.clk(clk),.rst_n(rst_n),.en(en),.setz(setz_dec),.in(rdaddr),.out(rdaddr_out));
    STEP_REG#(.WIDTH(3 ))STEP_REG_funct3(.clk(clk),.rst_n(rst_n),.en(en),.setz(setz_dec),.in(funct3),.out(funct3_out));
    STEP_REG#(.WIDTH(7 ))STEP_REG_funct7(.clk(clk),.rst_n(rst_n),.en(en),.setz(setz_dec),.in(funct7),.out(funct7_out));
    STEP_REG#(.WIDTH(32))STEP_REG_imm   (.clk(clk),.rst_n(rst_n),.en(en),.setz(setz_dec),.in(imm   ),.out(imm_out   ));
    STEP_REG#(.WIDTH(32))STEP_REG_pc    (.clk(clk),.rst_n(rst_n),.en(en),.setz(setz_dec),.in(pc_in ),.out(pc_out    ));
    
    RV32OPDEC RV32OPDEC_u(
        .opcode(opcode),
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
    
    
    // en_out is removed, CU owns en signals now.
    
    wire [31:0] ocu1;
    wire [31:0] ocu2;
    DEC #(
        .WIDTH(5)
    )DEC_1(
        .in(rs1addr),
        .out(ocu1)
    );
    DEC #(
        .WIDTH(5)
    )DEC_2(
        .in(rs2addr),
        .out(ocu2)
    );
    assign ocu = (ocu1 | ocu2) & (~32'b1);
    assign opcode_pre = opcode; // expose pre-registered opcode for CU
endmodule
