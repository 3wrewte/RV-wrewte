`timescale 1ns / 1ps

module RV32MEM(
    input         clk       ,
    input         rst_n     ,
    
    input [6:0]   opcode_in ,
    input [31:0]  rs1_in    ,
    input [31:0]  rs2_in    ,
    input [4:0]   rdaddr_in ,
    input [2:0]   funct3_in ,
    input [6:0]   funct7_in ,
    input [31:0]  imm_in    ,
    input [31:0]  pc_in     ,
    input [31:0]  res_in    ,
    input [31:0]  taddr_in  ,
    input         branch_in ,
    
    input         en1       ,
    input  [31:0] ocu       ,
    output        en_out    ,
    
    output [6:0]  opcode_out,
    output [31:0] rs1_out   ,
    output [31:0] rs2_out   ,
    output [4:0]  rdaddr_out,
    output [2:0]  funct3_out,
    output [6:0]  funct7_out,
    output [31:0] imm_out   ,
    output [31:0] pc_out    ,
    
    output [31:0] res_out   ,
    output [31:0] taddr_out ,
    output        branch_out,
    
    output        Load      ,
    output        Store     ,
    output [31:0] addr      ,
    output [31:0] data      ,
    output [2:0]  width     ,
    input [31:0]  D_data
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
    
    wire [31:0] res;
    assign res = L? D_data : res_in;
    
    assign Load = L;
    assign Store = S;
    assign addr = taddr_in;
    assign data = rs2_in;
    assign width = funct3_in;
    
    
    wire conflict_n;
    assign conflict_n = ((ocu & (1 << rdaddr_in)) == 32'b0);
    assign en_out = (!(jal | jalr | B) & conflict_n) & en1;
    
    
    wire en, setz;
    assign setz = 1'b0;
    assign en = 1'b1;
    STEP_REG#(.WIDTH(7 ))STEP_REG_opcode(.clk(clk),.rst_n(rst_n),.en(en),.setz(setz),.in(opcode_in),.out(opcode_out));
    STEP_REG#(.WIDTH(32))STEP_REG_rs1   (.clk(clk),.rst_n(rst_n),.en(en),.setz(setz),.in(rs1_in   ),.out(rs1_out   ));
    STEP_REG#(.WIDTH(32))STEP_REG_rs2   (.clk(clk),.rst_n(rst_n),.en(en),.setz(setz),.in(rs2_in   ),.out(rs2_out   ));
    STEP_REG#(.WIDTH(5 ))STEP_REG_rdaddr(.clk(clk),.rst_n(rst_n),.en(en),.setz(setz),.in(rdaddr_in),.out(rdaddr_out));
    STEP_REG#(.WIDTH(3 ))STEP_REG_funct3(.clk(clk),.rst_n(rst_n),.en(en),.setz(setz),.in(funct3_in),.out(funct3_out));
    STEP_REG#(.WIDTH(7 ))STEP_REG_funct7(.clk(clk),.rst_n(rst_n),.en(en),.setz(setz),.in(funct7_in),.out(funct7_out));
    STEP_REG#(.WIDTH(32))STEP_REG_imm   (.clk(clk),.rst_n(rst_n),.en(en),.setz(setz),.in(imm_in   ),.out(imm_out   ));
    STEP_REG#(.WIDTH(32))STEP_REG_pc    (.clk(clk),.rst_n(rst_n),.en(en),.setz(setz),.in(pc_in    ),.out(pc_out    ));
    
    STEP_REG#(.WIDTH(32))STEP_REG_res   (.clk(clk),.rst_n(rst_n),.en(en),.setz(setz),.in(res      ),.out(res_out    ));
    STEP_REG#(.WIDTH(32))STEP_REG_taddr (.clk(clk),.rst_n(rst_n),.en(en),.setz(setz),.in(taddr_in ),.out(taddr_out    ));
    STEP_REG#(.WIDTH(32))STEP_REG_branch(.clk(clk),.rst_n(rst_n),.en(en),.setz(setz),.in(branch_in),.out(branch_out    ));
    
    
endmodule