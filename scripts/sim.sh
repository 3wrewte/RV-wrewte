#!/bin/bash
# scripts/sim.sh - Run RV32 CPU simulation with verification
# Usage: ./scripts/sim.sh [-v|--verbose]
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
TMP="$ROOT/tmp"

VERBOSE=0
if [ "${1:-}" = "-v" ] || [ "${1:-}" = "--verbose" ]; then
    VERBOSE=1
fi

source /opt/Xilinx/2025.1/Vivado/settings64.sh

TCLARGS=""
[ "$VERBOSE" = "1" ] && TCLARGS="-v"

if [ "$VERBOSE" = "1" ]; then
    vivado -mode batch \
        -source "$ROOT/scripts/run_sim.tcl" \
        -tclargs $TCLARGS \
        -nojournal -nolog
else
    vivado -mode batch \
        -source "$ROOT/scripts/run_sim.tcl" \
        -tclargs $TCLARGS \
        -nojournal -nolog > /dev/null 2>&1
fi

RC=$?
STATUS=$(cat "$TMP/status.txt" 2>/dev/null || echo "UNKNOWN")
RESULT=$(cat "$TMP/result.txt" 2>/dev/null || echo "(no output)")

echo "$STATUS: $RESULT"
exit $RC
