//rob.v
`timescale 1ns / 1ps
`include "PIPELINE_REG.v"

module rob_entry( 
    input clk  ,
    input rst_n,
    input pipe_t  alloc_in  ,
    input pipe_t  receive_in,
    //input pipe_t  issue_out ,
    //input pipe_t  submit_out,
    output pipe_t value     ,
    input         alloc     ,
    input         issue     ,
    input         receive   ,
    input         submit    ,
    output  reg   issued    ,
    output  reg   received
    );
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)begin
            value.opcode   <= '0;
            value.rs1_addr <= '0;
            value.rs2_addr <= '0;
            value.rd_addr  <= '0;
            value.funct3   <= '0;
            value.funct7   <= '0;
            value.imm      <= '0;
            value.pc       <= '0;
            value.valid    <= '0;
            value.pred_taken <= '0;
            value.pred_pc   <= '0;
        end else if (submit)begin
            value.opcode   <= '0;
            value.rs1_addr <= '0;
            value.rs2_addr <= '0;
            value.rd_addr  <= '0;
            value.funct3   <= '0;
            value.funct7   <= '0;
            value.imm      <= '0;
            value.pc       <= '0;
            value.valid    <= '0;
            value.pred_taken <= '0;
            value.pred_pc   <= '0;
        end else if (alloc)begin
            value.opcode   <= alloc_in.opcode  ;
            value.rs1_addr <= alloc_in.rs1_addr;
            value.rs2_addr <= alloc_in.rs2_addr;
            value.rd_addr  <= alloc_in.rd_addr ;
            value.funct3   <= alloc_in.funct3  ;
            value.funct7   <= alloc_in.funct7  ;
            value.imm      <= alloc_in.imm     ;
            value.pc       <= alloc_in.pc      ;
            value.valid    <= alloc_in.valid   ;
            value.pred_taken <= alloc_in.pred_taken;
            value.pred_pc   <= alloc_in.pred_pc;
        end else begin
            value.opcode   <= value.opcode  ;
            value.rs1_addr <= value.rs1_addr;
            value.rs2_addr <= value.rs2_addr;
            value.rd_addr  <= value.rd_addr ;
            value.funct3   <= value.funct3  ;
            value.funct7   <= value.funct7  ;
            value.imm      <= value.imm     ;
            value.pc       <= value.pc      ;
            value.valid    <= value.valid   ;
            value.pred_taken <= value.pred_taken;
            value.pred_pc   <= value.pred_pc;
        end
    end
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)begin
            value.result <= '0;
            value.taddr  <= '0;
            value.jump   <= '0;
        end else if (submit)begin
            value.result <= '0;
            value.taddr  <= '0;
            value.jump   <= '0;
        end else if (receive)begin
            value.result <= receive_in.result;
            value.taddr  <= receive_in.taddr ;
            value.jump   <= receive_in.jump  ;
        end else begin
            value.result <= value.result;
            value.taddr  <= value.taddr ;
            value.jump   <= value.jump  ;
        end
    end
    always_ff @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            value.rob_id   <= '0;
            value.instr    <= '0;
            value.rs1_data <= '0;
            value.rs2_data <= '0;
        end else if(submit)begin
            value.rob_id   <= '0;
            value.instr    <= '0;
            value.rs1_data <= '0;
            value.rs2_data <= '0;
        end else begin
            value.rob_id   <= value.rob_id;
            value.instr    <= value.instr;
            value.rs1_data <= value.rs1_data;
            value.rs2_data <= value.rs2_data;
        end
    end
    
    /*assign issue_out.opcode   = value.opcode  ;
    assign issue_out.rs1_addr = value.rs1_addr;
    assign issue_out.rs2_addr = value.rs2_addr;
    assign issue_out.rd_addr  = value.rd_addr ;
    assign issue_out.funct3   = value.funct3  ;
    assign issue_out.funct7   = value.funct7  ;
    assign issue_out.imm      = value.imm     ;
    assign issue_out.pc       = value.pc      ;
    assign issue_out.valid    = value.valid   ;
    assign issue_out.result   = '0;
    assign issue_out.taddr    = '0;
    assign issue_out.jump     = '0;
    assign issue_out.rob_id   = '0;
    assign issue_out.instr    = '0;
    assign issue_out.rs1_data = '0;
    assign issue_out.rs2_data = '0;
    
    assign submit_out.rd_addr  = value.rd_addr ;
    assign submit_out.result   = value.result  ;
    assign submit_out.taddr    = value.taddr   ;
    assign submit_out.jump     = value.jump    ;
    assign submit_out.opcode   = value.opcode  ;
    assign submit_out.rs1_addr = '0;
    assign submit_out.rs2_addr = '0;
    assign submit_out.funct3   = '0;
    assign submit_out.funct7   = '0;
    assign submit_out.imm      = '0;
    assign submit_out.pc       = '0;
    assign submit_out.valid    = '0;
    assign submit_out.rob_id   = '0;
    assign submit_out.instr    = '0;
    assign submit_out.rs1_data = '0;
    assign submit_out.rs2_data = '0;*/
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)begin
            issued   <= '0;
            received <= '0;
        end else if (submit | alloc)begin
            issued   <= '0;
            received <= '0;
        end else if(issue)begin
            issued   <= '1;
            received <= '0;
        end else if(receive)begin
            issued   <= '1;
            received <= '1;
        end
    end
endmodule


// ===========================================================
// Reorder Buffer
// ===========================================================
module rob #(
    parameter ROB_SIZE = 32,
    parameter ROB_BITS = $clog2(ROB_SIZE),
    parameter ENTRY = 1,
    parameter ENTRY_BITS = $clog2(ENTRY),
    parameter ISSUE_LSU = 1,
    parameter ISSUE_ALU = 1,
    parameter ISSUE_BRU = 1,
    parameter SUBMIT = 1,
    parameter SUBMIT_BITS = $clog2(SUBMIT),
    parameter WINDOW = 6,
    parameter ISSUE_WINDOW = WINDOW > ROB_SIZE? WINDOW : ROB_SIZE,
    parameter ISSUE_WINDOW_BITS = $clog2(ISSUE_WINDOW)
)(
    input                      clk,
    input                      rst_n,

    // ---------- allocate from DEC ----------
    input  pipe_t              alloc_in[ENTRY-1:0],
    output                     rob_alloc_ready,

    // ---------- issue (to backend) ----------
    output pipe_t              issue_out[ISSUE_LSU + ISSUE_ALU + ISSUE_BRU - 1:0],

    // ---------- writeback ----------
    input  pipe_t              receive_in[ISSUE_LSU + ISSUE_ALU + ISSUE_BRU - 1:0],

    // ---------- BRU mispredict input ----------
    input                      br_mispredict,
    input  [31:0]              br_mispredict_rob_id,
    input  [31:0]              br_mispredict_target,

    // ---------- LSU backpressure ----------
    input                      lsu_ready,       // 0 = LSU lane stalled (cache busy)

    // ---------- flush output ----------
    output reg                 rob_flush,
    output reg [31:0]          rob_new_pc
);

localparam ISSUE = ISSUE_LSU + ISSUE_ALU + ISSUE_BRU;
localparam ISSUE_BITS = $clog2(ISSUE);
localparam IDX_LSU = 0;
localparam IDX_ALU = ISSUE_LSU;
localparam IDX_BRU = ISSUE_LSU + ISSUE_ALU;

// ===========================================================
// Local storage
// ===========================================================
reg [ROB_BITS-1:0] head;
reg [ROB_BITS-1:0] tail;

// Allocate
reg [ROB_BITS:0] rob_count;
wire alloc_ready = (rob_count + ENTRY <= ROB_SIZE);
assign rob_alloc_ready = alloc_ready;
wire [ROB_BITS-1:0]   alloc_id[ENTRY-1:0];
wire                  alloc_do[ENTRY-1:0];
wire [ROB_BITS-1:0] alloc_amount;

generate
wire [ROB_BITS-1:0] alloc_amount_cnt[ENTRY:0];
assign alloc_amount_cnt[0] = '0;
for(genvar i = 0; i < ENTRY; i++)begin
    assign alloc_do[i] = (alloc_in[i].valid & alloc_ready);
    assign alloc_id[i] = alloc_do[i]? tail + i : '0;
    assign alloc_amount_cnt[i+1] = alloc_amount_cnt[i] + alloc_do[i];
end
assign alloc_amount = alloc_amount_cnt[ENTRY];
endgenerate
// End Allocate

// Issue
wire [ 5-1:0] rs1   [ROB_SIZE-1:0];
wire [ 5-1:0] rs2   [ROB_SIZE-1:0];
wire [ 5-1:0] rd    [ROB_SIZE-1:0];
wire          valid [ROB_SIZE-1:0];
wire          issued[ROB_SIZE-1:0];
wire [ 7-1:0] opcode[ROB_SIZE-1:0];

wire [ 5-1:0] rs1_realloc   [ROB_SIZE-1:0];
wire [ 5-1:0] rs2_realloc   [ROB_SIZE-1:0];
wire [ 5-1:0] rd_realloc    [ROB_SIZE-1:0];
wire          valid_realloc [ROB_SIZE-1:0];
wire          issued_realloc[ROB_SIZE-1:0];
wire [ 7-1:0] opcode_realloc[ROB_SIZE-1:0];

realloc#(.WIDTH(5),.DEPTH(ROB_SIZE)) realloc_rs1(
    .head(head)     ,
    .in(rs1)         ,
    .out(rs1_realloc)
);
realloc#(.WIDTH(5),.DEPTH(ROB_SIZE)) realloc_rs2(
    .head(head)     ,
    .in(rs2)         ,
    .out(rs2_realloc)
);
realloc#(.WIDTH(5),.DEPTH(ROB_SIZE)) realloc_rd(
    .head(head)     ,
    .in(rd)         ,
    .out(rd_realloc)
);
realloc#(.WIDTH(1),.DEPTH(ROB_SIZE)) realloc_valid(
    .head(head)     ,
    .in(valid)         ,
    .out(valid_realloc)
);
realloc#(.WIDTH(1),.DEPTH(ROB_SIZE)) realloc_issued(
    .head(head)     ,
    .in(issued)         ,
    .out(issued_realloc)
);
realloc#(.WIDTH(7),.DEPTH(ROB_SIZE)) realloc_opcode(
    .head(head)     ,
    .in(opcode)         ,
    .out(opcode_realloc)
);

wire [32-1:0] rs_one_hot [ISSUE_WINDOW-1:0];
wire [32-1:0] rd_one_hot [ISSUE_WINDOW-1:0];
wire [32-1:0] occupied   [ISSUE_WINDOW-1:0];
wire [ISSUE_WINDOW-1:0] conflict_n;
wire [ISSUE_WINDOW-1:0] branched;
wire [ISSUE_WINDOW-1:0] is_lsu;
wire [ISSUE_WINDOW-1:0] is_branch;
wire [ISSUE_WINDOW-1:0] ready;
generate
for(genvar i = 0; i < ISSUE_WINDOW; i++) begin
    assign rs_one_hot[i] = (1 << rs1_realloc[i]) | (1 << rs2_realloc[i]);
    assign rd_one_hot[i] = (1 << rd_realloc[i]) & (~32'b1);
    assign is_lsu[i]    = (opcode_realloc[i] == 7'b0000011) || (opcode_realloc[i] == 7'b0100011);
    assign is_branch[i] = (opcode_realloc[i] == 7'b1100011) || (opcode_realloc[i] == 7'b1101111) || (opcode_realloc[i] == 7'b1100111);
end
endgenerate
assign occupied[0] = rd_one_hot[0];
assign conflict_n[0] = '1;
generate
for(genvar i = 1; i < ISSUE_WINDOW; i++) begin
    assign occupied[i] = occupied[i-1] | rd_one_hot[i];
    assign conflict_n[i] = ~(|(occupied[i-1] & rs_one_hot[i]));
end
endgenerate
assign branched[0] = '0;
generate
for(genvar i = 1; i < ISSUE_WINDOW; i++) begin
    assign branched[i] = branched[i-1] | is_branch[i-1];
end
endgenerate

generate
for(genvar i = 0; i < ISSUE_WINDOW; i++) begin
    assign ready[i] = conflict_n[i] & (!issued_realloc[i]) & valid_realloc[i] & !(is_lsu[i] & branched[i]);
end
endgenerate

//-----------------------------------------------------------------------
// Issue: independent pools — strict separation by opcode type
// LSU pool: ready & is_lsu        (load/store only)
// BRU pool: ready & is_branch     (branch/jal/jalr only)
// ALU pool: ready & ~is_lsu & ~is_branch  (U/I/R type only)
//-----------------------------------------------------------------------
wire [ISSUE-1:0] issue_do;
wire [ISSUE_WINDOW_BITS-1:0] issue_id_realloc [ISSUE-1:0];

generate
for (genvar k = 0; k < ISSUE; k++) begin : gen_issue
    wire [ISSUE_WINDOW-1:0] pool;
    if (k == IDX_LSU)
        assign pool = ready & is_lsu & {ISSUE_WINDOW{lsu_ready}};
    else if (k == IDX_BRU)
        assign pool = ready & is_branch;
    else
        assign pool = ready & ~is_lsu & ~is_branch;

    wire [ISSUE_WINDOW_BITS-1:0] id;
    LSB#(.WIDTH(ISSUE_WINDOW_BITS)) enc(.in(pool), .out(id));
    assign issue_do[k] = |pool;
    assign issue_id_realloc[k] = id;
end
endgenerate

wire [ROB_BITS-1:0] issue_id[ISSUE-1:0];
generate
for(genvar k = 0; k < ISSUE; k++) begin
    assign issue_id[k] = {{(ROB_BITS - ISSUE_WINDOW_BITS){1'b0}}, issue_id_realloc[k]} + head;
end
endgenerate
// End Issue

// Recieve
wire[ISSUE-1:0] receive_do;
wire [ROB_BITS-1:0] receive_id[ISSUE-1:0];
generate
for(genvar k = 0; k < ISSUE; k++) begin
    assign receive_do[k] = receive_in[k].valid ;
    assign receive_id[k] = receive_in[k].rob_id;
end
endgenerate
// End Recieve

 // Submit
 wire [ROB_SIZE-1:0] received    ;
 wire submit_do = received[head];
 //End Submit

wire partial_flush = br_mispredict;
wire [ROB_BITS-1:0] submit_id = submit_do ? head : '0;

// Registers
wire [ 5-1:0] rs1_addr[ISSUE-1:0];
wire [ 5-1:0] rs2_addr[ISSUE-1:0];
wire [32-1:0] rs1_data[ISSUE-1:0];
wire [32-1:0] rs2_data[ISSUE-1:0];
wire [ 5-1:0] rd_addr [SUBMIT-1:0];
wire [32-1:0] rd_data [SUBMIT-1:0];

registers32#(                
        .depth(5)   ,
        .read_channel(ISSUE),
        .write_channel(SUBMIT)         
    ) registers32_u(         
        .clk   (clk   ),     
        .rst_n (rst_n ),     
        .r1addr(rs1_addr),     
        .r2addr(rs2_addr),     
        .waddr (rd_addr ),     
        .rdata1(rs1_data),     
        .rdata2(rs2_data),     
        .wdata (rd_data )      
    );                       

// End Registers

// ROB Entries
pipe_t rob_stored_value  [ROB_SIZE-1:0];

pipe_t submit_chosen;
assign submit_chosen = submit_do ? rob_stored_value[submit_id] : '0;
wire commit_jump = submit_do && submit_chosen.jump;

assign rob_flush  = partial_flush;
assign rob_new_pc = partial_flush ? br_mispredict_target : '0;

pipe_t rob_alloc   [ROB_SIZE-1:0];
pipe_t rob_receive [ROB_SIZE-1:0];
reg[ROB_SIZE-1:0] self_alloc  ;
reg[ROB_SIZE-1:0] self_issue  ;
reg[ROB_SIZE-1:0] self_receive;
reg[ROB_SIZE-1:0] self_submit ;
always @(*)begin
    for(integer j = 0; j < ROB_SIZE; j++)begin
         self_alloc[j] = 0;
         rob_alloc[j] = 0;
    end
    for(integer j = 0; j < ENTRY; j++)begin
         self_alloc[alloc_id[j]] = alloc_do[j]? 1'b1 :       self_alloc[alloc_id[j]];
         rob_alloc[alloc_id[j]]  = alloc_do[j]?alloc_in[j] : rob_alloc[alloc_id[j]] ;
    end
end
always @(*)begin
    /*if(issue_do) begin
        self_issue <= 1 << issue_id;
    end else begin
        self_issue <= 0;
    end*/
    
    for(integer j = 0; j < ROB_SIZE; j++)begin
         self_issue[j] = 0;
    end 
    for(integer j = 0; j < ISSUE; j++)begin
         self_issue[issue_id[j]] = issue_do[j]? 1'b1 : self_issue[issue_id[j]];
    end
end
always @(*)begin
    /*if(receive_do) begin
        self_receive <= 1 << receive_id;
    end else begin
        self_receive <= 0;*/
        
    for(integer j = 0; j < ROB_SIZE; j++)begin
         self_receive[j] = 0;
         rob_receive[j] = 0;
    end
    for(integer j = 0; j < ISSUE; j++)begin
         self_receive[receive_id[j]] = receive_do[j]? 1'b1 : self_receive[receive_id[j]];
         rob_receive[receive_id[j]] =  receive_do[j]? receive_in[j] : rob_receive[receive_id[j]];
    end
end

always @(*)begin
    if(partial_flush)begin
        self_submit = '0;
        for (integer j = 0; j < ROB_SIZE; j = j + 1) begin
            if (br_mispredict_rob_id < tail) begin
                if (j > br_mispredict_rob_id && j < tail)
                    self_submit[j] = 1;
            end else begin
                if (j > br_mispredict_rob_id || j < tail)
                    self_submit[j] = 1;
            end
        end
    end else if(submit_do) begin
        self_submit = 1 << submit_id;
    end else begin
        self_submit = 0;
    end
end

generate
for(genvar i = 0; i < ROB_SIZE; i++)begin
    //assign self_issue  [i]   = issue_do && (issue_id == i);
    //assign self_receive[i]   = receive_do && (receive_id == i);
    //assign self_submit [i]   = (submit_do && (submit_id == i)) || rob_flush;
    //assign rob_receive[i] = (self_receive)? receive_in : '0;
    rob_entry rob_entry_u( 
        .clk       (clk                ),
        .rst_n     (rst_n              ),
        .alloc_in  (rob_alloc[i]       ),
        .receive_in(rob_receive[i]     ),
        .value     (rob_stored_value[i]),
        .alloc     (self_alloc      [i]),
        .issue     (self_issue      [i]),
        .receive   (self_receive    [i]),
        .submit    (self_submit     [i]),
        .issued    (issued[i]          ),
        .received  (received[i]        )
    );
    assign rs1  [i] = rob_stored_value[i].rs1_addr  ; 
    assign rs2  [i] = rob_stored_value[i].rs2_addr  ;
    assign rd   [i] = rob_stored_value[i].rd_addr   ;
    assign valid[i] = rob_stored_value[i].valid     ;
    assign opcode[i] = rob_stored_value[i].opcode   ;
end
endgenerate
pipe_t issue_chosen [ISSUE-1:0];
generate
for(genvar k = 0; k < ISSUE; k++) begin
    assign issue_chosen[k]  = issue_do[k]? rob_stored_value[issue_id[k]] : '0;
    assign rs1_addr[k] = issue_do[k]?issue_chosen[k].rs1_addr : '0;
    assign rs2_addr[k] = issue_do[k]?issue_chosen[k].rs2_addr : '0;
    assign issue_out[k].rob_id    = issue_do[k]?issue_id[k] : '0;
    assign issue_out[k].instr     = 32'b0;
    assign issue_out[k].pc        = issue_do[k]?issue_chosen[k].pc : '0;
    assign issue_out[k].imm       = issue_do[k]?issue_chosen[k].imm : '0;
    assign issue_out[k].rs1_data  = rs1_data[k];
    assign issue_out[k].rs2_data  = rs2_data[k];
    assign issue_out[k].rs1_addr  = 5'b0;
    assign issue_out[k].rs2_addr  = 5'b0;
    assign issue_out[k].rd_addr   = 5'b0;
    assign issue_out[k].opcode    = issue_do[k]?issue_chosen[k].opcode : '0;
    assign issue_out[k].funct3    = issue_do[k]?issue_chosen[k].funct3 : '0;
    assign issue_out[k].funct7    = issue_do[k]?issue_chosen[k].funct7 : '0;
    assign issue_out[k].result    = 32'b0;
    assign issue_out[k].taddr     = 32'b0;
    assign issue_out[k].jump      = 1'b0;
    assign issue_out[k].valid     = issue_do[k];
    assign issue_out[k].pred_taken = issue_do[k] ? issue_chosen[k].pred_taken : 1'b0;
    assign issue_out[k].pred_pc   = issue_do[k] ? issue_chosen[k].pred_pc   : 32'b0;
end
endgenerate



assign rd_addr[0]  = submit_do ? submit_chosen.rd_addr : '0;
assign rd_data[0]  = submit_do ? submit_chosen.result  : '0;



// End ROB Entries            

// Queue Ctl
always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            head <= '0;
            tail <= '0;
            rob_count <= '0;
        end else if (partial_flush) begin
            tail <= br_mispredict_rob_id + 1;
            rob_count <= (br_mispredict_rob_id + 1) - head;
        end else begin
            head <= head + submit_do; 
            tail <= tail + alloc_amount;
            rob_count <= rob_count + alloc_amount - submit_do;
        end
    end
// End Queue Ctl

endmodule
//end rob.v