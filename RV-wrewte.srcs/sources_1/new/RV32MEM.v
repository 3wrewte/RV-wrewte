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
    
    input         en1       , // en_wb from CU (used by STEP_REG en)
    input  [31:0] ocu       ,
    input         setz_mem,   // from CU (we keep this as input but historically it was 0)
    output        en_out,    // keep pin for compatibility (not driven by module)
    
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
    
    
    // conflict/en_out logic moved to CU
    assign en_out = 1'b1;
    
    
    wire en;
    assign en = 1'b1; // preserved as before
    STEP_REG#(.WIDTH(7 ))STEP_REG_opcode(.clk(clk),.rst_n(rst_n),.en(en),.setz(setz_mem),.in(opcode_in),.out(opcode_out));
    STEP_REG#(.WIDTH(32))STEP_REG_rs1   (.clk(clk),.rst_n(rst_n),.en(en),.setz(setz_mem),.in(rs1_in   ),.out(rs1_out   ));
    STEP_REG#(.WIDTH(32))STEP_REG_rs2   (.clk(clk),.rst_n(rst_n),.en(en),.setz(setz_mem),.in(rs2_in   ),.out(rs2_out   ));
    STEP_REG#(.WIDTH(5 ))STEP_REG_rdaddr(.clk(clk),.rst_n(rst_n),.en(en),.setz(setz_mem),.in(rdaddr_in),.out(rdaddr_out));
    STEP_REG#(.WIDTH(3 ))STEP_REG_funct3(.clk(clk),.rst_n(rst_n),.en(en),.setz(setz_mem),.in(funct3_in),.out(funct3_out));
    STEP_REG#(.WIDTH(7 ))STEP_REG_funct7(.clk(clk),.rst_n(rst_n),.en(en),.setz(setz_mem),.in(funct7_in),.out(funct7_out));
    STEP_REG#(.WIDTH(32))STEP_REG_imm   (.clk(clk),.rst_n(rst_n),.en(en),.setz(setz_mem),.in(imm_in   ),.out(imm_out   ));
    STEP_REG#(.WIDTH(32))STEP_REG_pc    (.clk(clk),.rst_n(rst_n),.en(en),.setz(setz_mem),.in(pc_in    ),.out(pc_out    ));
    
    STEP_REG#(.WIDTH(32))STEP_REG_res   (.clk(clk),.rst_n(rst_n),.en(en),.setz(setz_mem),.in(res      ),.out(res_out    ));
    STEP_REG#(.WIDTH(32))STEP_REG_taddr (.clk(clk),.rst_n(rst_n),.en(en),.setz(setz_mem),.in(taddr_in ),.out(taddr_out    ));
    STEP_REG#(.WIDTH(32))STEP_REG_branch(.clk(clk),.rst_n(rst_n),.en(en),.setz(setz_mem),.in(branch_in),.out(branch_out    ));
    
    
endmodule
