// test_program.v - hand-assembled ROM image for the regression testbench.
// Word format (32-bit): opcode[31:24] | dest[19:16] | src[15:12] | src2[11:8] | imm[7:0]
// LI / jumps / CALL take their 16-bit operand from instruction[15:0].
module instruction_memory(
    input wire [15:0] addr,
    output wire [31:0] instruction
);

    reg [31:0] mem [0:65535];

    initial begin
        // ---------- PASS A: countdown loop (LI/SUB/JZ/JMP + flag gating) ----------
        mem[0]  = 32'h1000_0003; // LI   R0, 3          ; counter
        mem[1]  = 32'h1001_0001; // LI   R1, 1          ; step
        mem[2]  = 32'h0200_0100; // SUB  R0, R1         ; LOOP: R0-=1, sets Z flag
        mem[3]  = 32'h2100_0006; // JZ   DONE           ; branch when R0==0
        mem[4]  = 32'h2000_0002; // JMP  LOOP           ; keep counting down
        mem[5]  = 32'h0000_0000; // NOP                 ; filler
        mem[6]  = 32'h2000_0010; // DONE: JMP DEMO2     ; fall into pass B

        // ---------- PASS B: CALL/RET + STORE/LOAD + GPIO MMIO + PUSH/POP ----------
        mem[16] = 32'h1000_000A; // DEMO2: LI   R0, 10      ; first number
        mem[17] = 32'h1001_002B; //        LI   R1, 43      ; second number
        mem[18] = 32'h3200_0021; //        CALL ADD_ROUTINE  ; -> 33, pushes PC+1=19
        mem[19] = 32'h1002_FF00; //        LI   R2, 0xFF00   ; RAM address
        mem[20] = 32'h1203_0002; //        STORE R3, R2      ; ram[0xFF00] = R3 (=0x35)
        mem[21] = 32'h1003_0000; //        LI   R3, 0        ; clear R3
        mem[22] = 32'h1103_0002; //        LOAD  R3, R2      ; R3 = ram[0xFF00] (expect 0x0035)
        mem[23] = 32'h1004_FFF0; //        LI   R4, 0xFFF0   ; GPIO address
        mem[24] = 32'h1200_0004; //        STORE R0, R4      ; leds = R0 (expect 0x000A)
        mem[25] = 32'h3005_0000; //        PUSH R5           ; stack: push R5 (=0)
        mem[26] = 32'h1005_00FF; //        LI   R5, 0xFF     ; scribble on R5
        mem[27] = 32'h3105_0000; //        POP  R5           ; restore R5 (expect 0x0000)
        mem[28] = 32'h2000_001C; //        JMP PARK          ; self-loop at 28 forever

        // ---------- subroutine ADD_ROUTINE at 33 ----------
        mem[33] = 32'h0103_0001; // ADD  R3, R0, R1     ; R3 = R0 + R1 = 0x35
        mem[34] = 32'h3300_0000; // RET                 ; pop return address -> PC=19
    end

    assign instruction = mem[addr];
endmodule
