//FILE RV32TOP.v
`timescale 1ns / 1ps
`include "PIPELINE_REG.v"

module RV32TOP(
    input         clk,
    input         rst_n,

    // instruction input port
    input  [31:0] in,
    output        in_en,

    // output port
    output [31:0] out,
    output        out_en
);
    parameter FETCH_NUM = 2;

    //----------------------------
    // Pipeline wires between stages
    //----------------------------
    pipe_t FETCH_out[FETCH_NUM - 1:0];
    pipe_t DEC_in[FETCH_NUM - 1:0];
    pipe_t DEC_out[FETCH_NUM - 1:0];
    pipe_t EX_in;
    pipe_t EX_out;
    pipe_t MEM_in;
    pipe_t MEM_out;
    pipe_t WB_in;

    //----------------------------
    // Control Unit signals
    //----------------------------
    wire stall_if_dec, stall_dec_rob, stall_rob_ex, stall_ex_mem, stall_mem_wb;
    wire flush_if_dec, flush_dec_rob, flush_rob_ex, flush_ex_mem, flush_mem_wb;
    wire en_PC;
    
    wire redirect_valid ;
    wire [31:0] redirect_pc;
    wire rob_alloc_ready;
    wire rob_flush      ;
    wire [31:0] rob_new_pc     ;
    
    pipe_t      alloc_in[FETCH_NUM - 1:0]     ;
    wire        rob_alloc_ready   ;
    pipe_t      issue_out        ;
    pipe_t      recieve_in       ;
    
    assign recieve_in = WB_in;
    //----------------------------
    // rob
    //----------------------------
    
    
    rob#(.ENTRY(FETCH_NUM)) rob_u(
        .clk              (clk              ),
        .rst_n            (rst_n            ),
        .alloc_in         (alloc_in         ),
        .rob_alloc_ready  (rob_alloc_ready  ),
        .issue_out        (issue_out        ),
        .recieve_in       (recieve_in       ),
        .rob_flush        (rob_flush        ),
        .rob_new_pc       (rob_new_pc       ) 
    );
    
    //------------------------------------
    // Control Unit
    //------------------------------------
    
    CU CU_u(
        .clk            (clk            ),
        .rst_n          (rst_n          ),
        .rob_alloc_ready(rob_alloc_ready),
        .rob_flush      (rob_flush      ),
        .rob_new_pc     (rob_new_pc     ),
        .stall_if_dec   (stall_if_dec   ),
        .stall_dec_rob  (stall_dec_rob  ),
        .stall_rob_ex   (stall_rob_ex   ),
        .stall_ex_mem   (stall_ex_mem   ),
        .stall_mem_wb   (stall_mem_wb   ),
        .flush_if_dec   (flush_if_dec   ),
        .flush_dec_rob  (flush_dec_rob  ),
        .flush_rob_ex   (flush_rob_ex   ),
        .flush_ex_mem   (flush_ex_mem   ),
        .flush_mem_wb   (flush_mem_wb   ),
        .redirect_valid (redirect_valid ),
        .redirect_pc    (redirect_pc    ),
        .en_pc          (en_PC          )
    );
    

    //----------------------------
    // FETCH stage
    //----------------------------
    RV32FETCH#(.FETCH_NUM(FETCH_NUM)) u_FETCH(
        .clk       (clk),
        .rst_n     (rst_n),
        .write     (redirect_valid),
        .wdata     (redirect_pc),
        .en_PC     (en_PC),
        .fetch_out (FETCH_out)
    );
    
    genvar k;
    generate
    for(k = 0; k < FETCH_NUM; k = k + 1)begin
        //----------------------------
        // Pipeline Register: FETCH -> DEC
        //----------------------------
        PIPELINE_REG PIPELINE_REG_FETCH_DEC(
            .clk  (clk),
            .rst_n(rst_n),
            .stall(stall_if_dec),
            .flush(flush_if_dec),
            .in   (FETCH_out[k]),
            .out  (DEC_in[k])
        );

        //----------------------------
        // DEC stage
        //----------------------------

        RV32DEC_REG u_DEC_REG(
            .clk      (clk),
            .rst_n    (rst_n),
            .fetch_in (DEC_in[k]),
            .dec_out  (DEC_out[k])
        );

        //----------------------------
        // Pipeline Register: DEC -> ROB
        //----------------------------
        PIPELINE_REG PIPELINE_REG_DEC_ROB(
            .clk  (clk),
            .rst_n(rst_n),
            .stall(stall_dec_rob),
            .flush(flush_dec_rob),
            .in   (DEC_out[k]),
            .out  (alloc_in[k])
        );
    end
    endgenerate
    
    PIPELINE_REG PIPELINE_REG_ROB_EX(
        .clk  (clk),
        .rst_n(rst_n),
        .stall(stall_rob_ex),
        .flush(flush_rob_ex),
        .in   (issue_out),
        .out  (EX_in)
    );
    
    //----------------------------
    // EX stage
    //----------------------------
    RV32EX u_EX(
        .dec_in (EX_in),
        .ex_out (EX_out)
    );

    //----------------------------
    // Pipeline Register: EX -> MEM
    //----------------------------
    PIPELINE_REG PIPELINE_REG_EX_MEM(
        .clk  (clk),
        .rst_n(rst_n),
        .stall(stall_ex_mem),
        .flush(flush_ex_mem),
        .in   (EX_out),
        .out  (MEM_in)
    );

    //----------------------------
    // BUS wires
    //----------------------------
    wire Load, Store;
    wire [31:0] bus_addr;
    wire [31:0] bus_data_out;
    wire [2:0]  bus_width;
    wire [31:0] bus_data_in;

    //----------------------------
    // MEM stage
    //----------------------------
    RV32MEM u_MEM(
        .ex_in (MEM_in),
        .Load  (Load),
        .Store (Store),
        .addr  (bus_addr),
        .data  (bus_data_out),
        .width (bus_width),
        .D_data(bus_data_in),
        .mem_out(MEM_out)
    );
    
    
    BUS BUS_u(
        .clk   (clk   ),
        .rst_n (rst_n ),
        .Load  (Load  ),
        .Store (Store ),
        .addr  (bus_addr  ),
        .data  (bus_data_out ),
        .width (bus_width ),
        .D_data(bus_data_in),
        .in    (in    ),
        .in_en (in_en ),
        .out   (out   ),
        .out_en(out_en)
    );
    

    //----------------------------
    // Pipeline Register: MEM -> WB
    //----------------------------
    PIPELINE_REG PIPELINE_REG_MEM_WB(
        .clk  (clk),
        .rst_n(rst_n),
        .stall(stall_mem_wb),
        .flush(flush_mem_wb),
        .in   (MEM_out),
        .out  (WB_in)
    );

    //----------------------------
    // WB stage
    //----------------------------
    //RV32WB u_WB(
    //    .mem_in (WB_in),
    //    .rdaddr (wb_rdaddr),
    //    .rd     (wb_rddata),
    //    .jump   (wb_jump),
    //    .pc_out (wb_pc)
    //);

    
    


    //----------------------------
    // output mapping (your style)
    //----------------------------
    //assign in_en  = 1'b1;
    //assign out    = wb_rddata;
    //assign out_en = 1'b1;

endmodule
//ENDFILE RV32TOP.v