`timescale 1ns / 1ps
`include "PIPELINE_REG.v"
// cache_wrapper.v
// Replaces RV32MEM in the LSU lane.
// Routes MMIO (addr < 0x1000) to BUS (combinational, same cycle).
// Routes DDR3 (addr >= 0x1000) to cache (multi-cycle, asserts lsu_stall).

module cache_wrapper(
    input             clk,
    input             rst_n,
    input             flush,        // branch mispredict flush

    // Pipeline interface (same as RV32MEM)
    input  pipe_t     ex_in,
    output pipe_t     mem_out,

    // Stall / ready
    output            lsu_stall,
    output            lsu_ready,

    // MMIO bus (to BUS for UART/IN/OUT)
    output            Load,
    output            Store,
    output [31:0]     addr,
    output [31:0]     data,
    output [2:0]      width,
    input  [31:0]     D_data,

    // Cache interface (for DDR3)
    output reg        cpu_ls,
    output reg [31:0] cpu_addr,
    output reg [31:0] cpu_data,
    output reg        cpu_valid,
    output reg [4:0]  cpu_id,
    output reg [3:0]  cpu_mask,
    input             ls_valid,
    input             submit_valid,
    input  [4:0]      submit_id,
    input  [31:0]     submit_data
);

    // Decode instruction type
    wire [6:0] opcode = ex_in.opcode;
    wire is_load  = (opcode == 7'b0000011);
    wire is_store = (opcode == 7'b0100011);
    wire is_mem   = is_load | is_store;

    // Address routing
    wire is_ddr   = is_mem && (ex_in.taddr >= 32'h1000);
    wire is_mmio  = is_mem && (ex_in.taddr <  32'h1000);

    // FSM
    localparam S_IDLE = 1'b0, S_WAIT = 1'b1;
    reg state;
    reg [4:0] req_id_q;

    // Can accept when IDLE
    assign lsu_ready = (state == S_IDLE);

    // MMIO: combinational passthrough (same as old RV32MEM)
    assign Load  = is_mmio & is_load;
    assign Store = is_mmio & is_store;
    assign addr  = ex_in.taddr;
    assign data  = ex_in.rs2_data;
    assign width = ex_in.funct3;

    // funct3 → byte mask
    function [3:0] mask_from_funct3;
        input [2:0] f3;
        input [1:0] off;
        begin
            case (f3[1:0])
                2'b00: case (off)   // byte
                    2'b00: mask_from_funct3 = 4'b0001;
                    2'b01: mask_from_funct3 = 4'b0010;
                    2'b10: mask_from_funct3 = 4'b0100;
                    2'b11: mask_from_funct3 = 4'b1000;
                endcase
                2'b01: mask_from_funct3 = off[1] ? 4'b1100 : 4'b0011;  // half
                default: mask_from_funct3 = 4'b1111;                    // word
            endcase
        end
    endfunction

    // Cache interface (combinational)
    always @(*) begin
        cpu_valid = 1'b0;
        cpu_ls    = is_load;
        cpu_addr  = ex_in.taddr;
        cpu_data  = ex_in.rs2_data;
        cpu_id    = ex_in.rob_id[4:0];
        cpu_mask  = mask_from_funct3(ex_in.funct3, ex_in.taddr[1:0]);

        if (state == S_IDLE && is_ddr && ls_valid) begin
            cpu_valid = 1'b1;
        end
    end

    // Stall: combinational. Hold during flush to protect pipeline results.
    // Must stall for ANY DDR3 instruction in S_IDLE — the instruction stays
    // in PREG2 until the cache completes and result is delivered.
    assign lsu_stall = flush ||
                       (state == S_WAIT && !submit_valid) ||
                       (state == S_IDLE && is_ddr);

    // FSM sequential
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= S_IDLE;
            req_id_q <= 5'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    if (is_ddr && ls_valid) begin
                        req_id_q <= ex_in.rob_id[4:0];
                        state    <= S_WAIT;
                    end
                end
                S_WAIT: begin
                    if (submit_valid) begin
                        state <= S_IDLE;
                    end
                end
            endcase
        end
    end

    // Load data alignment for DDR3 results
    wire [1:0] byte_off = ex_in.taddr[1:0];
    wire [7:0] load_byte = submit_data >> {byte_off, 3'b0};
    wire [15:0] load_half = submit_data >> {byte_off[1], 4'b0};

    reg [31:0] ddr_load_ext;
    always @(*) begin
        case (ex_in.funct3[1:0])
            2'b00: ddr_load_ext = ex_in.funct3[2] ? {24'b0, load_byte}
                                                   : {{24{load_byte[7]}}, load_byte};
            2'b01: ddr_load_ext = ex_in.funct3[2] ? {16'b0, load_half}
                                                   : {{16{load_half[7]}}, load_half};
            default: ddr_load_ext = submit_data;
        endcase
    end

    // Result selection
    wire [31:0] load_result = is_ddr ? ddr_load_ext : D_data;
    wire [31:0] result = is_load ? load_result : ex_in.result;

    // mem_out (passthrough with result replaced)
    always @(*) begin
        mem_out.rob_id     = ex_in.rob_id;
        mem_out.instr      = ex_in.instr;
        mem_out.pc         = ex_in.pc;
        mem_out.imm        = ex_in.imm;
        mem_out.rs1_data   = ex_in.rs1_data;
        mem_out.rs2_data   = ex_in.rs2_data;
        mem_out.rs1_addr   = ex_in.rs1_addr;
        mem_out.rs2_addr   = ex_in.rs2_addr;
        mem_out.rd_addr    = ex_in.rd_addr;
        mem_out.opcode     = ex_in.opcode;
        mem_out.funct3     = ex_in.funct3;
        mem_out.funct7     = ex_in.funct7;
        mem_out.result     = result;
        mem_out.taddr      = ex_in.taddr;
        mem_out.jump       = ex_in.jump;
        mem_out.valid      = ex_in.valid;
        mem_out.pred_taken = ex_in.pred_taken;
        mem_out.pred_pc    = ex_in.pred_pc;
    end

endmodule
