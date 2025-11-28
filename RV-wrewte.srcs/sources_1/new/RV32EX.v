`timescale 1ns / 1ps
`include "PIPELINE_REG.v"
// RV32EX.v -- now purely combinational EX logic; pipeline regs moved to TOP


module RV32EX(
    input  pipe_t dec_in,   // from DEC stage
    input  [31:0] ocu,      // for CU compatibility (not used inside EX)
    output pipe_t ex_out    // to MEM stage
    );

    // unpack inputs
    wire [6:0] opcode = dec_in.opcode;
    wire [2:0] funct3 = dec_in.funct3;
    wire [6:0] funct7 = dec_in.funct7;
    wire [31:0] rs1 = dec_in.rs1_data;
    wire [31:0] rs2 = dec_in.rs2_data;
    wire [31:0] imm = dec_in.imm;
    wire [31:0] pc  = dec_in.pc;
    wire jal = (opcode == 7'b1101111);
    wire jalr= (opcode == 7'b1100111);
    wire B   = (opcode == 7'b1100011);
    wire L   = (opcode == 7'b0000011);
    wire S   = (opcode == 7'b0100011);
    wire I   = (opcode == 7'b0010011) || (opcode == 7'b0000011) || (opcode == 7'b1100111); // rough
    wire R   = (opcode == 7'b0110011);

    // ALU inputs selection
    reg [31:0] alu_in1;
    reg [31:0] alu_in2;
    always @(*) begin
        if (jal || jalr) alu_in1 = pc;
        else if (I || R) alu_in1 = rs1;
        else if (opcode == 7'b0010111) alu_in1 = pc; // auipc-like
        else alu_in1 = 32'b0;
    end
    always @(*) begin
        if (jal || jalr) alu_in2 = 32'h4;
        else if (I) alu_in2 = imm;
        else if (R) alu_in2 = rs2;
        else alu_in2 = 32'b0;
    end

    wire [31:0] res;
    RV32ALU RV32ALU_u(
        .in1(alu_in1),
        .in2(alu_in2),
        .funct3(funct3),
        .funct7(funct7),
        .out(res)
    );

    // taddr calc: target address for branch/jump or mem addr
    reg [31:0] taddr;
    always @(*) begin
        if (jal || jalr) taddr = pc + imm;
        else if (B) taddr = pc + imm;
        else if (L || S) taddr = rs1 + imm;
        else taddr = 32'b0;
    end

    // branch condition
    wire branch;
    RV32COND RV32COND_u(
        .in1(rs1),
        .in2(rs2),
        .funct3(funct3),
        .out(branch)
    );

    // pack outputs to ex_out
    assign ex_out.instr     = dec_in.instr;
    assign ex_out.pc        = pc;
    assign ex_out.imm       = imm;
    assign ex_out.rs1_data  = rs1;
    assign ex_out.rs2_data  = rs2;
    assign ex_out.rs1_addr  = dec_in.rs1_addr;
    assign ex_out.rs2_addr  = dec_in.rs2_addr;
    assign ex_out.rd_addr   = dec_in.rd_addr;
    assign ex_out.opcode    = opcode;
    assign ex_out.funct3    = funct3;
    assign ex_out.funct7    = funct7;
    assign ex_out.result    = res;
    assign ex_out.taddr     = taddr;
    assign ex_out.valid     = branch;
    //assign ex_out.valid     = branch | jal | jalr | dec_in.valid; // mark special/valid

endmodule
