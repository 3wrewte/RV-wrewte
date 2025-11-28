`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module RV32EX(
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
    
    input         en1       , // en_mem from CU
    input         en2       , // en_wb  from CU
    input  [31:0] ocu       ,
    input         setz_ex,     // from CU
    output        en_out,     // preserved as output? keep for compatibility (not driven)
    
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
    output        branch_out
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
    wire [31:0] res   ;
    wire [31:0] taddr ;
    wire        branch;
    
    
    reg [31:0] alu_in1;
    reg [31:0] alu_in2;
    always @(*)begin
        case(1'b1)
            lui    : alu_in1 <= imm_in;
            auipc  : alu_in1 <= pc_in ;
            jal    : alu_in1 <= pc_in ;
            jalr   : alu_in1 <= pc_in ;
            I      : alu_in1 <= rs1_in;
            R      : alu_in1 <= rs1_in;
            default: alu_in1 <= 32'b0 ;
        endcase
    end
    always @(*)begin
        case(1'b1)
            lui    : alu_in2 <= 32'b0  ;
            auipc  : alu_in2 <= imm_in ;
            jal    : alu_in2 <= 32'b100;
            jalr   : alu_in2 <= 32'b100;
            I      : alu_in2 <= imm_in ;
            R      : alu_in2 <= rs2_in ;
            default: alu_in2 <= 32'b0  ;
        endcase
    end
    RV32ALU RV32ALU_u(
        .in1   (alu_in1  ),
        .in2   (alu_in2  ),
        .funct3(funct3_in),
        .funct7(funct7_in),
        .out   (res      )
    );
    
    
    reg [31:0] taddr_in;
    always @(*)begin
        case(1'b1)
            jal    : taddr_in <= pc_in  ;
            jalr   : taddr_in <= rs1_in ;
            B      : taddr_in <= pc_in  ;
            L      : taddr_in <= rs1_in ;
            S      : taddr_in <= rs1_in ;
            default: taddr_in <= 32'b0  ;
        endcase
    end
    assign taddr = taddr_in + imm_in;
    
    RV32COND RV32COND_u(
        .in1   (rs1_in   ),
        .in2   (rs2_in   ),
        .funct3(funct3_in),
        .out   (branch   )
    );
    
    
    // the conflict/en_out logic moved to CU; preserve en_out pin but drive to 1 for compatibility
    assign en_out = 1'b1;
    
    
    wire en;
    assign en = en2;
    STEP_REG#(.WIDTH(7 ))STEP_REG_opcode(.clk(clk),.rst_n(rst_n),.en(en),.setz(setz_ex),.in(opcode_in),.out(opcode_out));
    STEP_REG#(.WIDTH(32))STEP_REG_rs1   (.clk(clk),.rst_n(rst_n),.en(en),.setz(setz_ex),.in(rs1_in   ),.out(rs1_out   ));
    STEP_REG#(.WIDTH(32))STEP_REG_rs2   (.clk(clk),.rst_n(rst_n),.en(en),.setz(setz_ex),.in(rs2_in   ),.out(rs2_out   ));
    STEP_REG#(.WIDTH(5 ))STEP_REG_rdaddr(.clk(clk),.rst_n(rst_n),.en(en),.setz(setz_ex),.in(rdaddr_in),.out(rdaddr_out));
    STEP_REG#(.WIDTH(3 ))STEP_REG_funct3(.clk(clk),.rst_n(rst_n),.en(en),.setz(setz_ex),.in(funct3_in),.out(funct3_out));
    STEP_REG#(.WIDTH(7 ))STEP_REG_funct7(.clk(clk),.rst_n(rst_n),.en(en),.setz(setz_ex),.in(funct7_in),.out(funct7_out));
    STEP_REG#(.WIDTH(32))STEP_REG_imm   (.clk(clk),.rst_n(rst_n),.en(en),.setz(setz_ex),.in(imm_in   ),.out(imm_out   ));
    STEP_REG#(.WIDTH(32))STEP_REG_pc    (.clk(clk),.rst_n(rst_n),.en(en),.setz(setz_ex),.in(pc_in    ),.out(pc_out    ));
    
    STEP_REG#(.WIDTH(32))STEP_REG_res   (.clk(clk),.rst_n(rst_n),.en(en),.setz(setz_ex),.in(res      ),.out(res_out    ));
    STEP_REG#(.WIDTH(32))STEP_REG_taddr (.clk(clk),.rst_n(rst_n),.en(en),.setz(setz_ex),.in(taddr    ),.out(taddr_out    ));
    STEP_REG#(.WIDTH(32))STEP_REG_branch(.clk(clk),.rst_n(rst_n),.en(en),.setz(setz_ex),.in(branch   ),.out(branch_out    ));
endmodule
