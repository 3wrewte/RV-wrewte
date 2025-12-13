`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/13/2025 06:59:09 PM
// Design Name: 
// Module Name: ENC
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

module ENC #(
    parameter WIDTH = 5  // 默认 32-5 encoder
)(
    input  [(1 << WIDTH)-1:0] in,
    output [WIDTH-1:0]        out
);
    
    generate
        // 为每个输出位生成逻辑
        for (genvar i = 0; i < WIDTH; i = i + 1) begin : gen_out_bits
            // 创建一个临时连线，存储所有需要或非的位
            wire [(1 << (WIDTH-1))-1:0] temp_bits;
            
            for (genvar j = 0; j < (1 << (WIDTH - i - 1)); j = j + 1) begin 
                for (genvar k = 0; k < (1 << i); k = k + 1) begin 
                    // 将对应的输入位连接到temp_bits中
                    assign temp_bits[(j << i) + k] = in[(j << (i + 1)) + k];
                end
            end
            
            // 计算或非：如果没有相关位为1，则输出1
            assign out[i] = ~(|temp_bits);
        end
    endgenerate
    
endmodule