//FILE control_unit.v
`timescale 1ns/1ps

module CU (
    input               clk,
    input               rst_n,

    // -------------------- ROB 状态 ------------------------
    input               rob_alloc_ready, // ROB可否分配新的 entry

    input               rob_flush,       // 分支错误 flush
    input      [31:0]   rob_new_pc,      // flush 后的正确 PC


    // -------------------- Stall --------------------
    output reg          stall_if_dec,
    output reg          stall_dec_rob,
    output reg          stall_rob_ex,
    output reg          stall_ex_mem,
    output reg          stall_mem_wb,

    // -------------------- Flush --------------------
    output reg          flush_if_dec,
    output reg          flush_dec_rob,
    output reg          flush_rob_ex,
    output reg          flush_ex_mem,
    output reg          flush_mem_wb,

    // -------------------- PC 重定向输出 --------------------
    output reg          redirect_valid,
    output reg [31:0]   redirect_pc   ,
    output reg          en_pc
);

    // =================================================================
    // 主逻辑
    // =================================================================
    wire flush;
    wire stall_frontend;
    
    assign flush = rob_flush;
    assign stall_frontend = ~(rob_flush | rob_alloc_ready);
    always @(*) begin
        // 默认：所有 stall = 0，所有 flush = 0
        stall_if_dec  <= stall_frontend;
        stall_dec_rob <= stall_frontend;
        stall_rob_ex  <= 1'b0;
        stall_ex_mem  <= 1'b0;
        stall_mem_wb  <= 1'b0;

        flush_if_dec  <= flush;
        flush_dec_rob <= flush;
        flush_rob_ex  <= flush;
        flush_ex_mem  <= flush;
        flush_mem_wb  <= flush;

        redirect_valid <= rob_flush;
        redirect_pc    <= rob_new_pc;
        en_pc          <= rob_alloc_ready;
    end
endmodule

//ENDFILE control_unit.v