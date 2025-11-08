`timescale 1ns / 1ps

module RV32FETCH(
    input         clk       ,
    input         rst_n     ,
    input         en1       ,
    input         en2       ,
    input         write     ,
    input [31:0]  wdata     ,
    output [31:0] instr_out ,
    output [31:0] pc_out 
    );
    wire[31:0] instr   ;
    wire[31:0] pc      ;
    wire en, setz;
    PC PC_u(
        .clk  (clk  ),
        .rst_n(rst_n),
        .write(write),
        .wdata(wdata),
        .en   (en1  ),
        .pc   (pc   )
    );                
    I_Cache#(
        .DEPTH(256)
    )I_Cache_u(
        .clk  (clk  ),
        .rst_n(rst_n),
        .pc   (pc   ),
        .rdata(instr)
    );
    
    assign setz = en2 ^ en1;
    assign en = en2;
    STEP_REG#(.WIDTH(32))STEP_REG_instr (.clk(clk),.rst_n(rst_n),.en(en),.setz(setz),.in(instr ),.out(instr_out ));
    STEP_REG#(.WIDTH(32))STEP_REG_pc    (.clk(clk),.rst_n(rst_n),.en(en),.setz(setz),.in(pc    ),.out(pc_out    ));
    
endmodule