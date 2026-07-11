module instruction_memory(
    input wire [3:0] addr,
    output wire [7:0] instruction
);

    reg [7:0] mem [0:15];

    initial begin
        // Addr 0: LI R0, 3      -> R0 = 3
        mem[0] = 8'b0101_00_11; 
        
        // Addr 1: LI R1, 1      -> R1 = 1
        mem[1] = 8'b0101_01_01; 
        
        // Addr 2: SUB R0, R1    -> R0 = R0 - 1 (Loop body starts here)
        mem[2] = 8'b0010_00_01; 
        
        // Addr 3: JZ to Addr 5  -> If R0==0, jump to 5 to halt. (dest=01, src=01 -> 0101)
        mem[3] = 8'b1001_01_01; 
        
        // Addr 4: JMP to Addr 2 -> Unconditionally jump back to the SUB instruction! (dest=00, src=10 -> 0010)
        mem[4] = 8'b1000_00_10; 
        
        // Addr 5: NOP           -> Halt loop (Program ends)
        mem[5] = 8'b0000_00_00; 
        
        // Clear the rest
        mem[6] = 8'b0000_00_00;
        mem[7] = 8'b0000_00_00;
    end

    assign instruction = mem[addr];

endmodule