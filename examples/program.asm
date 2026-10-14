// blink.asm

// 1. Get the GPIO Address (15) from RAM Address 0
LI R1, 0       // R1 = 0 (This is the RAM address)
LOAD R0, R1    // R0 = RAM[0] = 15 (Now R0 holds the GPIO address!)

// 2. Get LED Pattern 1 (5) from RAM Address 1
LI R1, 1       // R1 = 1 (RAM address)
LOAD R2, R1    // R2 = RAM[1] = 5 (Pattern 1: 0101)

// 3. Get LED Pattern 2 (10) from RAM Address 2
LI R1, 2       // R1 = 2 (RAM address)
LOAD R3, R1    // R3 = RAM[2] = 10 (Pattern 2: 1010)

// 4. The Blink Loop
LOOP:
STORE R2, R0   // Write Pattern 1 (R2) to GPIO (Address in R0)
STORE R3, R0   // Write Pattern 2 (R3) to GPIO (Address in R0)
JMP LOOP       // Loop forever