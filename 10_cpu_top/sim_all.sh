#!/bin/bash
# sim_all.sh - compile every .v source in the project, then run a testbench.
# Usage: ./sim_all.sh tb_top_cpu   (testbench name without .v)
cd "$(dirname "$0")" || exit 1
SRCS=$(find .. -name "*.v" ! -name "tb_*" ! -name "synth_*" | sort)
TB="$1.v"
if [ "$1" == "" ]; then echo "Usage: $0 <testbench_name>"; exit 1; fi
BIN="/tmp/$(basename "$TB" .v)_sim"
iverilog -g2012 -Wall -o "$BIN" "$TB" $SRCS || exit 1
vvp "$BIN"
