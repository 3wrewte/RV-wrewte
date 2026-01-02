//FILE RV32FETCH.v 
`timescale 1ns / 1ps
`include "PIPELINE_REG.v"

module RV32FETCH#(
    parameter FETCH_NUM = 1
)(
    input         clk,
    input         rst_n,
    input         write,
    input  [31:0] wdata,
    input         en_PC,
    output pipe_t fetch_out[FETCH_NUM-1:0]  // to DEC stage (wire)
    );

    // internal fetch
    wire [31:0] instr[FETCH_NUM-1:0];
    reg [31:0] pc;

    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)
            pc <= 32'b0;
        else begin
            case({write, en_PC})
                2'b00:pc <= pc;
                2'b01:pc <= pc + (FETCH_NUM << 2);
                2'b10:pc <= wdata;
                2'b11:pc <= wdata;
                default: pc <= pc;
            endcase
        end
    end

    I_Cache#(.DEPTH(256),.ISSUE(FETCH_NUM)) I_Cache_u(
        .clk  (clk),
        .rst_n(rst_n),
        .pc   (pc),
        .rdata(instr)
    );
    
    genvar k;
    generate
    for(k = 0; k < FETCH_NUM; k= k + 1)begin
        // pack into pipe_t
        // only instr and pc are meaningful at this stage; other fields zeroed
        assign fetch_out[k].rob_id    = 32'b0;
        assign fetch_out[k].instr     = instr[k];
        assign fetch_out[k].pc        = pc + (k << 2);
        assign fetch_out[k].imm       = 32'b0;
        assign fetch_out[k].rs1_data  = 32'b0;
        assign fetch_out[k].rs2_data  = 32'b0;
        assign fetch_out[k].rs1_addr  = 5'b0;
        assign fetch_out[k].rs2_addr  = 5'b0;
        assign fetch_out[k].rd_addr   = 5'b0;
        assign fetch_out[k].opcode    = 7'b0;
        assign fetch_out[k].funct3    = 3'b0;
        assign fetch_out[k].funct7    = 7'b0;
        assign fetch_out[k].result    = 32'b0;
        assign fetch_out[k].taddr     = 32'b0;
        assign fetch_out[k].jump      = 1'b0;
        assign fetch_out[k].valid     = 1'b1;
    end
    endgenerate

endmodule
//ENDFILE RV32FETCH.v