//FILE registers32.v
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/05/2025 02:46:23 PM
// Design Name: 
// Module Name: reg32x32
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


module registers32 #(
    parameter depth = 5,
    parameter read_channel = 1,
    parameter write_channel = 1
)(
    input                    clk   ,
    input                    rst_n ,
    input [depth - 1:0]      r1addr[read_channel-1:0],
    input [depth - 1:0]      r2addr[read_channel-1:0],
    input [depth - 1:0]      waddr[write_channel-1:0],
    output[31:0]             rdata1[read_channel-1:0],
    output[31:0]             rdata2[read_channel-1:0],
    input [31:0]             wdata[write_channel-1:0]
    );
  reg [31:0] registers [0:(1 << depth) - 1]; // 32 个 32 位寄存器
  //reg [depth - 1:0] cnt;
  integer i;
  always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
      // 复位时将所有寄存器初始化为 0
          //cnt = 0;
          //repeat(1 << depth) begin
          //    registers[cnt] <= 0;
          //    cnt = cnt + 1;
          //end
          for(i = 0; i < (1 << depth); i= i + 1)begin
              registers[i] = 0;
          end
      end else begin
          for(i = 0; i < write_channel; i= i + 1)begin
            if(waddr[i] != 0)
                registers[waddr[i]] = wdata[i];
          end
      end
  end
  
  generate
    for(genvar k = 0; k < read_channel; k= k + 1)begin
        assign rdata1[k] = registers[r1addr[k]];
        assign rdata2[k] = registers[r2addr[k]];
    end
  endgenerate
endmodule


//registers32#(
//        .depth(5)
//    ) registers32_u(
//        .clk   (clk   ),
//        .rst_n (rst_n ),
//        .r1addr(r1addr),
//        .r2addr(r2addr),
//        .waddr (waddr ),
//        .rdata1(rdata1),
//        .rdata2(rdata2),
//        .wdata (wdata )
//    );
//ENDFILE registers32.v
