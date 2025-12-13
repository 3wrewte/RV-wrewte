//rob.v
`timescale 1ns / 1ps
`include "PIPELINE_REG.v"

module rob_entry( 
    input clk  ,
    input rst_n,
    input pipe_t  alloc_in  ,
    input pipe_t  recieve_in,
    input pipe_t  issue_out ,
    input pipe_t  submit_out,
    input         alloc     ,
    input         issue     ,
    input         recieve   ,
    input         submit    ,
    output  reg   issued    ,
    output  reg   recieved
    );
    pipe_t value;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n | submit)begin
            value.opcode   <= '0;
            value.rs1_addr <= '0;
            value.rs2_addr <= '0;
            value.rd_addr  <= '0;
            value.funct3   <= '0;
            value.funct7   <= '0;
            value.imm      <= '0;
            value.pc       <= '0;
            value.valid    <= '0;
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
        end
    end
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n | submit)begin
            value.result <= '0;
            value.taddr  <= '0;
            value.jump   <= '0;
        end else if (recieve)begin
            value.result <= recieve_in.result;
            value.taddr  <= recieve_in.taddr ;
            value.jump   <= recieve_in.jump  ;
        end else begin
            value.result <= value.result;
            value.taddr  <= value.taddr ;
            value.jump   <= value.jump  ;
        end
    end
    always_ff @(posedge clk or negedge rst_n)begin
        value.rob_id   <= '0;
        value.instr    <= '0;
        value.rs1_data <= '0;
        value.rs2_data <= '0;
    end
    
    assign issue_out.opcode   = value.opcode  ;
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
    assign submit_out.rs2_data = '0;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n | submit | alloc)begin
            issued   <= '0;
            recieved <= '0;
        end else if(issue)begin
            issued   <= '1;
            recieved <= '0;
        end else if(recieve)begin
            issued   <= '1;
            recieved <= '1;
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
    parameter ENTRY_BITS = $clog2(ENTRY)
)(
    input                      clk,
    input                      rst_n,

    // ---------- allocate from DEC ----------
    input  pipe_t              alloc_in[ENTRY-1:0],
    //input  pipe_t              alloc1,
    output                     rob_alloc_ready,

    // ---------- issue (to backend) ----------
    output pipe_t              issue_out,
    //output reg                 issue_found,

    // ---------- writeback ----------
    input  pipe_t              recieve_in,

    // ---------- commit ----------

    // ---------- flush output ----------
    output reg                 rob_flush,
    output reg [31:0]          rob_new_pc
);

// ===========================================================
// Local storage
// ===========================================================
reg [ROB_BITS-1:0] head;
reg [ROB_BITS-1:0] tail;

// Allocate
wire alloc_ready;
assign rob_alloc_ready = alloc_ready;
wire [ROB_BITS-1:0] space_left;
//assign space_left = {head - tail}[ROB_BITS-1:0];
assign space_left = head - tail - 1;
assign alloc_ready = (space_left >= ENTRY);
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

wire [ 5-1:0] rs1_realloc   [ROB_SIZE-1:0];
wire [ 5-1:0] rs2_realloc   [ROB_SIZE-1:0];
wire [ 5-1:0] rd_realloc    [ROB_SIZE-1:0];
wire          valid_realloc [ROB_SIZE-1:0];
wire          issued_realloc[ROB_SIZE-1:0];

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

wire [32-1:0] rs_one_hot    [ROB_SIZE-1:0];
wire [32-1:0] rd_one_hot    [ROB_SIZE-1:0];

wire [32-1:0] occupied      [ROB_SIZE-1:0];
wire [ROB_SIZE-1:0]         conflict_n    ;
wire [ROB_SIZE-1:0]         found         ;
wire [ROB_SIZE-1:0]         issue_able    ;
generate
for(genvar i = 0; i < ROB_SIZE; i++)begin
    assign rs_one_hot[i] = (1 << rs1_realloc[i]) | (1 << rs2_realloc[i]);
    assign rd_one_hot[i] = (1 << rd_realloc[i]) & (~32'b1);
end
endgenerate

assign occupied[0] = rd_one_hot[0];
assign conflict_n[0] = '1;
assign issue_able[0] = (conflict_n[0] & (!issued_realloc[0]) & valid_realloc[0]);
assign found[0] =  issue_able[0];

generate
for(genvar i = 1; i < ROB_SIZE; i++)begin
    assign occupied[i] = occupied[i-1] | rd_one_hot[i];
    assign conflict_n[i] = ~(|(occupied[i-1] & rs_one_hot[i]));
    assign issue_able[i] = ((!found[i-1]) & conflict_n[i] & (!issued_realloc[i]) & valid_realloc[i]);
    assign found[i] =  issue_able[i] | found[i-1];
end
endgenerate
wire issue_do = |(issue_able);
wire [ROB_BITS-1:0] issue_id_realloc;
ENC#(.WIDTH(ROB_BITS)) enc_issue(
    .in(issue_able),
    .out(issue_id_realloc)
);
wire [ROB_BITS-1:0] issue_id = issue_id_realloc + head;
// End Issue

// Recieve
wire recieve_do;
wire [ROB_BITS-1:0] recieve_id;
assign recieve_do = recieve_in.valid ;
assign recieve_id = recieve_in.rob_id;
// End Recieve

// Submit
wire [ROB_SIZE-1:0] recieved    ;
wire submit_do = recieved[head];
wire [ROB_BITS-1:0] submit_id = submit_do? head : '0;
//End Submit

// Registers
wire [ 5-1:0] rs1_addr;
wire [ 5-1:0] rs2_addr;
wire [32-1:0] rs1_data;
wire [32-1:0] rs2_data;
wire [ 5-1:0] rd_addr ;
wire [32-1:0] rd_data ;

registers32#(                
        .depth(5)            
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
pipe_t rob_issue   [ROB_SIZE-1:0];
pipe_t rob_submit  [ROB_SIZE-1:0];
pipe_t rob_alloc   [ROB_SIZE-1:0];
pipe_t rob_recieve [ROB_SIZE-1:0];
generate
for(genvar i = 0; i < ROB_SIZE; i++)begin
    wire self_alloc     = alloc_do[0] && (alloc_id[0] == i);
    wire self_issue     = issue_do && (issue_id == i);
    wire self_recieve   = recieve_do && (recieve_id == i);
    wire self_submit    = (submit_do && (submit_id == i)) || rob_flush;
    assign rob_alloc[i]   = (self_alloc)? alloc_in[0] : '0;
    assign rob_recieve[i] = (self_recieve)? recieve_in : '0;
    rob_entry rob_entry_u( 
        .clk       (clk           ),
        .rst_n     (rst_n         ),
        .alloc_in  (rob_alloc[i]  ),
        .recieve_in(rob_recieve[i]),
        .issue_out (rob_issue[i]  ),
        .submit_out(rob_submit[i] ),
        .alloc     (self_alloc    ),
        .issue     (self_issue    ),
        .recieve   (self_recieve  ),
        .submit    (self_submit   ),
        .issued    (issued[i]     ),
        .recieved  (recieved[i]   )
    );
    assign rs1  [i] = rob_issue[i].rs1_addr  ; 
    assign rs2  [i] = rob_issue[i].rs2_addr  ;
    assign rd   [i] = rob_issue[i].rd_addr   ;
    assign valid[i] = rob_issue[i].valid     ;
end
endgenerate
pipe_t issue_chosen ;
pipe_t submit_chosen;
assign issue_chosen  = issue_do? rob_issue[issue_id] : '0;
assign submit_chosen = submit_do? rob_submit[submit_id] : '0;
assign rob_flush = submit_do?submit_chosen.jump : '0;
assign rob_new_pc = submit_do?submit_chosen.taddr : '0;

assign rs1_addr = issue_do?issue_chosen.rs1_addr : '0;
assign rs2_addr = issue_do?issue_chosen.rs2_addr : '0;
assign rd_addr  = issue_do?submit_chosen.rd_addr : '0;
assign rd_data  = issue_do?submit_chosen.result  : '0;

assign issue_out.rob_id    = issue_id;
assign issue_out.instr     = 32'b0;
assign issue_out.pc        = issue_do?issue_chosen.pc : '0;
assign issue_out.imm       = issue_do?issue_chosen.imm : '0;
assign issue_out.rs1_data  = rs1_data;
assign issue_out.rs2_data  = rs2_data;
assign issue_out.rs1_addr  = 5'b0;
assign issue_out.rs2_addr  = 5'b0;
assign issue_out.rd_addr   = 5'b0;
assign issue_out.opcode    = issue_do?issue_chosen.opcode : '0;
assign issue_out.funct3    = issue_do?issue_chosen.funct3 : '0;
assign issue_out.funct7    = issue_do?issue_chosen.funct7 : '0;
assign issue_out.result    = 32'b0;
assign issue_out.taddr     = 32'b0;
assign issue_out.jump      = 1'b0;
assign issue_out.valid     = issue_do;

// End ROB Entries            

// Queue Ctl
always @(posedge clk or negedge rst_n) begin
        if (!rst_n | rob_flush)begin
            head <= '0;
            tail <= '0;
        end else begin
            //head <= {head + alloc_amount}[ROB_BITS-1:0];
            //tail <= {tail + submit_do}[ROB_BITS-1:0];
            head <= head + submit_do; 
            tail <= tail + alloc_amount;    
        end
    end
// End Queue Ctl

endmodule
//end rob.v