//FILE control_unit.v
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Control Unit (Centralized control for simple pipeline)
// - 收集各 stage 的 opcode / rdaddr / ocu / branch
// - 产生 en_wb, en_mem, en_ex, en_dec
// - 产生对应的 setz signals（用于 STEP_REG 的 flush）
// 简化：不实现 ROB/重命名等，仅把原先各模块的冲突判断与 branch gating 集中。
// 作者: ChatGPT (generated)
//////////////////////////////////////////////////////////////////////////////////

module CU(
    input             clk,
    input             rst_n,
    // decode-stage combinational signals (before DEC reg)
    input      [31:0] ocu_dec,       // one-hot of rs1/rs2 (bit0 cleared)
    input      [6:0]  opcode_dec_pre,// opcode of instruction currently in DEC (pre-STEP_REG)
    // pipeline opcodes (registered signals)
    input      [6:0]  opcode_dec_ex, // DEC->EX
    input      [6:0]  opcode_ex_mem, // EX->MEM
    input      [6:0]  opcode_mem_wb, // MEM->WB
    // pipeline rdaddr (registered)
    input      [4:0]  rdaddr_dec_ex, // rd in EX stage (from DEC->EX)
    input      [4:0]  rdaddr_ex_mem, // rd in MEM stage (from EX->MEM)
    input      [4:0]  rdaddr_mem_wb, // rd in WB stage (from MEM->WB)
    // outputs: enables for each stage (driven by CU)
    output reg        stall_FETCH_DEC,
    output reg        stall_DEC_EX   ,
    output reg        stall_EX_MEM   ,
    output reg        stall_MEM_WB   ,
    // outputs: setz (flush) for pipeline registers; used by STEP_REG inside modules
    output reg        flush_FETCH_DEC,
    output reg        flush_DEC_EX   ,
    output reg        flush_EX_MEM   ,
    output reg        flush_MEM_WB   ,   
    // output
    output reg        en_PC
    );
    reg en_dec;
    reg en_ex ;
    reg en_mem;
    reg en_wb ;
    
    // en_X  (1 = enabled)
    // stall_X (1 = stall)
    always @(*) begin
        stall_FETCH_DEC = ~en_ex  ;   // if dec not enabled => stall fetch->dec reg
        stall_DEC_EX    = ~en_mem ;
        stall_EX_MEM    = ~en_wb  ;
        stall_MEM_WB    = 1'b0    ;
    end
    
    always @(*) begin
        en_PC = en_dec;
    end

    // decode opcode flags (helper)
    function automatic [2:0] decode_flags;
        input [6:0] opc;
        reg jal, jalr, B;
        begin
            jal  = (opc == 7'b1101111);
            jalr = (opc == 7'b1100111);
            B    = (opc == 7'b1100011);
            decode_flags = {jal, jalr, B}; // bit2=jal, bit1=jalr, bit0=B
        end
    endfunction

    wire [2:0] f_dec_pre  = decode_flags(opcode_dec_pre);
    wire [2:0] f_dec_ex   = decode_flags(opcode_dec_ex);
    wire [2:0] f_ex_mem   = decode_flags(opcode_ex_mem);
    wire [2:0] f_mem_wb   = decode_flags(opcode_mem_wb);

    wire jal_dec_pre  = f_dec_pre[2];
    wire jalr_dec_pre = f_dec_pre[1];
    wire B_dec_pre    = f_dec_pre[0];

    wire jal_dec_ex  = f_dec_ex[2];
    wire jalr_dec_ex = f_dec_ex[1];
    wire B_dec_ex    = f_dec_ex[0];

    wire jal_ex_mem  = f_ex_mem[2];
    wire jalr_ex_mem = f_ex_mem[1];
    wire B_ex_mem    = f_ex_mem[0];

    wire jal_mem_wb  = f_mem_wb[2];
    wire jalr_mem_wb = f_mem_wb[1];
    wire B_mem_wb    = f_mem_wb[0];

    // conflict detection: check if ocu_dec has bit for a stage's rdaddr
    wire conflict_ex = |( ocu_dec & (32'h1 << rdaddr_dec_ex) );
    wire conflict_mem = |( ocu_dec & (32'h1 << rdaddr_ex_mem) );
    wire conflict_wb = |( ocu_dec & (32'h1 << rdaddr_mem_wb) );

    // compute enables in chain order: WB -> MEM -> EX -> DEC
    // conservative policy: a stage is enabled only if:
    //   - it is not a control-writing instruction (jal/jalr/B)
    //   - there is no conflict (i.e., its rd isn't needed by decode)
    //   - the next stage downstream is enabled
    // WB uses only its own branch/opcode to allow commit.
    always @(*) begin
        // default
        en_wb  = 1'b1;
        en_mem = 1'b1;
        en_ex  = 1'b1;
        en_dec = 1'b1;

        // WB gating by its own control (conservative)
        en_wb = !(jal_mem_wb | jalr_mem_wb | B_mem_wb) & (~conflict_wb);

        // MEM gated by its own control, conflict_wb, and en_wb
        en_mem = !(jal_ex_mem | jalr_ex_mem | B_ex_mem) & (~conflict_mem) & en_wb;

        // EX gated by its own control, conflict_mem, and en_mem
        en_ex = !(jal_dec_ex | jalr_dec_ex | B_dec_ex) & (~conflict_ex) & en_mem;

        // DEC (pre-STEP_REG) gated by its own control (use pre opcode) and en_ex
        en_dec = !(jal_dec_pre | jalr_dec_pre | B_dec_pre) & en_ex;
    end

    // setz (flush) signals: follow previous convention setz = en_next ^ en_current
    always @(*) begin
        flush_FETCH_DEC = en_ex ^ en_dec;   // FETCH STEP_REG used setz = en2 ^ en1 where en2=en_ex,en1=en_dec
        flush_DEC_EX    = en_mem ^ en_ex;   // DEC STEP_REG used setz = en2 ^ en1 where en2=en_mem,en1=en_ex
        flush_EX_MEM    = en_wb ^ en_mem;   // EX STEP_REG used setz = en2 ^ en1 where en2=en_wb,en1=en_mem
        flush_MEM_WB    = ~en_wb        ;
    end

endmodule
//ENDFILE control_unit.v