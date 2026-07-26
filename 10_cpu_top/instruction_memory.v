module instruction_memory(
    input wire [3:0] addr,
    output wire [7:0] instruction
);

    reg [7:0] mem [0:15];

    initial begin

    // --- Setup Values ---
    mem[0] = 8'b01010010; // 0: LI R0, 2      (R0 = 2)
    mem[1] = 8'b01010111; // 1: LI R1, 3      (R1 = 3)
    
    // --- Test the Stack (PUSH/POP) ---
    mem[2] = 8'b10100000; // 2: PUSH R0       (RAM[15] = 2, SP becomes 14)
    mem[3] = 8'b10100001; // 3: PUSH R1       (RAM[14] = 3, SP becomes 13)
    mem[4] = 8'b10111000; // 4: POP R2        (R2 gets 3, SP becomes 14)
    mem[5] = 8'b10111100; // 5: POP R3        (R3 gets 2, SP becomes 15)
    
    // --- Math & Memory ---
    mem[6] = 8'b00011110; // 6: ADD R3, R2    (R3 = 2 + 3 = 5)
    mem[7] = 8'b01010011; // 7: LI R0, 3      (R0 = 3, preparing the memory address)
    mem[8] = 8'b01111100; // 8: STORE [R0], R3(Store R3(5) into RAM address 3)
    
    // --- Halt ---
    mem[9] = 8'b10001001; // 9: JMP 9         (Infinite loop to halt CPU)
    
    // Fill the rest with NOPs
    mem[10] = 8'b00000000;
    mem[11] = 8'b00000000;
    mem[12] = 8'b00000000;
    mem[13] = 8'b00000000;
    mem[14] = 8'b00000000;
    mem[15] = 8'b00000000;

    end

    assign instruction = mem[addr];
endmodule
