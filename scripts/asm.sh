#!/bin/bash
# scripts/asm.sh - Compile RV32I assembly to init_data.mem
# Usage: ./scripts/asm.sh [-v|--verbose]
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)

CROSS="${CROSS:-riscv32-linux-gnu-}"
AS="${CROSS}as"
LD="${CROSS}ld"
OBJCOPY="${CROSS}objcopy"
OBJDUMP="${CROSS}objdump"

SRC="$ROOT/src"
BLD="$ROOT/build"
TMP="$ROOT/tmp"

mkdir -p "$BLD" "$TMP"

"$AS" -march=rv32i -mabi=ilp32 "$SRC/a.s" -o "$BLD/a.o"
"$LD" -T "$ROOT/linker.ld" "$BLD/a.o" -o "$BLD/a.elf" 2>/dev/null
"$OBJCOPY" -O verilog "$BLD/a.elf" "$BLD/a.mem"
"$OBJDUMP" -d -M no-aliases "$BLD/a.elf" > "$BLD/a.lst"

cp "$BLD/a.mem" "$ROOT/RV-wrewte.srcs/sources_1/new/init_data.mem"
cp "$BLD/a.mem" "$TMP/init_data.mem"

echo "ASM OK: $BLD/a.mem ($(wc -l < "$BLD/a.mem") lines) -> init_data.mem"
