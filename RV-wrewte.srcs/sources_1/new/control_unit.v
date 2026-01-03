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
    output reg          stall_frontend,
    output reg          stall_backend ,

    // -------------------- Flush --------------------
    output reg          flush_frontend,
    output reg          flush_backend ,

    // -------------------- PC 重定向输出 --------------------
    output reg          redirect_valid,
    output reg [31:0]   redirect_pc   ,
    output reg          en_pc
);

    // =================================================================
    // 主逻辑
    // =================================================================
    wire flush;
    
    assign flush = rob_flush;
    always @(*) begin
        // 默认：所有 stall = 0，所有 flush = 0
        stall_frontend <= ~(rob_flush | rob_alloc_ready);
        stall_backend  <= 1'b0;

        flush_frontend <= flush;
        flush_backend  <= flush;

        redirect_valid <= rob_flush;
        redirect_pc    <= rob_new_pc;
        en_pc          <= rob_alloc_ready;
    end
endmodule

//ENDFILE control_unit.v