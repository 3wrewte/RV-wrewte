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


module RAM32 #(
    parameter depth = 256
)(
    input                    clk   ,
    input                    rst_n ,
    input                    read  ,
    input                    write ,
    input      [31:0]        addr  ,
    input      [2:0]         width ,
    output reg [31:0]        rdata ,
    input      [31:0]        wdata
    );
    //reg clk, rst_n;
    //initial begin
    //    clk = 0;
    //    rst_n = 0;
    //    #50;
    //        rst_n = 1;
    //end
    //always #50 clk = ~clk;
    
    
    
    
    reg [31:0] data [0: depth - 1]; // depth 个 32 位寄存器
    // 一次性读取相邻两个字（64位）
    wire [63:0] double_word = {data[(addr >> 2)+1], data[addr >> 2]};
    // 用地址低3位控制移位（位选择仅需连线）
    //reg [31:0] word;
    //always @(*)begin
    //    case(addr[1:0])begin
    //        3'b00: word <=
    //    endcase 
    //end
    wire [63:0] selected_word = double_word >> {addr[1:0], 3'b0}; 
    wire [31:0] word      = selected_word[31:0];
    wire [15:0] half_word = selected_word[15:0];
    wire [ 7:0] byte      = selected_word[7:0];
    
    reg [31:0] mask;
    always @(*)begin
        case(width[1:0])
            2'b00:  mask <= {24'h000000, 8'hff};
            2'b01:  mask <= {16'h0000, 16'hffff};
            2'b10:  mask <= 32'hffffffff;
            default:mask <= 32'b0;
        endcase
    end 
    wire [63:0] mask64 = mask << {addr[1:0], 3'b0};
    wire [63:0] write_dword = wdata << {addr[1:0], 3'b0};
    
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for(i = 0 ; i < depth; i = i + 1)begin
                data[i] <= 0;
            end
        end else begin
            if(write)begin
                data[addr >> 2] <= (data[addr >> 2] & ~mask64[31:0]) | write_dword[31:0];
                data[(addr >> 2)+1] <= (data[(addr >> 2)+1] & ~mask64[63:32]) | write_dword[63:32];
            end else begin
                data[addr >> 2] <= data[addr >> 2];
                data[(addr >> 2)+1] <= data[(addr >> 2)+1];
            end
        end
    end
    

    //assign rdata = read? data[addr] : 32'b0;
    always @(*)begin
        if(read) begin
            case(width)
                3'b000:  rdata <= {{24{byte[7]}},byte[7:0]};  
                3'b001:  rdata <= {{16{byte[7]}},half_word[15:0]};
                3'b010:  rdata <= word;
                3'b100:  rdata <= {24'b0,byte[7:0]};
                3'b101:  rdata <= {16'b0,half_word[15:0]};
                default: rdata <= 32'b0; 
            endcase
        end else
            rdata <= 32'b0;
    end

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
