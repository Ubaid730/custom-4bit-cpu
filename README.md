# 4-Bit CPU in Verilog 🖥️

A from-scratch educational CPU built entirely in Verilog. This project follows a "simulation-first" philosophy: every component is designed, tested in Icarus Verilog, and verified in GTKWave before being integrated into the larger system.

## What it does
This CPU can execute an 8-bit instruction set to perform math, move data between registers and memory, and make decisions using jumps.

### Current Features
*   **ALU:** Addition, Subtraction, AND, OR.
*   **Registers:** 4x 4-bit general-purpose registers (R0–R3).
*   **Memory:** Separate Instruction ROM (16 addresses) and Data RAM (16 addresses).
*   **Control Unit:** Decodes opcodes and manages the datapath.
*   **Flags:** Zero flag for conditional branching.

## The Instruction Set (ISA)
| Opcode | Mnemonic | Description |
| :--- | :--- | :--- |
| `0000` / `0001` | **ADD** | Add two registers |
| `0010` | **SUB** | Subtract two registers |
| `0011` | **AND** | Bitwise AND |
| `0100` | **OR** | Bitwise OR |
| `0101` | **LOADI** | Load immediate value |
| `0110` | **LOAD** | Load from RAM |
| `0111` | **STORE** | Store to RAM |
| `1000` | **JMP** | Unconditional Jump |
| `1001` | **JZ** | Jump if Zero |

## How to Simulate
You need **Icarus Verilog** and **GTKWave** installed on your system.

1.  **Compile all modules:**
    ```bash
    iverilog -o cpu_sim tb_cpu_top.v *.v
    ```
2.  **Run the simulation:**
    ```bash
    vvp cpu_sim
    ```
3.  **View the waveforms:**
    ```bash
    gtkwave dump.vcd
    ```

## Project Structure
*   `cpu_top.v`: The main integration of all components.
*   `alu.v`, `register_file.v`, `control_unit.v`: The core CPU logic.
*   `instruction_memory.v`, `data_memory.v`: Storage for code and variables.
*   `tb_*.v`: Testbenches used to verify each module.

## Philosophy
> "Build instead of consume. Understand every component before integrating it."
