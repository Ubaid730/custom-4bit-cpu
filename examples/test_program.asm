// test_program.asm - canonical source for the regression ROM roms/test_program.v
// Regenerate with:  python3 scripts/assembler.py examples/test_program.asm roms/test_program.v
// tb_full_cpu expects: DEMO2 at word 16, HALT parked at word 29 (PC 0x1D),
// subroutine ADD_ROUTINE at word 33.
LI R0, 3            // 0: counter
LI R1, 1            // 1: step
LOOP:
SUB R0, R1          // 2: R0 -= 1, sets Z
JZ DONE             // 3
JMP LOOP            // 4
NOP                 // 5
DONE:
JMP DEMO2           // 6: pad so DEMO2 lands on address 16
NOP                 // 7
NOP                 // 8
NOP                 // 9
NOP                 // 10
NOP                 // 11
NOP                 // 12
NOP                 // 13
NOP                 // 14
NOP                 // 15
DEMO2:
LI R0, 10           // 16: first number
LI R1, 43           // 17: second number
CALL ADD_ROUTINE    // 18: pushes PC+1 (=19), jumps to 33
LI R2, 0xFF00       // 19: RAM address
LI R3, 0x35         // 20: value to store
STORE R3, R2        // 21: ram[0xFF00] = 0x35
LI R3, 0            // 22: clear R3
LOAD R3, R2         // 23: round-trip - must read back 0x35
LI R4, 0xFFF0       // 24: GPIO address
STORE R0, R4        // 25: leds = 10
PUSH R5             // 26: save R5 (=0)
LI R5, 0xFF         // 27: scribble on R5
POP R5              // 28: restore R5 (=0)
HALT                // 29: parks here forever
NOP                 // 30
NOP                 // 31
NOP                 // 32
NOP                 // 33
NOP                 // 34
ADD_ROUTINE:
PUSH R0             // 35: save args (ADD clobbers R[dest]=R[src])
PUSH R1             // 36
ADD R3, R0, R1      // 37: R3 = R0 + R1 = 10 + 43 = 0x35
POP R1              // 38
POP R0              // 39
RET                 // 40: pops return addr -> PC
