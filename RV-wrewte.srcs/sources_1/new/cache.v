`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/03/2026 02:21:15 PM
// Design Name: 
// Module Name: cache
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
`timescale 1ns / 1ps

// Assume realloc and LSB modules are defined elsewhere, as in your ROB code.
// realloc reorders the array starting from head.
// LSB is a priority encoder for the least set bit.

// Define the LS entry module
module ls_entry #(
    parameter LS_SIZE = 32,
    parameter LS_BITS = $clog2(LS_SIZE)
)(
(
    input clk,
    input rst_n,
    input alloc_ls,         // 1 for load, 0 for store
    input [31:0] alloc_addr,
    input [31:0] alloc_data, // for store
    input [LS_BITS-1:0] alloc_cpu_id,
    input [31:0] receive_data, // for load return or hit
    output reg ls,
    output reg [31:0] addr,
    output reg [31:0] data,
    output reg [ 3:0] mask,
    output reg [LS_BITS-1:0] cpu_id,
    output reg valid,
    input alloc,
    input issue,
    input receive,
    input submit,
    output reg issued,
    output reg received
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n || submit) begin
            ls <= 0;
            addr <= 0;
            data <= 0;
            cpu_id <= 0;
            valid <= 0;
        end else if (alloc) begin
            ls <= alloc_ls;
            addr <= alloc_addr;
            data <= alloc_data;
            cpu_id <= alloc_cpu_id;
            valid <= 1;
        end else begin
            ls <= ls;
            addr <= addr;
            data <= data;
            cpu_id <= cpu_id;
            valid <= valid;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n || submit) begin
            data <= 0;
        end else if (receive) begin
            data <= receive_data;
        end else begin
            data <= data;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n || submit || alloc) begin
            issued <= 0;
            received <= 0;
        end else if (issue) begin
            issued <= 1;
            received <= received; // may be set combinationaly elsewhere
        end else if (receive) begin
            issued <= 1;
            received <= 1;
        end else begin
            issued <= issued;
            received <= received;
        end
    end
endmodule

// ===========================================================
// L1 D-Cache with LS Queue
// ===========================================================
module cache #(
    parameter LS_SIZE = 32,
    parameter LS_BITS = $clog2(LS_SIZE),
    parameter CACHE_LINES = 256,
    parameter INDEX_BITS = $clog2(CACHE_LINES),
    parameter OFFSET_BITS = 2,
    parameter TAG_BITS = 32 - INDEX_BITS - OFFSET_BITS  // line size 4 bytes, offset 2 bits, assume aligned word access
)(
    input clk,
    input rst_n,

    // From CPU
    input               cpu_ls   ,           // 1 load, 0 store
    input [31:0]        cpu_addr ,
    input [31:0]        cpu_data ,
    input               cpu_valid,
    input [LS_BITS-1:0] cpu_id   ,
    input [3:0]         cpu_mask ,
    output              ls_valid ,        // alloc ready

    // To CPU
    output               submit_valid,
    output [LS_BITS-1:0] submit_id   ,
    output [31:0]        submit_data ,

    // To lower level
    output               lower_ls      ,
    output [31:0]        lower_addr    ,
    output [31:0]        lower_data    ,
    output               lower_valid   ,
    output [LS_BITS-1:0] lower_id      ,
    output [3:0]         lower_mask    ,
    input                lower_ls_valid,

    // From lower level
    input               lower_submit_valid,
    input [LS_BITS-1:0] lower_submit_id   ,
    input [31:0]        lower_submit_data
);

// ===========================================================
// Local storage
// ===========================================================
reg [LS_BITS-1:0] head;
reg [LS_BITS-1:0] tail;

// Allocate
wire alloc_ready;
assign ls_valid = alloc_ready;
wire [LS_BITS-1:0] space_left;
assign space_left = head - tail - 1;
assign alloc_ready = (space_left >= 1);
wire [LS_BITS-1:0] alloc_id;
wire alloc_do;
assign alloc_do = cpu_valid & alloc_ready;
assign alloc_id = alloc_do ? tail : '0;

// End Allocate

// Issue
wire          valid        [LS_SIZE-1:0];
wire          issued       [LS_SIZE-1:0];
wire          received     [LS_SIZE-1:0];
wire [32-1:0] addr         [LS_SIZE-1:0];

wire          valid_realloc    [LS_SIZE-1:0];
wire          issued_realloc   [LS_SIZE-1:0];
wire          received_realloc [LS_SIZE-1:0];
wire [32-1:0] addr_realloc     [LS_SIZE-1:0];

realloc #(.WIDTH(1) , .DEPTH(LS_SIZE)) realloc_valid   (.head(head),.in(valid   ),.out(valid_realloc   ));
realloc #(.WIDTH(1) , .DEPTH(LS_SIZE)) realloc_issued  (.head(head),.in(issued  ),.out(issued_realloc  ));
realloc #(.WIDTH(1) , .DEPTH(LS_SIZE)) realloc_received(.head(head),.in(received),.out(received_realloc));
realloc #(.WIDTH(32), .DEPTH(LS_SIZE)) realloc_addr    (.head(head),.in(addr    ),.out(addr_realloc    ));

reg [LS_SIZE-1:0] conflict_n;
generate
for(genvar i = 0; i < LS_SIZE; i++) begin
    conflict_n[i] = 1;
    for(integer j = 0; j < i; j++) begin
        conflict_n[i] = conflict_n[i] & (addr_realloc[i] != addr_realloc[j]);
    end
end
endgenerate 
//assign conflict_n = '1;  // No dependency check for now, assume no disambiguation

wire [LS_SIZE-1:0] ready;
generate
for(genvar i = 0; i < LS_SIZE; i++) begin
    assign ready[i] = conflict_n[i] & (!issued_realloc[i]) & valid_realloc[i];
end
endgenerate

wire issue_do;
wire [LS_BITS-1:0] issue_id_realloc;
LSB #(.WIDTH(LS_SIZE)) enc_issue(
    .in(ready),
    .out(issue_id_realloc)
);

wire [LS_BITS-1:0] issue_id;
assign issue_id = issue_id_realloc + head;

// Temp for issue logic
wire issue_ls = ls_arr[issue_id];
wire [31:0] issue_addr = addr_arr[issue_id];
wire [31:0] issue_data = data_arr[issue_id];
wire [ 3:0] issue_mask = mask_arr[issue_id];
wire [INDEX_BITS-1:0] issue_index = issue_addr[INDEX_BITS + 1 : 2];
wire [TAG_BITS-1:0] issue_tag = issue_addr[31 : INDEX_BITS + 2];
wire issue_hit = cache_valid[issue_index] && (cache_tag[issue_index] == issue_tag);
wire [31:0] issue_load_data = cache_data[issue_index];
wire need_lower = (!issue_ls) || (issue_ls && !issue_hit);
wire can_issue = !need_lower || lower_ls_valid;
assign issue_do = |avail && can_issue;

// End Issue

// Receive from lower
wire lower_receive_do;
wire [LS_BITS-1:0] lower_receive_id;
wire [31:0] lower_receive_data;
assign lower_receive_do = lower_submit_valid && ls_arr[lower_submit_id] && issued[lower_submit_id] && !received[lower_submit_id];
assign lower_receive_id = lower_submit_id;
assign lower_receive_data = lower_submit_data;

// Submit
wire submit_do = received[head] && valid[head];
wire [LS_BITS-1:0] submit_head = head;
assign submit_valid = submit_do;
assign submit_id = cpu_id_arr[submit_head];
assign submit_data = data_arr[submit_head];
// End Submit

// Cache storage
reg [31:0] cache_data [CACHE_LINES-1:0];
reg [TAG_BITS-1:0] cache_tag [CACHE_LINES-1:0];
reg cache_valid [CACHE_LINES-1:0];

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (integer i = 0; i < CACHE_LINES; i++) begin
            cache_valid[i] <= 0;
        end
    end
end

// Cache write/fill logic (synchronous)
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // reset already handled
    end else begin
        if (issue_do && !issue_ls && issue_hit) begin // Store: always write/allocate
            cache_valid[issue_index] <= 1;
            cache_tag[issue_index] <= issue_tag;
            cache_data[issue_index] <= issue_data;
        end
        if (lower_receive_do) begin // Load miss fill
            wire [INDEX_BITS-1:0] fill_index = addr_arr[lower_receive_id][INDEX_BITS + 1 : 2];
            wire [TAG_BITS-1:0] fill_tag = addr_arr[lower_receive_id][31 : INDEX_BITS + 2];
            cache_valid[fill_index] <= 1;
            cache_tag[fill_index] <= fill_tag;
            cache_data[fill_index] <= lower_receive_data;
        end
    end
end

// LS Queue Entries
reg [LS_SIZE-1:0] self_alloc;
reg [LS_SIZE-1:0] self_issue;
reg [LS_SIZE-1:0] self_receive;
reg [LS_SIZE-1:0] self_submit;
reg [31:0] receive_in_data [LS_SIZE-1:0];

// Alloc combin
always @(*) begin
    for (integer j = 0; j < LS_SIZE; j++) begin
        self_alloc[j] = 0;
    end
    if (alloc_do) begin
        self_alloc[alloc_id] = 1;
    end
end

// Issue combin
always @(*) begin
    for (integer j = 0; j < LS_SIZE; j++) begin
        self_issue[j] = 0;
    end
    if (issue_do) begin
        self_issue[issue_id] = 1;
    end
end

// Receive combin (from hit/store/lower)
always @(*) begin
    for (integer j = 0; j < LS_SIZE; j++) begin
        self_receive[j] = 0;
        receive_in_data[j] = 0;
    end
    if (issue_do && ((issue_ls && issue_hit) || !issue_ls)) begin
        self_receive[issue_id] = 1;
        if (issue_ls && issue_hit) begin
            receive_in_data[issue_id] = issue_load_data;
        end
    end
    if (lower_receive_do) begin
        self_receive[lower_receive_id] = 1;
        receive_in_data[lower_receive_id] = lower_receive_data;
    end
end

// Submit combin
always @(*) begin
    for (integer j = 0; j < LS_SIZE; j++) begin
        self_submit[j] = 0;
    end
    if (submit_do) begin
        self_submit[head] = 1;
    end
end

// Entry instances
reg ls_arr [LS_SIZE-1:0];
reg [31:0] addr_arr [LS_SIZE-1:0];
reg [31:0] data_arr [LS_SIZE-1:0];
reg [ 3:0] mask_arr [LS_SIZE-1:0];
reg [LS_BITS-1:0] cpu_id_arr [LS_SIZE-1:0];

generate
for (genvar i = 0; i < LS_SIZE; i++) begin
    ls_entry ls_entry_u (
        .clk(clk),
        .rst_n(rst_n),
        .alloc_ls(cpu_ls),
        .alloc_addr(cpu_addr),
        .alloc_data(cpu_data),
        .alloc_cpu_id(cpu_id),
        .receive_data(receive_in_data[i]),
        .ls(ls_arr[i]),
        .addr(addr_arr[i]),
        .data(data_arr[i]),
        .mask(mask_arr[i]),
        .cpu_id(cpu_id_arr[i]),
        .valid(valid[i]),
        .alloc(self_alloc[i]),
        .issue(self_issue[i]),
        .receive(self_receive[i]),
        .submit(self_submit[i]),
        .issued(issued[i]),
        .received(received[i])
    );
end
endgenerate

// Lower level output combin
assign lower_valid = issue_do && need_lower;
assign lower_ls    = lower_valid ? issue_ls                    : 0;
assign lower_addr  = lower_valid ? issue_addr                  : 0;
assign lower_data  = lower_valid ? (issue_ls ? 0 : issue_data) : 0;
assign lower_id    = lower_valid ? issue_id                    : 0;
assign lower_mask  = lower_valid ? issue_mask                  : 0;

// Queue control
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        head <= 0;
        tail <= 0;
    end else begin
        head <= head + submit_do;
        tail <= tail + alloc_do;
    end
end

endmodule