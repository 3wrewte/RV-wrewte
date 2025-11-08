`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/06/2025 11:59:43 AM
// Design Name: 
// Module Name: DEC
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


module DEC #(
    parameter WIDTH = 5  // 默认 5-32 解码器
)(
    input  [WIDTH-1:0]        in ,
    output [(1 << WIDTH)-1:0] out
);
    genvar i;
    generate// 使用 generate + case 实现高效解码
        for (i = 0; i < 2**WIDTH; i = i + 1) begin : gen_decoder//generate
            assign out[i] = (in == i);//    // 大规模解码器使用树状结构优化
        end//    wire [OUTPUT_WIDTH-1:0] decoded;
    endgenerate//    
    //    // 生成 AND 门阵列
    //    for (integer i=0; i<OUTPUT_WIDTH; i++) begin : bit_gen
    //        // 为每个输出位生成门控逻辑
    //        wire [INPUT_WIDTH-1:0] match_val = i;
    //        assign decoded[i] = &(in ~^ match_val); // XNOR + AND
    //    end
    //    
    //    always @(*) out = decoded;
    //endgenerate
    
    //generate
    //    if (WIDTH == 1) begin : base_case
    //        // Base case: 1-to-2 decoder
    //        assign out[0] = ~in[0];
    //        assign out[1] =  in[0];
    //    end else begin : recursive_case
    //        // Split the decoder into two (WIDTH-1)-to-2^(WIDTH-1) decoders
    //        wire [(1 << (WIDTH-1))-1:0] lower;
    //        wire [(1 << (WIDTH-1))-1:0] upper;
    //
    //        DEC #(.WIDTH(WIDTH-1)) lower_decoder (
    //            .in(in[WIDTH-2:0]),
    //            .out(lower)
    //        );
    //
    //        DEC #(.WIDTH(WIDTH-1)) upper_decoder (
    //            .in(in[WIDTH-2:0]),
    //            .out(upper)
    //        );
    //
    //        genvar i;
    //        for (i = 0; i < 2**(WIDTH-1); i = i + 1) begin : output_mux
    //            assign out[i] = lower[i] & ~in[WIDTH-1];
    //            assign out[i + 2**(WIDTH-1)] = upper[i] & in[WIDTH-1];
    //        end
    //    end
    //endgenerate

                                                         
endmodule