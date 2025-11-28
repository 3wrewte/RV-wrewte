`timescale 1ns / 1ps

module RV32FETCH(
    input         clk       ,
    input         rst_n     ,
    input         en1       , // traditionally connected to en_dec
    input         en2       , // traditionally connected to en_ex
    input         write     ,
    input [31:0]  wdata     ,
    input         setz_fetch, // from CU: flush for fetch's STEP_REGs
    output [31:0] instr_out ,
    output [31:0] pc_out 
    );
    wire[31:0] instr   ;
    wire[31:0] pc      ;
    wire en;
    PC PC_u(
        .clk  (clk  ),
        .rst_n(rst_n),
        .write(write),
        .wdata(wdata),
        .en   (en1  ), // PC increment controlled by en_dec (as original)
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
    
    // setz comes from CU; en is the stage en2 as before
    assign en = en2;
    STEP_REG#(.WIDTH(32))STEP_REG_instr (.clk(clk),.rst_n(rst_n),.en(en),.setz(setz_fetch),.in(instr ),.out(instr_out ));
    STEP_REG#(.WIDTH(32))STEP_REG_pc    (.clk(clk),.rst_n(rst_n),.en(en),.setz(setz_fetch),.in(pc    ),.out(pc_out    ));
    
endmodule
