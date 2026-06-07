//FILE BHT.v
`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// BHT: 2-bit saturating counter branch history table
// Direct-mapped, indexed by PC[INDEX_BITS+1:2]
// State: 00=strong NOT, 01=weak NOT, 10=weak TAKEN, 11=strong TAKEN
// Prediction: taken = state[1]
////////////////////////////////////////////////////////////////////////////////
module BHT #(
    parameter ENTRIES    = 64,
    parameter INDEX_BITS = $clog2(ENTRIES)
)(
    input                clk,
    input                rst_n,

    // lookup (combinational, used at fetch)
    input  [31:0]        lookup_pc,
    output               predict_taken,

    // update (sequential, from BRU resolve)
    input                update_valid,
    input  [31:0]        update_pc,
    input                update_taken
);
    localparam STRONG_NOT = 2'b00;
    localparam WEAK_NOT   = 2'b01;
    localparam WEAK_TAKEN = 2'b10;
    localparam STRONG_TAKEN=2'b11;

    reg [1:0] counter [0:ENTRIES-1];
    wire [INDEX_BITS-1:0] lookup_idx = lookup_pc[INDEX_BITS+1:2];
    wire [INDEX_BITS-1:0] update_idx = update_pc[INDEX_BITS+1:2];

    assign predict_taken = counter[lookup_idx][1];

    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < ENTRIES; i = i + 1) begin
                counter[i] <= WEAK_NOT;
            end
        end else if (update_valid) begin
            if (update_taken) begin
                case (counter[update_idx])
                    STRONG_NOT:  counter[update_idx] <= WEAK_NOT;
                    WEAK_NOT:    counter[update_idx] <= WEAK_TAKEN;
                    WEAK_TAKEN:  counter[update_idx] <= STRONG_TAKEN;
                    STRONG_TAKEN: counter[update_idx] <= STRONG_TAKEN;
                endcase
            end else begin
                case (counter[update_idx])
                    STRONG_NOT:  counter[update_idx] <= STRONG_NOT;
                    WEAK_NOT:    counter[update_idx] <= STRONG_NOT;
                    WEAK_TAKEN:  counter[update_idx] <= WEAK_NOT;
                    STRONG_TAKEN: counter[update_idx] <= WEAK_TAKEN;
                endcase
            end
        end
    end

endmodule
//ENDFILE BHT.v
