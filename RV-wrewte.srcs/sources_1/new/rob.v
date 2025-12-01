//FILE rob.v
`timescale 1ns / 1ps
`include "PIPELINE_REG.v"
// Simple ring-buffer ROB (minimal): no speculative state yet, just push/pop & full flag.
// Fields stored minimal (valid + rdaddr) to avoid invasive changes.
// push: assert to allocate a new entry (tail moves)
// pop : assert to retire oldest entry (head moves)

module ROB #(
    parameter DEPTH = 32,
    parameter IDXW  = 5 // log2(DEPTH)
) (
    input clk,
    input rst_n,
    // push when DEC/dispatch issues an instr into ROB (front-end decided to issue)
    input push,
    input [4:0] push_rdaddr, // optional: store destination
    // pop when WB commits an instr
    input pop,
    output reg full,
    output reg empty,
    output reg [IDXW:0] count
);

    // storage (very small): valid + rdaddr
    reg valid_mem [0:DEPTH-1];
    reg [4:0] rd_mem   [0:DEPTH-1];

    reg [IDXW-1:0] head;
    reg [IDXW-1:0] tail;

    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            head <= 0;
            tail <= 0;
            count <= 0;
            full <= 1'b0;
            empty <= 1'b1;
            for (i = 0; i < DEPTH; i = i + 1) begin
                valid_mem[i] <= 1'b0;
                rd_mem[i] <= 5'b0;
            end
        end else begin
            // push
            if (push && !full) begin
                valid_mem[tail] <= 1'b1;
                rd_mem[tail] <= push_rdaddr;
                tail <= tail + 1'b1;
                count <= count + 1'b1;
            end
            // pop
            if (pop && !empty) begin
                valid_mem[head] <= 1'b0;
                head <= head + 1'b1;
                count <= count - 1'b1;
            end
            // Both push and pop same cycle: net change handled above (works for ring buffer)
            full <= (count == DEPTH);
            empty <= (count == 0);
        end
    end

endmodule
//ENDFILE rob.v