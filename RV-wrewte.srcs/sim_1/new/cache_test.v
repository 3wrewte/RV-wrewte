`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/10/2026 10:37:13 AM
// Design Name: 
// Module Name: cache_test
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


module cache_test(
    output reg sys_clk,
    output reg sys_rst_n
    );
    
    parameter LS_SIZE = 32;
    parameter LS_BITS = 5;
    reg                 clk               ;
    reg                 rst_n             ;
    reg                 cpu_ls            ;
    reg  [31:0]         cpu_addr          ;
    reg  [31:0]         cpu_data          ;
    reg                 cpu_valid         ;
    reg  [LS_BITS-1:0]  cpu_id            ;
    reg  [3:0]          cpu_mask          ;
    wire                ls_valid          ;      
    wire                submit_valid      ;
    wire  [LS_BITS-1:0] submit_id         ;
    wire  [31:0]        submit_data       ;
    wire                lower_ls          ;
    wire  [31:0]        lower_addr        ;
    wire  [31:0]        lower_data        ;
    wire                lower_valid       ;
    wire  [LS_BITS-1:0] lower_id          ;
    wire  [3:0]         lower_mask        ;
    reg                 lower_ls_valid    ; 
    reg                 lower_submit_valid;
    reg  [LS_BITS-1:0]  lower_submit_id   ;
    reg  [31:0]         lower_submit_data ;
    
    initial begin
        sys_clk = 0;
        sys_rst_n = 0;
        cpu_ls             = 0;
        cpu_addr           = 0;
        cpu_data           = 0;
        cpu_valid          = 0;
        cpu_id             = 0;
        cpu_mask           = 0;
        lower_ls_valid     = 0;
        lower_submit_valid = 0;
        lower_submit_id    = 0;
        lower_submit_data  = 0;
        #50;
        sys_rst_n = 1;
        cpu_ls             = 1;
        cpu_addr           = 32'b1111000011110000;
        cpu_data           = 0;
        cpu_valid          = 1;
        cpu_id             = 1;
        cpu_mask           = 4'b1111;
        lower_ls_valid     = 1;
        lower_submit_valid = 0;
        lower_submit_id    = 0;
        lower_submit_data  = 0;
        #100;
        cpu_ls             = 0;
        cpu_addr           = 0;
        cpu_data           = 0;
        cpu_valid          = 0;
        cpu_id             = 0;
        cpu_mask           = 0;
        lower_ls_valid     = 1;
        lower_submit_valid = 0;
        lower_submit_id    = 0;
        lower_submit_data  = 0;
        #100;
        cpu_ls             = 0;
        cpu_addr           = 0;
        cpu_data           = 0;
        cpu_valid          = 0;
        cpu_id             = 0;
        cpu_mask           = 0;
        lower_ls_valid     = 1;
        lower_submit_valid = 0;
        lower_submit_id    = 0;
        lower_submit_data  = 0;
        #100;
        cpu_ls             = 0;
        cpu_addr           = 0;
        cpu_data           = 0;
        cpu_valid          = 0;
        cpu_id             = 0;
        cpu_mask           = 0;
        lower_ls_valid     = 1;
        lower_submit_valid = 0;
        lower_submit_id    = 0;
        lower_submit_data  = 0;
        #100;
        cpu_ls             = 0;
        cpu_addr           = 0;
        cpu_data           = 0;
        cpu_valid          = 0;
        cpu_id             = 0;
        cpu_mask           = 0;
        lower_ls_valid     = 1;
        lower_submit_valid = 1;
        lower_submit_id    = 0;
        lower_submit_data  = 32'b0101001011010110;
        #100;
        cpu_ls             = 0;
        cpu_addr           = 0;
        cpu_data           = 0;
        cpu_valid          = 0;
        cpu_id             = 0;
        cpu_mask           = 0;
        lower_ls_valid     = 1;
        lower_submit_valid = 0;
        lower_submit_id    = 0;
        lower_submit_data  = 0;
        #100;
        cpu_ls             = 0;
        cpu_addr           = 32'b1111000011110000;
        cpu_data           = 32'b1001001000111001;
        cpu_valid          = 1;
        cpu_id             = 2;
        cpu_mask           = 4'b1111;
        lower_ls_valid     = 1;
        lower_submit_valid = 0;
        lower_submit_id    = 0;
        lower_submit_data  = 0;
        #100;
        cpu_ls             = 0;
        cpu_addr           = 0;
        cpu_data           = 0;
        cpu_valid          = 0;
        cpu_id             = 0;
        cpu_mask           = 0;
        lower_ls_valid     = 1;
        lower_submit_valid = 0;
        lower_submit_id    = 0;
        lower_submit_data  = 0;
    end
    always #50 sys_clk = ~sys_clk;
    
    
    
    
    always @(*) begin
        clk <= sys_clk;
        rst_n <= sys_rst_n;
    end   
    cache#(
    .LS_SIZE(LS_SIZE),.CACHE_LINES(256)) cache_u(
        .clk               (clk               ),
        .rst_n             (rst_n             ),
        .cpu_ls            (cpu_ls            ),
        .cpu_addr          (cpu_addr          ),
        .cpu_data          (cpu_data          ),
        .cpu_valid         (cpu_valid         ),
        .cpu_id            (cpu_id            ),
        .cpu_mask          (cpu_mask          ),
        .ls_valid          (ls_valid          ),
        .submit_valid      (submit_valid      ),
        .submit_id         (submit_id         ),
        .submit_data       (submit_data       ),
        .lower_ls          (lower_ls          ),
        .lower_addr        (lower_addr        ),
        .lower_data        (lower_data        ),
        .lower_valid       (lower_valid       ),
        .lower_id          (lower_id          ),
        .lower_mask        (lower_mask        ),
        .lower_ls_valid    (lower_ls_valid    ),
        .lower_submit_valid(lower_submit_valid),
        .lower_submit_id   (lower_submit_id   ),
        .lower_submit_data (lower_submit_data )
    );
endmodule
