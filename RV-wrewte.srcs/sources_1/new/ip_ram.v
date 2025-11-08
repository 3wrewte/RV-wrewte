`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/30/2025 06:48:00 PM
// Design Name: 
// Module Name: ip_ram
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


module ip_ram(
    input sys_clk,
    input sys_rst_n,
    output [7:0] dout
    );
wire clk, rst_n;
wire we; 
reg en; 
reg [4:0]addr;
reg [7:0] din;
assign clk = sys_clk;
assign rst_n = sys_rst_n;
blk_mem_gen_0 your_instance_name (
  .clka(clk),    // input wire clka
  .rsta(!sys_rst_n),            // input wire rsta
  .ena(en),      // input wire ena
  .wea(we),      // input wire [0 : 0] wea
  .addra(addr),  // input wire [4 : 0] addra
  .dina(din),    // input wire [7 : 0] dina
  .douta(dout)  // output wire [7 : 0] douta
);
//reg define
reg    [5:0]  rw_cnt ;                

assign we = (rw_cnt <= 6'd31 && en == 1'b1) ? 1'b1 : 1'b0;

//控制RAM使能信号
always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)
        en <= 1'b0;    
    else
        en <= 1'b1;    
end 

//读写控制计数器,计数器范围0~63
always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)
        rw_cnt <= 6'b0;    
    else if(rw_cnt == 6'd63  && en)
        rw_cnt <= 6'b0;
    else if(en)
        rw_cnt <= rw_cnt + 1'b1; 
    else
        rw_cnt <= 6'b0;      
end  

//读写地址信号 范围：0~31
always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)
        addr <= 5'b0;
    else if(addr == 5'd31 && en)
        addr <= 5'b0;
    else if (en)   
        addr <= addr + 1'b1;
    else
        addr <= 5'b0;         
end

//在WE拉高期间产生RAM写数据,变化范围是0~31
always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)
        din <= 8'b0;  
    else if(din < 8'd31 && we)
        din <= din + 1'b1;
    else
        din <= 8'b0 ;   
end  
endmodule
