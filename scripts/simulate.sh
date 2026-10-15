#!/bin/bash
# simulate.sh - compile RTL + a testbench and run it with Icarus Verilog.
#
# Usage:
#   ./scripts/simulate.sh <testbench_name> [rom_image.v ...]
# Examples:
#   ./scripts/simulate.sh tb_full_cpu roms/test_program.v
#   ./scripts/simulate.sh tb_top_cpu  build/program.v
#
# The default ROM (rtl/instruction_memory.v) is excluded automatically; pass a
# generated/hand-assembled ROM image as an extra argument to override it.
cd "$(dirname "$0")/.." || exit 1
mkdir -p build

TB="tests/$1.v"
if [ -z "$1" ] || [ ! -f "$TB" ]; then
    echo "Usage: $0 <testbench_name> [rom_image.v ...]"
    echo "Available testbenches:"; ls tests | sed 's/^/  /'
    exit 1
fi
shift

SRCS=$(find rtl -name "*.v" ! -name "instruction_memory.v" | sort)
iverilog -g2012 -o build/sim "$TB" $SRCS "$@" || exit 1
vvp build/sim
