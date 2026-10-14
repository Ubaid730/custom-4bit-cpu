# VERITON-16 — 16-bit CPU Datasheet & Programmer's Guide

**Version:** 2.0 (clean-tree release)  ·  **Status:** All regression tests PASS  
A Von Neumann-style 16-bit educational CPU written in plain Verilog, with a
32-bit fixed-length instruction word, MMIO peripherals (GPIO + UART), a
hardware stack, subroutine calls, conditional branches and a HALT instruction.

---

## 1. Quick Start

```bash
# Assemble a program -> ROM image
python3 scripts/assembler.py examples/countdown.asm build/program.v

# Run it on the full-CPU testbench
./scripts/simulate.sh tb_top_cpu build/program.v

# Run the regression suite (7 checks: countdown, DEMO2, CALL/RET, STORE/LOAD, GPIO, PUSH/POP, HALT)
./scripts/simulate.sh tb_full_cpu roms/test_program.v

# Virtual console (UART TX -> terminal text, LEDs -> status line)
./scripts/simulate.sh tb_virt build/bootloader.v
```

Repository layout:

| Path        | Contents                                             |
|-------------|------------------------------------------------------|
| `rtl/`      | Synthesizable Verilog (the CPU itself)               |
| `tests/`    | Testbenches (`tb_top_cpu`, `tb_full_cpu`, `tb_virt`) |
| `roms/`     | Pre-assembled regression ROM images                  |
| `examples/` | `.asm` sources (countdown, blink, bootloader, ...)   |
| `scripts/`  | `assembler.py` + `simulate.sh`                       |
| `docs/`     | This datasheet                                       |
| `build/`    | Generated artifacts (gitignored)                     |

---

## 2. Architecture Overview

```
            +----------------+
            | Program Counter|----+
            +----------------+    |  address (16b)
                                  v
   clock -----> +--------------------+     +---------------+
                | Instruction Memory |---->| Fetch Latch   |
                | (ROM, 64K x 32b)   |     | (opcode/src/  |
                +--------------------+     |  dest/imm/pc) |
                                           +-------+-------+
                                                   | decoded fields
             +-----------+   +------------+  +-----v------+
             | ALU (16b) |<--| RegFile A/B|<-| Control    |
             | Z C V N   |   | (16 x 16b) |  | Unit       |
             +-----+-----+   +-----+------+  +-----+------+
                   |               ^ write          |
                   v               |                v
            +--------------+  +---------+   flags / enables
            | Data Memory  |  | Flags   |<-- ALU result
            | RAM 64K x16b |  | Regs    |
            +--------------+  +---------+
                   |
                   +--> MMIO window 0xFFF0-0xFFFF
                        GPIO (LEDs) @0xFFF8, UART TX @0xFFFA
```

* **Word size:** 16-bit data, 32-bit instructions.
* **Memory:** unified 16-bit address space (65,536 words). Instructions live in
  a separate 32-bit-wide ROM addressed by PC; data lives in RAM. The top 16
  addresses (`0xFFF0..0xFFFF`) are an MMIO window decoded away from RAM.
* **Execution model:** two registered stages — *fetch* (latch IR at PC) and
  *execute* (everything else acts on the latched fields). Branches redirect the
  PC using the execute-stage latched immediate, so there is no one-word-off
  decode hazard. HALT parks both PC and IR forever.
* **Registers:** 16 general-purpose 16-bit registers R0–R15, plus PC and SP.
  There is no dedicated accumulator or link register — return addresses go on
  the stack via `CALL`.
* **Flags:** Zero, Carry, Overflow, Negative — single shared flag register,
  updated only when the executing instruction has `flags_write` asserted
  (ALU ops and CMP; NOT loads, pushes, etc.).

### Register file
| Port | Use                          |
|------|------------------------------|
| A    | src operand / store-address? |
| B    | src2 operand                 |
| W    | dest (writeback)             |

Writes take effect on the rising edge; reads are combinational with a
same-cycle write-through bypass, so back-to-back dependent instructions work
without stalls.

---

## 3. Instruction Set Architecture (ISA)

### 3.1 Encoding format (little-field order inside the 32-bit word)

```
 bit 31              24 23    20 19    16 15                     0
+---------------------+--------+--------+-------------------------+
|      opcode         |  dest  |  src   | imm16 / src2 in [11:8]  |
+---------------------+--------+--------+-------------------------+
```

| Field   | Bits    | Meaning                                        |
|---------|---------|------------------------------------------------|
| opcode  | [31:24] | 8-bit operation code                           |
| dest    | [23:20] | destination register (4-bit)                   |
| src     | [19:16] | source register A                              |
| src2    | [15:12] | source register B (reg-reg forms)              |
| imm16   | [15:0]  | 16-bit immediate (LI, jumps, CALL, SHL/SHR amt in low nibble) |

The assembler accepts both `SUB R0, R1, R2` (dest,src,src2) and the common
two-operand form `SUB R0, R1` (which fills src = src2 = R1).

### 3.2 Opcode map

| Op     | Code   | Syntax                | Semantics (flags unless noted)                    |
|--------|--------|-----------------------|---------------------------------------------------|
| NOP    | 0x00   | `NOP`                 | nothing                                           |
| ADD    | 0x01   | `ADD Rd, Ra, Rb`      | Rd = Ra + Rb  → Z C V N                           |
| SUB    | 0x02   | `SUB Rd, Ra, Rb`      | Rd = Ra − Rb  → Z C V N                           |
| AND    | 0x03   | `AND Rd, Ra, Rb`      | bitwise AND → Z N                                 |
| OR     | 0x04   | `OR  Rd, Ra, Rb`      | bitwise OR  → Z N                                 |
| NAND   | 0x05   | `NAND Rd, Ra, Rb`     | ~(Ra & Rb) → Z N                                  |
| XOR    | 0x06   | `XOR Rd, Ra, Rb`      | bitwise XOR → Z N                                 |
| SHL    | 0x07   | `SHL Rd, Rs, #n`      | logical left shift n bits → Z N (carry = last out)|
| SHR    | 0x08   | `SHR Rd, Rs, #n`      | logical right shift n bits → Z N (carry = last out)|
| CMP    | 0x09   | `CMP Ra, Rb`          | sets flags of Ra−Rb, no writeback                 |
| LI     | 0x0A   | `LI Rd, #imm16`       | Rd = imm16 (no flags)                             |
| LOAD   | 0x0B   | `LOAD Rd, [Rs]`       | Rd = mem[Rs] (no flags)                           |
| STORE  | 0x0C   | `STORE Rs, [Ra]`      | mem[Ra] = Rs ; if Ra in MMIO window → device      |
| JMP    | 0x10   | `JMP label`           | PC = imm16                                        |
| JZ     | 0x11   | `JZ label`            | if Z then PC = imm16                              |
| JNZ    | 0x12   | `JNZ label`           | if !Z then PC = imm16                             |
| JC     | 0x13   | `JC label`            | if C then PC = imm16                              |
| JNC    | 0x14   | `JNC label`           | if !C then PC = imm16                             |
| JN     | 0x15   | `JN label`            | if N then PC = imm16                              |
| JNN    | 0x16   | `JNN label`           | if !N then PC = imm16                             |
| PUSH   | 0x20   | `PUSH Rs`             | SP = SP−1 ; mem[SP] = Rs                          |
| POP    | 0x21   | `POP Rd`              | Rd = mem[SP] ; SP = SP+1                          |
| CALL   | 0x22   | `CALL label`          | push return PC (next instr addr); PC = imm16      |
| RET    | 0x23   | `RET`                 | PC = pop()                                        |
| OUT    | 0x30   | `OUT Rs, [Ra]`        | alias of STORE (device write)                     |
| IN     | 0x31   | `IN Rd, [Ra]`         | alias of LOAD (device read)                       |
| HALT   | 0x34   | `HALT`                | park PC + IR forever until reset                  |

*(Opcodes 0x0D–0x0F, 0x17–0x1F, 0x24–0x2F, 0x32–0x33, 0x35–0xFF are free for
future expansion.)*

### 3.3 Flag semantics
* **Z** — result == 0.
* **C** — carry-out of bit 15 (ADD) / borrow (SUB: set when no borrow) / last
  bit shifted out (SHL/SHR).
* **V** — signed overflow (operands same sign, result opposite).
* **N** — bit 15 of result.
* `CMP` computes `src − src2` internally and writes ONLY the flags.
* Loads/PUSH/POP/LI/CALL never disturb flags — safe to interleave with
  flag-driven loops.

### 3.4 Assembler syntax highlights
```asm
; comments start with ';'
start:  LI   R0, 3          ; 16-bit immediates allowed
loop:   DEC-equivalent:
        LI   R1, 1
        SUB  R0, R0, R1     ; three-operand form
        CMP  R0, R2         ; or two-operand (fills src=src2)
        JZ   done
        JMP  loop
done:   OUT  R0, [R15]      ; R15 preloaded with 0xFFF8 (LEDs)
        CALL routine
        HALT
routine: PUSH R3
         ADD  R3, R3, R3
         POP  R3
         RET
```
Labels resolve to word addresses; `#` prefixes on immediates are optional.

---

## 4. Memory Map

| Range          | Maps to                                   |
|----------------|-------------------------------------------|
| `0x0000–0xEFFF`| RAM (data memory, 60 KiB usable)          |
| `0xF000–0xFFEF`| RAM (stack region grows down from 0xFFFE) |
| `0xFFF0–0xFFF7`| reserved MMIO (reads 0)                   |
| `0xFFF8–0xFFF9`| **GPIO LEDs** — write low byte = LED pattern; read returns last written value |
| `0xFFFA–0xFFFB`| **UART DATA** — write triggers TX of low byte (9-bit frame incl. parity slot); read returns last RX byte (stub = 0) |
| `0xFFFC–0xFFFF`| UART STATUS — bit0 = tx-busy (read-only)  |

Initial SP after reset = `0xFFFE` (first PUSH lands at `0xFFFD`).

---

## 5. Peripherals

### 5.1 GPIO
One 8-bit output register driving `leds[7:0]`. Write any word whose address
falls in the GPIO window; the low byte appears on `leds_out`. Read-back works
via `IN Rd,[Ra]`.

### 5.2 UART (TX functional, RX stubbed)
Writing a byte to `0xFFFA` starts an asynchronous frame on `uart_tx`:
**115200 baud default, 8N1**, LSB first, idle-high. The testbench
`tests/tb_virt.v` decodes the serial stream back into printable characters and
renders a "screen" — this is your virtual console. RX side exists as
`io_registers` with a ready/byte pair but is not driven by a real receiver in
simulation yet.

---

## 6. Bootloader, Kernel & OS Guide

### 6.1 Reset behavior
On rising-edge `reset_n` release: PC ← 0, IR cleared, all registers zeroed,
SP ← 0xFFFE, flags cleared, halted de-asserted. Execution begins at ROM word 0
— exactly like real hardware boot vectors.

### 6.2 Writing a bootloader
Your bootloader IS the ROM image (word 0 onward). Pattern used by
`examples/bootloader.asm`:

1. **Early init** — zero scratch registers, set up the LED pointer
   (`LI R15, 0xFFF8`).
2. **Banner** — print over UART by storing bytes to `0xFFFA`.
3. **Stage load** — copy a kernel image from ROM (higher addresses) into RAM
   with a LOAD/STORE loop.
4. **Handoff** — `JMP kernel_entry`. From here the kernel owns RAM and the
   stack.

Because ROM and RAM share the same 16-bit index space, a loader loop simply
addresses ROM constants through the assembler's literal pool (labels) and
writes them into RAM windows.

### 6.3 Kernel conventions
* **Syscall-free**: kernels call subroutines directly (`CALL`/`RET`).
* **Context switch**: PUSH/POP all live registers around the switch; save the
  stack pointer itself into a per-task control block in RAM.
* **Scheduler tick**: without interrupts (see Limitations), poll a software
  counter or the UART status port in a cooperative loop.
* **Console driver**: `PUTC`: `STORE R_byte, [R_uart]`; busy-wait on
  `IN R_tmp,[R_status]` bit0 before writing the next char.

### 6.4 Minimal OS recipe
A tiny分时 OS on VERITON-16 needs: a fixed task table in RAM, a cooperative
scheduler loop that `CALL`s each task entry, PUSH/POP context frames, and the
UART console above. `examples/bootloader.asm` already demonstrates the
boot→kernel handoff path; extend it with a second task and a dispatcher loop.

---

## 7. Limitations (honest list)

1. **No interrupts / exceptions.** Only polled I/O. Future: IRQ lines + vector
   table + automatic state save.
2. **No indexed addressing** (`mem[base+offset]`) — indirect-only through a
   register holding the full address. Costs a couple of extra instructions per
   array access.
3. **Single-cycle everything** — no pipelining beyond fetch/execute latch, so
   max clock is limited by the whole datapath delay; fine at simulation speeds.
4. **No MUL/DIV** in the ALU. Software multiply = shift-and-add loops.
5. **UART RX is a stub** — you can talk TO the machine but not FROM it yet.
6. **No cache / wait states** — assumes ideal BRAM timing; real FPGA synthesis
   will need proper dual-port inference.
7. **Stack underflow/overflow untrapped** — SP wraps silently at 0x0000/0xFFFF.
8. **Immediate width** — 16-bit absolute addresses only; the whole address
   space is reachable directly (nice property), but there are no PC-relative
   or long-displacement modes.

---

## 8. Roadmap / Future Additions

* **Interrupt controller** (vector table + IRET) — enables preemptive OS.
* **Hardware multiplier** (sequential 16×16) and restoring divider.
* **Indexed addressing mode** (`LOAD Rd, [Ra+#off]`) — big QoL win for arrays.
* **Real UART RX** wired into `io_registers` so the virtual console becomes
  interactive (type into the simulator).
* **Timer peripheral** at `0xFFFC` for scheduler ticks.
* **Multi-cycle microcoded engine** to raise fmax and shrink area.
* **Yosys → FPGA flow** (board constraints for iCE40/ECP5) to run the
  bootloader on silicon.
* **Toolchain growth:** linker, ELF loader, and an emulator binary that reuses
  `tb_virt`'s UART decoder as a VM front-end.

---

## 9. Verification Status

| Test | What it covers | Result |
|------|----------------|--------|
| `tb_top_cpu` | countdown demo end-to-end | ✅ PASS |
| `tb_full_cpu` | 7-check regression: countdown, DEMO2, CALL/RET, STORE/LOAD round-trip, GPIO LED write, PUSH/POP restore, HALT park | ✅ 7/7 PASS |
| `tb_virt` | bootloader banner on virtual UART console | ✅ chars received |
| unit tbs (`tb_dbg`, `tb_trace`, …) | ALU, flags, stack timing probes | ✅ available |

Run everything: `./scripts/simulate.sh tb_full_cpu roms/test_program.v`

---

## 10. File-by-file reference

| RTL module | Role |
|------------|------|
| `cpu_top.v` | integration, fetch latch, PC/control muxing, HALT parking |
| `control_unit.v` | opcode → enable/selector decoding |
| `alu.v`, `16bit_full_adder.v`, `16bit_subtractor.v` | 16-bit ALU + flags |
| `register_file.v` | 16×16b RF with write-through bypass |
| `program_counter.v` | 16-bit PC with load/hold |
| `stack_pointer.v` | down-growing SP with push/pop strobes |
| `flag_registers.v` | Z/C/V/N storage with gated write |
| `instruction_memory.v` | 64K×32b ROM (replaceable by generated image) |
| `data_memory.v` | 64K×16b RAM |
| `mmio_decoder.v`, `gpio.v`, `io_registers.v` | peripheral window |
| `uart_tx.v` (+`uart_rx.v`) | serial console |
| legacy 4-bit cells (`half_adder.v`, `full_adder.v`, `four_bit_subtractor.v`, `mux_4to1.v`, `decode_2to4.v`, `register.v`) | kept for historical continuity; unused by cpu_top |

© Built from a humble 4-bit core into a genuinely usable 16-bit machine.
