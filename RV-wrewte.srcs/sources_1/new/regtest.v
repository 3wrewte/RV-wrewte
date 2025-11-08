`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/05/2025 02:41:05 PM
// Design Name: 
// Module Name: regtest
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


module regtest(
    input clk,
    input rst_n,
    output [31:0] dout
    );
    reg [31:0] wdata;
    wire [4:0] r1addr;
    wire [4:0] r2addr;
    wire [4:0] waddr;
    wire [31:0] rdata1;
    wire [31:0] rdata2;
    //defparam registers32_u.depth = 5;
    //registers32#(
    //    .depth(5)
    //) registers32_u(
    //    .clk   (clk   ),
    //    .rst_n (rst_n ),
    //    .r1addr(r1addr),
    //    .r2addr(r2addr),
    //    .waddr (waddr ),
    //    .rdata1(rdata1),
    //    .rdata2(rdata2),
    //    .wdata (wdata )
    //);
    assign dout = rdata1;
    reg    [7:0]  rw_cnt ;  
    
    I_Cache I_Cache_u(
        .clk   (clk   ),
        .rst_n (rst_n ),
        .pc    (rw_cnt),
        .rdata (dout  )
    );
    
                  
    
    
    //读写控制计数器,计数器范围0~63
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            rw_cnt <= 6'b0;    
        else if(rw_cnt == 6'd63)
            rw_cnt <= 6'b0;
        else
            rw_cnt <= rw_cnt + 1'b1;    
    end  
    assign r1addr = (rw_cnt > 31)?0:rw_cnt;
    assign waddr = (rw_cnt > 31)?rw_cnt - 32:0;
    assign r2addr = 0;
    
    //在WE拉高期间产生RAM写数据,变化范围是0~31
    always @(posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0)
            wdata <= 8'b0;  
        else if(wdata < 8'd31)
            wdata <= wdata + 1'b1;
        else
            wdata <= 8'b0 ;   
    end  
endmodule
