// countdown.asm - the classic demo for this CPU (16-bit edition)
LI R0, 3          // R0 = 3 (counter)
LI R1, 1          // R1 = 1 (step)
LOOP:
SUB R0, R1        // R0 = R0 - 1 (sets flags!)
JZ DONE           // if R0 == 0 -> branch to DONE
JMP LOOP          // otherwise keep counting down
DONE:
NOP               // park here (halt loop)
