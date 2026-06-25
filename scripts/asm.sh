#!/bin/bash
# scripts/asm.sh - Compile RV32I assembly test to init_data.mem
# Usage: ./scripts/asm.sh <test_name> [-v]
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)

# Auto-detect RISC-V cross toolchain prefix
if [ -z "${CROSS:-}" ]; then
    for prefix in riscv32-linux-gnu- riscv64-elf- riscv64-linux-gnu-; do
        if command -v "${prefix}as" &>/dev/null; then
            CROSS="$prefix"
            break
        fi
    done
fi
CROSS="${CROSS:?no RISC-V toolchain found (tried riscv32-linux-gnu-, riscv64-elf-, riscv64-linux-gnu-)}"
AS="${CROSS}as"; LD="${CROSS}ld"; OBJCOPY="${CROSS}objcopy"; OBJDUMP="${CROSS}objdump"

TEST="${1:?Usage: $0 <test_name>}"
SRC_TEST="$ROOT/tests/$TEST"
BLD="$ROOT/build"
TMP="$ROOT/tmp"

[ -d "$SRC_TEST" ] || { echo "ERROR: test not found: tests/$TEST"; exit 1; }
[ -f "$SRC_TEST/test.s" ] || { echo "ERROR: no test.s in tests/$TEST"; exit 1; }

mkdir -p "$BLD" "$TMP"

# Detect linker emulation flag for 32-bit RISC-V
case "$CROSS" in
    riscv32-*) LDEMUL="" ;;
    *)         LDEMUL="-m elf32lriscv" ;;
esac

"$AS" -march=rv32i -mabi=ilp32 "$SRC_TEST/test.s" -o "$BLD/$TEST.o"
"$LD" $LDEMUL -T "$ROOT/linker.ld" "$BLD/$TEST.o" -o "$BLD/$TEST.elf" 2>/dev/null
"$OBJCOPY" -O verilog "$BLD/$TEST.elf" "$BLD/$TEST.mem"
"$OBJDUMP" -d -M no-aliases "$BLD/$TEST.elf" > "$BLD/$TEST.lst"

cp "$BLD/$TEST.mem" "$ROOT/RV-wrewte.srcs/sources_1/new/init_data.mem"
cp "$BLD/$TEST.mem" "$TMP/init_data.mem"

echo "ASM OK: tests/$TEST/test.s -> init_data.mem ($(wc -l < "$BLD/$TEST.mem") lines)"
