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

    //----------------------------
    // Pipeline wires between stages
    //----------------------------
    pipe_t FETCH_out;
    pipe_t DEC_in;
    pipe_t DEC_out;
    pipe_t EX_in;
    pipe_t EX_out;
    pipe_t MEM_in;
    pipe_t MEM_out;
    pipe_t WB_in;

    //----------------------------
    // Control Unit signals
    //----------------------------
    wire stall_FETCH_DEC, stall_DEC_EX, stall_EX_MEM, stall_MEM_WB;
    wire flush_FETCH_DEC, flush_DEC_EX, flush_EX_MEM, flush_MEM_WB;
    wire en_PC;

    //----------------------------
    // Writeback signals to regfile & PC
    //----------------------------
    wire [4:0]  wb_rdaddr;
    wire [31:0] wb_rddata;
    wire        wb_jump;
    wire [31:0] wb_pc;

    //----------------------------
    // FETCH stage
    //----------------------------
    RV32FETCH u_FETCH(
        .clk       (clk),
        .rst_n     (rst_n),
        .write     (wb_jump),
        .wdata     (wb_pc),
        .en_PC     (en_PC),
        .fetch_out (FETCH_out)
    );

    //----------------------------
    // Pipeline Register: FETCH -> DEC
    //----------------------------
    PIPELINE_REG PIPELINE_REG_FETCH_DEC(
        .clk  (clk),
        .rst_n(rst_n),
        .stall(stall_FETCH_DEC),
        .flush(flush_FETCH_DEC),
        .in   (FETCH_out),
        .out  (DEC_in)
    );

    //----------------------------
    // DEC stage
    //----------------------------
    wire [31:0] ocu;
    wire [6:0]  opcode_pre;

    RV32DEC_REG u_DEC_REG(
        .clk      (clk),
        .rst_n    (rst_n),
        .fetch_in (DEC_in),
        .waddr    (wb_rdaddr),
        .wdata    (wb_rddata),
        .dec_out  (DEC_out),
        .ocu      (ocu),
        .opcode_pre(opcode_pre)
    );

    //----------------------------
    // Pipeline Register: DEC -> EX
    //----------------------------
    PIPELINE_REG PIPELINE_REG_DEC_EX(
        .clk  (clk),
        .rst_n(rst_n),
        .stall(stall_DEC_EX),
        .flush(flush_DEC_EX),
        .in   (DEC_out),
        .out  (EX_in)
    );

    //----------------------------
    // EX stage
    //----------------------------
    RV32EX u_EX(
        .dec_in (EX_in),
        .ocu    (ocu),
        .ex_out (EX_out)
    );

    //----------------------------
    // Pipeline Register: EX -> MEM
    //----------------------------
    PIPELINE_REG PIPELINE_REG_EX_MEM(
        .clk  (clk),
        .rst_n(rst_n),
        .stall(stall_EX_MEM),
        .flush(flush_EX_MEM),
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
        .stall(stall_MEM_WB),
        .flush(flush_MEM_WB),
        .in   (MEM_out),
        .out  (WB_in)
    );

    //----------------------------
    // WB stage
    //----------------------------
    RV32WB u_WB(
        .mem_in (WB_in),
        .rdaddr (wb_rdaddr),
        .rd     (wb_rddata),
        .jump   (wb_jump),
        .pc_out (wb_pc)
    );

    //------------------------------------
    // Control Unit
    //------------------------------------
    CU u_CU(
        .clk   (clk),
        .rst_n (rst_n),
    
        //---------------------------
        // decode stage COMBINATIONAL
        //---------------------------
        .ocu_dec        (ocu),              // from DEC_REG
        .opcode_dec_pre (opcode_pre),       // raw opcode (before DEC->EX reg)
    
        //---------------------------
        // pipeline opcodes
        //---------------------------
        .opcode_dec_ex  (EX_in.opcode),   // DEC->EX
        .opcode_ex_mem  (MEM_in.opcode),   // EX->MEM
        .opcode_mem_wb  (WB_in.opcode),   // MEM->WB
    
        //---------------------------
        // pipeline rd addresses
        //---------------------------
        .rdaddr_dec_ex  (EX_in.rd_addr),
        .rdaddr_ex_mem  (MEM_in.rd_addr),
        .rdaddr_mem_wb  (WB_in.rd_addr),
    
        //---------------------------
        // branch results (registered)
        //---------------------------
        .branch_ex_mem  (MEM_in.valid),   // EX result registered into MEM
        .branch_mem_wb  (WB_in.valid),   // MEM result registered into WB
    
        //---------------------------
        // outputs (STALL)
        //---------------------------
        .stall_FETCH_DEC(stall_FETCH_DEC),
        .stall_DEC_EX   (stall_DEC_EX),
        .stall_EX_MEM   (stall_EX_MEM),
        .stall_MEM_WB   (stall_MEM_WB),
    
        //---------------------------
        // outputs (FLUSH)
        //---------------------------
        .flush_FETCH_DEC(flush_FETCH_DEC),
        .flush_DEC_EX   (flush_DEC_EX),
        .flush_EX_MEM   (flush_EX_MEM),
        .flush_MEM_WB   (flush_MEM_WB),
        
        .en_PC(en_PC)
    );


    //----------------------------
    // output mapping (your style)
    //----------------------------
    //assign in_en  = 1'b1;
    //assign out    = wb_rddata;
    //assign out_en = 1'b1;

endmodule
//ENDFILE RV32TOP.v