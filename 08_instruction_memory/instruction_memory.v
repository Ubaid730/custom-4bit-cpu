module instruction_memory(
    input wire[3:0] addr,
    output wire[7:0] instruction
);
reg[7:0] mem[0:15];
    initial begin
        
        
        
        mem[0] = 8'b0101_00_01; 
        mem[1] = 8'b0101_01_10; 
        
        // 2. Store R1 into RAM at the address held in R0
        mem[2] = 8'b0111_01_00; // STORE R1, R0 -> RAM[1] = 2
        
        // 3. Change R1 to something else
        mem[3] = 8'b0101_01_11; // LI R1, 3   -> R1 = 3
        
        // 4. Load the value back from RAM into R2
        mem[4] = 8'b0110_10_00; // LOAD R2, R0  -> R2 = RAM[1] (Should be 2!)
        
        // 5. Add them up to prove it worked
        mem[5] = 8'b0001_10_01; // ADD R2, R1   -> R2 = R2 + R1 (2 + 3 = 5)
        
        mem[6] = 8'b0000_00_00; 
    end
assign instruction = mem[addr];
endmodule