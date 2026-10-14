`timescale 1ns/1ps

module tb_instruction_memory();

    reg [15:0] addr;
    wire [31:0] instruction;

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
        addr = 16'h0000; #10; // Look at Address 0
        addr = 16'h0001; #10; // Look at Address 1
        addr = 16'h0002; #10; // Look at Address 2
        addr = 16'h0003; #10; // Look at Address 3
        addr = 16'h0004; #10; // Look at Address 4 (Should be 0 since we didn't program it)

        $finish;
    end

endmodule
