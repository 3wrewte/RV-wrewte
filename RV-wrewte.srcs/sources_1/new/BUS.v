//FILE BUS.v
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/06/2025 06:27:28 PM
// Design Name: 
// Module Name: BUS
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


module BUS(
    input          clk   ,
    input          rst_n ,
    input          Load  ,
    input          Store ,
    input  [31:0]  addr  ,
    input  [31:0]  data  ,
    input  [2:0]   width ,
    output [31:0]  D_data,
    
    input [31:0]   in    ,
    output         in_en ,
    output [31:0]  out   ,
    output         out_en
    );
    reg [31:0] bus;
    wire       RAM_en    = (addr < 512 && addr >= 256);
    wire       RAM_read  = RAM_en? Load : 1'b0;
    wire       RAM_write = RAM_en? Store: 1'b0;
    wire [31:0]RAM_addr  = RAM_en? (addr & 32'hff) : 32'b0;
    wire [ 2:0]RAM_width = RAM_en? width: 3'b0;
    wire [31:0]RAM_rdata ;
    RAM32 RAM32_u(
        .clk  (clk  ), 
        .rst_n(rst_n), 
        .read (RAM_read ), 
        .write(RAM_write), 
        .addr (RAM_addr ), 
        .width(RAM_width), 
        .rdata(RAM_rdata), 
        .wdata(bus      )
    );
    assign out_en = (addr == 32'b100);
    assign out = out_en? bus : 32'b0;
    
    assign D_data = Load? bus: 32'b0;
    
    always @(*)begin
        if(Load)begin
            if(addr < 512 && addr >= 256)begin
                bus <= RAM_rdata;
            end else if(addr == 0)begin
                bus <= in;
            end else;
        end else begin
            bus <= data;
        end
    end
endmodule
//ENDFILE BUS.v
