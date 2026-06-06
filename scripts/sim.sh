#!/bin/bash
# scripts/sim.sh - Run RV32 CPU simulation with verification
# Usage: ./scripts/sim.sh <test_name> [-v]
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)

TEST="${1:?Usage: $0 <test_name>}"
VERBOSE=0
[ "${2:-}" = "-v" ] || [ "${2:-}" = "--verbose" ] && VERBOSE=1

LOG="$ROOT/log"
TMP="$ROOT/tmp"
mkdir -p "$LOG" "$TMP"

source /opt/Xilinx/2025.1/Vivado/settings64.sh

if [ "$VERBOSE" = "1" ]; then
    vivado -mode batch \
        -source "$ROOT/scripts/run_sim.tcl" \
        -tclargs "$TEST" -v \
        -nojournal -nolog
else
    vivado -mode batch \
        -source "$ROOT/scripts/run_sim.tcl" \
        -tclargs "$TEST" \
        -nojournal -nolog > /dev/null 2>&1
fi

RC=$?
STATUS=$(cat "$TMP/status.txt" 2>/dev/null || echo "UNKNOWN")
RESULT=$(cat "$TMP/result.txt" 2>/dev/null || echo "(no output)")

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
cp "$TMP/xsim.log" "$LOG/${TEST}_${STATUS}_${TIMESTAMP}.log" 2>/dev/null || true

echo "$STATUS: $RESULT"
exit $RC
