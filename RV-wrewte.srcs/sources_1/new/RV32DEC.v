//FILE RV32DEC.v
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/05/2025 04:17:45 PM
// Design Name: 
// Module Name: RV32DEC
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


module RV32DEC(
    input      [31:0] instr  ,
    output     [6:0]  opcode ,
    output     [4:0]  rs1addr,
    output     [4:0]  rs2addr,
    output     [4:0]  rdaddr ,
    output     [2:0]  funct3 ,
    output     [6:0]  funct7 ,
    output reg [31:0] imm
    );
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
    wire R_type, I_type, S_type, B_type, U_type, J_type;
    
    assign R_type = R;
    assign I_type = jalr | L | I | fence | csr;
    assign S_type = S;
    assign B_type = B;
    assign U_type = lui | auipc;
    assign J_type = jal;
    
    assign opcode  = instr[6:0];
    assign rdaddr  = (S_type | B_type)? 5'b0 : instr[11:7];
    assign rs1addr = (U_type | J_type)? 5'b0 : instr[19:15];
    assign rs2addr = (R_type | S_type | B_type)? instr[24:20] : 5'b0;
    assign funct3  = (U_type | J_type)? 3'b0 : instr[14:12];
    assign funct7  = R_type? instr[31:25] : 7'b0;
    
    wire [31:0] I_imm;
    wire [31:0] S_imm;
    wire [31:0] B_imm;
    wire [31:0] U_imm;
    wire [31:0] J_imm;

    //assign I_imm[11:0] = instr[31:20];
    //generate
    //    genvar i;
    //    for (i = 12; i <= 31; i = i + 1) begin : sign_extend
    //        assign I_imm[i] = instr[31];
    //    end
    //endgenerate
    
    assign I_imm = {{20{instr[31]}},instr[31:20]};
    assign S_imm = {{20{instr[31]}},instr[31:25],instr[11:7]}; 
    assign B_imm = {{20{instr[31]}},instr[7],instr[30:25],instr[11:8],1'b0};
    assign U_imm = {instr[31:12],{12{1'b0}}};
	assign J_imm = {{12{instr[31]}},instr[19:12],instr[20],instr[30:21],1'b0};   
    
    
    //assign imm = I_type? I_imm:
    //             S_type? S_imm:
    //             B_type? B_imm:
    //             U_type? U_imm:
    //             J_type? J_imm:
    //             32'b0;
    always @(*) begin
        case(1'b1)
            I_type : imm <= I_imm;
            S_type : imm <= S_imm;
            B_type : imm <= B_imm;
            U_type : imm <= U_imm;
            J_type : imm <= J_imm;
            default: imm <= 32'b0;
        endcase
    end
endmodule
//ENDFILE RV32DEC.v
