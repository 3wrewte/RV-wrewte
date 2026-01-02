//FILE I_Cache.v
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/05/2025 11:39:09 PM
// Design Name: 
// Module Name: I_Cache
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


module I_Cache#(
    parameter DEPTH = 256,
    parameter ISSUE = 1
)(
    input                    clk   ,
    input                    rst_n ,
    input [31:0]             pc    ,
    output[31:0]             rdata[ISSUE-1: 0]//,
    //input [depth - 1:0]      waddr ,
    //output[31:0]             dout2 ,
    //input [31:0]             din
    );
    integer i, j;
    reg [7:0] instructions [0:DEPTH - 1]; 
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
          for(i = 0; i < DEPTH; i= i + 1)begin
              instructions[i] = 8'b0;
          end
          $readmemh("init_data.mem", instructions);  // 文件内容自动加载
        end else;
    end
    //initial begin
    //    for(integer i = 0; i < DEPTH; i= i + 1)begin
    //        instructions[i] = 32'b0;
    //    end
    //    $readmemh("init_data.mem", instructions);  // 文件内容自动加载
    //end
    
    genvar k;
    generate
        for(k = 0; k < ISSUE; k= k + 1)begin
            wire[29:0] id = (pc[31:2]) + k;
            assign rdata[k] = {instructions[(id << 2) | 2'b11], instructions[(id << 2) | 2'b10], instructions[(id << 2) | 2'b01], instructions[(id << 2) | 2'b00]};
            //assign dout2 = instructions[r2addr];
        end
    endgenerate
endmodule
//ENDFILE I_Cache.v
