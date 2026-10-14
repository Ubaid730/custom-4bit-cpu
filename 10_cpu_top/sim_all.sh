#!/bin/bash
# sim_all.sh - compile the CPU sources and run a testbench.
#
# Usage:  ./sim_all.sh <testbench_name> [extra .v files...]
#   e.g.  ./sim_all.sh tb_full_cpu test_program.v
#         ./sim_all.sh tb_top_cpu  program.v        (after assembling)
#
# The ROM image is NOT part of the default source list: each testbench picks
# its own instruction_memory module via the extra file argument, so there can
# never be duplicate-module collisions again.
cd "$(dirname "$0")" || exit 1

TB="$1.v"
if [ -z "$1" ]; then echo "Usage: $0 <testbench_name> [rom_image.v ...]"; exit 1; fi
shift

SRCS=$(find .. -name "*.v" ! -name "tb_*" ! -name "synth_*" \
       ! -name "test_program.v" ! -name "instruction_memory.v" | sort)

BIN="/tmp/$(basename "$TB" .v)_sim"
iverilog -g2012 -o "$BIN" "$TB" $SRCS "$@" || exit 1
vvp "$BIN"
