`timescale 1ns/1ps

module tb_instruction_memory();

    reg [3:0] addr;
    wire [7:0] instruction;

    // Instantiate the Instruction Memory
    instruction_memory uut (
        .addr(addr),
        .instruction(instruction)
    );

    initial begin
        // Setup GTKWave dumping
        $dumpfile("instruction_memory_dump.vcd");
        $dumpvars(0, tb_instruction_memory);

        // Test Sequence
        addr = 4'b0000; #10; // Look at Address 0
        addr = 4'b0001; #10; // Look at Address 1
        addr = 4'b0010; #10; // Look at Address 2
        addr = 4'b0011; #10; // Look at Address 3
        addr = 4'b0100; #10; // Look at Address 4 (Should be 0 since we didn't program it)
        
        $finish;
    end

endmodule