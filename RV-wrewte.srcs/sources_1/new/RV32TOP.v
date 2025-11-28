`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module RV32TOP(
    input          clk   ,
    input          rst_n ,
    input [31:0]   in    ,
    output         in_en ,
    output [31:0]  out   ,
    output         out_en
    );
    // unified enable signals produced by CU
    wire en_dec, en_ex, en_mem, en_wb;
    wire setz_fetch, setz_dec, setz_ex, setz_mem;
    wire [31:0]ocu;
    
    wire [31:0] instr_if_dec;
    wire [31:0] pc_if_dec   ;
    
    wire [ 6:0]  opcode_dec_ex;
    wire [31:0]     rs1_dec_ex;
    wire [31:0]     rs2_dec_ex;
    wire [ 4:0]  rdaddr_dec_ex;
    wire [ 2:0]  funct3_dec_ex;
    wire [ 6:0]  funct7_dec_ex;
    wire [31:0]     imm_dec_ex;
    wire [31:0]      pc_dec_ex;
    
    wire [ 6:0]  opcode_ex_mem;
    wire [31:0]     rs1_ex_mem;
    wire [31:0]     rs2_ex_mem;
    wire [ 4:0]  rdaddr_ex_mem;
    wire [ 2:0]  funct3_ex_mem;
    wire [ 6:0]  funct7_ex_mem;
    wire [31:0]     imm_ex_mem;
    wire [31:0]      pc_ex_mem;
    wire [31:0]     res_ex_mem;
    wire [31:0]   taddr_ex_mem;
    wire         branch_ex_mem;
    
    wire [ 6:0]  opcode_mem_wb;
    wire [31:0]     rs1_mem_wb;
    wire [31:0]     rs2_mem_wb;
    wire [ 4:0]  rdaddr_mem_wb;
    wire [ 2:0]  funct3_mem_wb;
    wire [ 6:0]  funct7_mem_wb;
    wire [31:0]     imm_mem_wb;
    wire [31:0]      pc_mem_wb;
    wire [31:0]     res_mem_wb;
    wire [31:0]   taddr_mem_wb;
    wire         branch_mem_wb;
    
    // "pre" opcode from DEC (combinational) so CU can know if DEC instruction is branch/jump
    wire [6:0] opcode_pre_dec;
    
    wire [4:0]  rd_addr   ;
    wire [31:0] rd_data   ;
    wire        pc_jump   ;
    wire [31:0] pc_data   ;
    
    wire        bus_Load  ;
    wire        bus_Store ;
    wire [31:0] bus_addr  ;
    wire [31:0] bus_data  ;
    wire [ 2:0] bus_width ;
    wire [31:0] bus_D_data;
    
    // FETCH
    RV32FETCH RV32FETCH_u(
        .clk      (clk      ),
        .rst_n    (rst_n    ),
        .en1      (en_dec   ),  // en_dec provided by CU
        .en2      (en_ex    ),  // en_ex provided by CU
        .write    (pc_jump  ),
        .wdata    (pc_data  ),
        .setz_fetch(setz_fetch),
        .instr_out(instr_if_dec),
        .pc_out   (pc_if_dec   )
    );
    
    // DEC/REG
    RV32DEC_REG RV32DEC_REG_u(
        .clk       (clk       ),
        .rst_n     (rst_n     ),
        .instr_in  (instr_if_dec),
        .pc_in     (pc_if_dec   ),
        .en1       (en_ex     ), // from CU
        .en2       (en_mem    ), // from CU
        .setz_dec  (setz_dec  ), // from CU
        .waddr     (rd_addr   ),
        .wdata     (rd_data   ),
        .ocu       (ocu       ),
        //.en_out    (en_dec    ), // removed: CU provides en_dec
        .opcode_out(opcode_dec_ex),
        .rs1_out   (   rs1_dec_ex),
        .rs2_out   (   rs2_dec_ex),
        .rdaddr_out(rdaddr_dec_ex),
        .funct3_out(funct3_dec_ex),
        .funct7_out(funct7_dec_ex),
        .imm_out   (   imm_dec_ex),
        .pc_out    (    pc_dec_ex),
        .opcode_pre(opcode_pre_dec)
    );
    
    // EX
    RV32EX RV32EX_u(
        .clk       (clk       ),
        .rst_n     (rst_n     ),
        .opcode_in (opcode_dec_ex),
        .rs1_in    (   rs1_dec_ex),
        .rs2_in    (   rs2_dec_ex),
        .rdaddr_in (rdaddr_dec_ex),
        .funct3_in (funct3_dec_ex),
        .funct7_in (funct7_dec_ex),
        .imm_in    (   imm_dec_ex),
        .pc_in     (    pc_dec_ex),
        .en1       (en_mem    ), // CU-driven
        .en2       (en_wb     ), // CU-driven
        .ocu       (ocu       ),  // provide current decode ocu for conflict tests
        .setz_ex   (setz_ex),
        //.en_out    (en_ex     ), // original en_out removed (CU controls)
        .opcode_out(opcode_ex_mem),
        .rs1_out   (   rs1_ex_mem),
        .rs2_out   (   rs2_ex_mem),
        .rdaddr_out(rdaddr_ex_mem),
        .funct3_out(funct3_ex_mem),
        .funct7_out(funct7_ex_mem),
        .imm_out   (   imm_ex_mem),
        .pc_out    (    pc_ex_mem),
        .res_out   (   res_ex_mem),
        .taddr_out ( taddr_ex_mem),
        .branch_out(branch_ex_mem)
    );
    
    // MEM
    RV32MEM RV32MEM_u(
        .clk       (clk       ),
        .rst_n     (rst_n     ),
        .opcode_in (opcode_ex_mem),
        .rs1_in    (   rs1_ex_mem),
        .rs2_in    (   rs2_ex_mem),
        .rdaddr_in (rdaddr_ex_mem),
        .funct3_in (funct3_ex_mem),
        .funct7_in (funct7_ex_mem),
        .imm_in    (   imm_ex_mem),
        .pc_in     (    pc_ex_mem),
        .res_in    (   res_ex_mem),
        .taddr_in  ( taddr_ex_mem),
        .branch_in (branch_ex_mem),
        .en1       (en_wb     ), // CU-driven
        .ocu       (ocu       ),
        .setz_mem  (setz_mem  ),
        //.en_out    (en_mem    ), // removed: CU controls
        .opcode_out(opcode_mem_wb),
        .rs1_out   (   rs1_mem_wb),
        .rs2_out   (   rs2_mem_wb),
        .rdaddr_out(rdaddr_mem_wb),
        .funct3_out(funct3_mem_wb),
        .funct7_out(funct7_mem_wb),
        .imm_out   (   imm_mem_wb),
        .pc_out    (    pc_mem_wb),
        .res_out   (   res_mem_wb),
        .taddr_out ( taddr_mem_wb),
        .branch_out(branch_mem_wb),
        .Load      (bus_Load  ),
        .Store     (bus_Store ),
        .addr      (bus_addr  ),
        .data      (bus_data  ),
        .width     (bus_width ),
        .D_data    (bus_D_data)
    );
    
    BUS BUS_u(
        .clk   (clk   ),
        .rst_n (rst_n ),
        .Load  (bus_Load  ),
        .Store (bus_Store ),
        .addr  (bus_addr  ),
        .data  (bus_data  ),
        .width (bus_width ),
        .D_data(bus_D_data),
        .in    (in    ),
        .in_en (in_en ),
        .out   (out   ),
        .out_en(out_en)
    );
    
    RV32WB RV32WB_u(
        .clk      (clk      ),
        .rst_n    (rst_n    ), 
        .opcode_in(opcode_mem_wb),
        .rs1_in   (   rs1_mem_wb),
        .rs2_in   (   rs2_mem_wb),
        .rdaddr_in(rdaddr_mem_wb),
        .funct3_in(funct3_mem_wb),
        .funct7_in(funct7_mem_wb),
        .imm_in   (   imm_mem_wb),
        .pc_in    (    pc_mem_wb),
        .res_in   (   res_mem_wb),
        .taddr_in ( taddr_mem_wb),
        .branch_in(branch_mem_wb),
        .ocu      (ocu      ),
        //.en_out   (en_wb    ), // removed
        .rdaddr   (rd_addr  ),
        .rd       (rd_data  ),
        .jump     (pc_jump  ),
        .pc       (pc_data  )
    );
    
    // Instantiate Control Unit
    CU CU_u(
        .clk(clk),
        .rst_n(rst_n),
        .ocu_dec(ocu),
        .opcode_dec_pre(opcode_pre_dec),
        .opcode_dec_ex(opcode_dec_ex),
        .opcode_ex_mem(opcode_ex_mem),
        .opcode_mem_wb(opcode_mem_wb),
        .rdaddr_dec_ex(rdaddr_dec_ex),
        .rdaddr_ex_mem(rdaddr_ex_mem),
        .rdaddr_mem_wb(rdaddr_mem_wb),
        .branch_ex_mem(branch_ex_mem),
        .branch_mem_wb(branch_mem_wb),
        .en_wb(en_wb),
        .en_mem(en_mem),
        .en_ex(en_ex),
        .en_dec(en_dec),
        .setz_fetch(setz_fetch),
        .setz_dec(setz_dec),
        .setz_ex(setz_ex),
        .setz_mem(setz_mem)
    );
    
endmodule
