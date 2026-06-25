// tb.cpp — Comprehensive cache verification with Verilator
// Tests: cold miss, hit, store-hit, store-miss, byte/halfword masks,
//        eviction, multi-op queue, random stress with golden model.
#include "Vcache.h"
#include "verilated.h"
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <random>

static Vcache* dut;
static uint64_t sim_time = 0;
static uint8_t golden_mem[1 << 16];
static int npass = 0, nfail = 0;

static uint32_t rd_word(uint32_t a) {
    a &= ~3u;
    return (uint32_t)golden_mem[a] | ((uint32_t)golden_mem[a+1]<<8) |
           ((uint32_t)golden_mem[a+2]<<16) | ((uint32_t)golden_mem[a+3]<<24);
}
static void wr_word(uint32_t a, uint32_t d) {
    a &= ~3u; golden_mem[a]=d; golden_mem[a+1]=d>>8; golden_mem[a+2]=d>>16; golden_mem[a+3]=d>>24;
}
static void apply_store(uint32_t a, uint32_t d, uint8_t m) {
    uint32_t base = a & ~3u;
    uint32_t ofs = a & 3;
    uint32_t shifted = d << (ofs * 8);  // align data to word position
    for(int i=0;i<4;i++) if((m>>i)&1) golden_mem[base+i]=(shifted>>(i*8))&0xFF;
}

// ── Lower-level model ──
struct R { bool v; uint8_t id; uint32_t data; int lat; };
static R resps[64];
static int g_lat;

static void drive_resp() {
    dut->lower_submit_valid = 0;
    for(int i=0;i<64;i++) if(resps[i].v && resps[i].lat<=0){
        dut->lower_submit_valid=1; dut->lower_submit_id=resps[i].id;
        dut->lower_submit_data=resps[i].data; resps[i].v=false; break;
    }
    dut->lower_ls_valid = 1;
}
static void capture_lower() {
    if(dut->lower_valid) {
        if(dut->lower_ls) {
            uint32_t d=rd_word(dut->lower_addr);
            for(int i=0;i<64;i++) if(!resps[i].v){resps[i]={true,(uint8_t)dut->lower_id,d,g_lat};break;}
        } else apply_store(dut->lower_addr, dut->lower_data, dut->lower_mask);
    }
}
static void dec_lat() {
    for(int i=0;i<64;i++) if(resps[i].v) resps[i].lat--;
}

static void tick() {
    drive_resp();
    dut->clk=0; dut->eval();
    capture_lower();
    dut->clk=1; dut->eval();
    dec_lat();
    sim_time++;
}

static void reset() {
    dut->clk=0; dut->rst_n=0; dut->cpu_valid=0; dut->cpu_ls=0;
    dut->cpu_addr=0; dut->cpu_data=0; dut->cpu_id=0; dut->cpu_mask=0;
    dut->lower_ls_valid=1; dut->lower_submit_valid=0; dut->lower_submit_id=0;
    dut->lower_submit_data=0;
    memset(resps,0,sizeof(resps));
    for(int i=0;i<20;i++){dut->clk=0;dut->eval();dut->clk=1;dut->eval();}
    dut->rst_n=1; dut->clk=0; dut->eval();
}

static int op_ctr = 0;
static void send(bool load, uint32_t addr, uint32_t data, uint8_t mask, uint8_t id) {
    while(!dut->ls_valid){dut->cpu_valid=0;tick();}
    dut->cpu_valid=1; dut->cpu_ls=load; dut->cpu_addr=addr;
    dut->cpu_data=data; dut->cpu_id=id; dut->cpu_mask=mask;
    tick();
    dut->cpu_valid=0;
}

struct Sub { bool valid; uint8_t id; uint32_t data; };
static Sub wait_submit(int max_wait=10000) {
    for(int t=0;t<max_wait;t++){
        drive_resp();
        dut->clk=0; dut->eval();
        capture_lower();
        if(dut->submit_valid){
            Sub s={true,(uint8_t)dut->submit_id,dut->submit_data};
            dut->clk=1;dut->eval(); dec_lat(); sim_time++;
            return s;
        }
        dut->clk=1;dut->eval(); dec_lat(); sim_time++;
    }
    printf("TIMEOUT waiting for submit (sim_time=%lu)\n", (unsigned long)sim_time);
    return {false,0,0};
}

static void check(uint32_t got, uint32_t exp, const char* ctx) {
    if(got==exp){npass++; /*printf("  PASS %s: 0x%08x\n",ctx,got);*/}
    else{nfail++; printf("  FAIL %s: got 0x%08x exp 0x%08x\n",ctx,got,exp);}
}

// ── Directed tests ──
static void run_directed() {
    printf("=== Directed tests ===\n");

    // T1: cold miss + hit
    {memset(golden_mem,0,sizeof(golden_mem)); wr_word(0x1000,0xDEADBEEF);
     g_lat=2; reset();
     send(true,0x1000,0,0xF,0); Sub s=wait_submit(); check(s.data,0xDEADBEEF,"cold-miss");
     send(true,0x1000,0,0xF,0); s=wait_submit(); check(s.data,0xDEADBEEF,"hit");}

    // T2: two loads back-to-back
    {memset(golden_mem,0,sizeof(golden_mem)); wr_word(0x1400,0x11111111); wr_word(0x1404,0x22222222);
     g_lat=2; reset();
     send(true,0x1400,0,0xF,0); send(true,0x1404,0,0xF,1);
     Sub s=wait_submit(); check(s.data,0x11111111,"2load-A");
     s=wait_submit(); check(s.data,0x22222222,"2load-B");}

    // T3: store-miss then load
    {memset(golden_mem,0,sizeof(golden_mem)); g_lat=2; reset();
     send(false,0x1800,0xCAFEBABE,0xF,0); wait_submit();
     send(true,0x1800,0,0xF,0); Sub s=wait_submit(); check(s.data,0xCAFEBABE,"store-miss+load");}

    // T4: store+load same addr in queue simultaneously
    {memset(golden_mem,0,sizeof(golden_mem)); g_lat=3; reset();
     send(false,0x1C00,0x12345678,0xF,0); send(true,0x1C00,0,0xF,1);
     wait_submit(); Sub s=wait_submit(); check(s.data,0x12345678,"queue store+load");}

    // T5: three loads to different addrs
    {memset(golden_mem,0,sizeof(golden_mem));
     wr_word(0x2000,0xAAAAAAAA); wr_word(0x2400,0xBBBBBBBB); wr_word(0x2800,0xCCCCCCCC);
     g_lat=3; reset();
     send(true,0x2000,0,0xF,0); send(true,0x2400,0,0xF,1); send(true,0x2800,0,0xF,2);
     for(int i=0;i<3;i++){Sub s=wait_submit();
        check(s.data, i==0?0xAAAAAAAA : i==1?0xBBBBBBBB : 0xCCCCCCCC, "3load");}}

    // T6: byte store (byte 0)
    {memset(golden_mem,0,sizeof(golden_mem)); wr_word(0x3000,0x11223344);
     g_lat=2; reset();
     send(true,0x3000,0,0xF,0); wait_submit(); // cache it
     send(false,0x3000,0x000000AA,0x1,0); wait_submit(); // store byte 0
     send(true,0x3000,0,0xF,0); Sub s=wait_submit();
     check(s.data,0x112233AA,"byte-store-0");}

    // T7: byte store (byte 2)
    {memset(golden_mem,0,sizeof(golden_mem)); wr_word(0x3400,0x11223344);
     g_lat=2; reset();
     send(true,0x3400,0,0xF,0); wait_submit();
     send(false,0x3400,0x00BB0000,0x4,0); wait_submit(); // store byte 2
     send(true,0x3400,0,0xF,0); Sub s=wait_submit();
     check(s.data,0x11BB3344,"byte-store-2");}

    // T8: halfword store (lower)
    {memset(golden_mem,0,sizeof(golden_mem)); wr_word(0x3800,0x12345678);
     g_lat=2; reset();
     send(true,0x3800,0,0xF,0); wait_submit();
     send(false,0x3800,0x0000BEEF,0x3,0); wait_submit();
     send(true,0x3800,0,0xF,0); Sub s=wait_submit();
     check(s.data,0x1234BEEF,"half-store-lo");}

    // T9: halfword store (upper)
    {memset(golden_mem,0,sizeof(golden_mem)); wr_word(0x3C00,0x12345678);
     g_lat=2; reset();
     send(true,0x3C00,0,0xF,0); wait_submit();
     send(false,0x3C00,0xCAFE0000,0xC,0); wait_submit();
     send(true,0x3C00,0,0xF,0); Sub s=wait_submit();
     check(s.data,0xCAFE5678,"half-store-hi");}

    // T10: eviction (same index, different tag)
    {memset(golden_mem,0,sizeof(golden_mem));
     wr_word(0x4000,0xAAAAAAAA); wr_word(0x4400,0xBBBBBBBB); // same index, diff tag
     g_lat=2; reset();
     send(true,0x4000,0,0xF,0); wait_submit(); // cache A
     send(true,0x4400,0,0xF,0); wait_submit(); // evict A, cache B
     send(true,0x4000,0,0xF,0); Sub s=wait_submit(); check(s.data,0xAAAAAAAA,"evict-reload");}

    printf("  Directed: %d pass, %d fail\n\n", npass, nfail);
}

// ── Random stress test ──
static void run_random(int n_ops, int lat, unsigned seed) {
    int p0=npass, f0=nfail;
    printf("=== Random: %d ops, lat=%d, seed=%u ===\n", n_ops, lat, seed);
    // Use unique tag per invocation to avoid stale cache from previous run
    static int run_tag = 0x20;
    uint32_t base = run_tag << 10;
    run_tag += 2;
    memset(golden_mem,0,sizeof(golden_mem));
    for(int i=0;i<(int)sizeof(golden_mem);i++) golden_mem[i]=i&0xFF;
    g_lat=lat; reset();
    op_ctr=0;

    struct P { bool used, is_load; uint32_t addr; };
    P pend[32];
    memset(pend,0,sizeof(pend));

    std::mt19937 rng(seed);
    int sent=0, submitted=0;

    while(submitted < n_ops) {
        // Send if possible
        if(sent < n_ops && dut->ls_valid) {
                            uint32_t addr = (rng()%128)*4 + base;
            bool is_load = (rng()%10) < 7;  // 70% loads
            uint32_t data = rng();
            uint8_t mask;
            switch(rng()%4) {
                case 0: mask=0xF; break;
                case 1: mask=1<<(rng()%4); break;  // byte
                case 2: mask=3<<(rng()%2*2); break; // halfword
                default: mask=0xF; break;
            }
            int id = op_ctr % 31; op_ctr++;
            pend[id] = {true, is_load, addr};
            dut->cpu_valid=1; dut->cpu_ls=is_load; dut->cpu_addr=addr;
            dut->cpu_data=data; dut->cpu_id=id; dut->cpu_mask=mask;
            sent++;
        } else dut->cpu_valid=0;

        drive_resp();
        dut->clk=0; dut->eval();
        capture_lower();

        // Check submit
        if(dut->submit_valid) {
            uint8_t sid=dut->submit_id;
            if(sid<32 && pend[sid].used) {
                if(pend[sid].is_load) {
                    uint32_t exp=rd_word(pend[sid].addr);
                    check(dut->submit_data, exp, "rand-load");
                }
                pend[sid].used=false;
                submitted++;
            }
        }

        dut->clk=1; dut->eval(); dec_lat(); sim_time++;

        if(sim_time > (uint64_t)(n_ops)*2000) {
            printf("  TIMEOUT: sent=%d submitted=%d\n", sent, submitted); break;
        }
    }
    printf("  Random: %d pass, %d fail (%d submitted)\n\n",
           npass-p0, nfail-f0, submitted);
}

int main() {
    dut = new Vcache;
    printf("Cache Verification (Verilator)\n\n");

    run_directed();

    for(int lat=1; lat<=10; lat+=3) {
        run_random(2000, lat, 42+lat);
        run_random(2000, lat, 999+lat);
    }

    printf("═══════════════════════════\n");
    printf("  TOTAL: %d pass, %d fail\n", npass, nfail);
    printf("  %s\n", nfail==0?"ALL TESTS PASSED":"FAILURES DETECTED");
    printf("═══════════════════════════\n");

    delete dut;
    return nfail ? 1 : 0;
}
