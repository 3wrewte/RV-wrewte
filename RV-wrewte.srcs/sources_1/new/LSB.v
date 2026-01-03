`timescale 1ns / 1ps
module LSB #(
    parameter WIDTH = 5,
    parameter INPUT_WIDTH = 1 << WIDTH  // 输入宽度
)(
    input  [INPUT_WIDTH-1:0] in,
    output [WIDTH-1:0]       out,
    output                   valid
);
    
    // 使用casez语句的并行优先级编码（需要综合工具支持）
    reg [WIDTH-1:0] out_reg;
    
    always @(*) begin
        out_reg = {WIDTH{1'b0}};
        
        // 这是一个优先级编码器，找到最低位的1
        casez (in)
            {INPUT_WIDTH{1'b0}} : out_reg = {WIDTH{1'b0}};  // 全0情况
            default: begin
                // 从低位开始检查
                for (integer i = 0; i < INPUT_WIDTH; i = i + 1) begin
                    if (in[i]) begin
                        out_reg = i[WIDTH-1:0];
                        break;  // 找到第一个1就退出
                    end
                end
            end
        endcase
    end
    
    assign out = out_reg;
    assign valid = |in;
    
endmodule
