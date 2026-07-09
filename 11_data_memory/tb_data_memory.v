`timescale 1ns/1ps

module tb_data_memory();

    reg clk;
    reg write_enable;
    reg [3:0] addr;
    reg [3:0] data_in;
    wire [3:0] data_out;

    // Instantiate the Data Memory
    data_memory uut (
        .clk(clk),
        .write_enable(write_enable),
        .addr(addr),
        .data_in(data_in),
        .data_out(data_out)
    );

    // Generate clock
    always #5 clk = ~clk;

    initial begin
        $dumpfile("data_memory_dump.vcd");
        $dumpvars(0, tb_data_memory);

        // Initialize
        clk = 0;
        write_enable = 0;
        addr = 4'b0000;
        data_in = 4'b0000;

        #10; // Wait for initial block in RAM to finish

        // --- TEST 1: Read pre-loaded data ---
        addr = 4'b0000; #10; // Should read 1010 (A)
        addr = 4'b0001; #10; // Should read 0101 (5)

        // --- TEST 2: Write new data ---
        addr = 4'b0010;          // Point to Address 2
        data_in = 4'b1111;       // We want to write 15 (F)
        write_enable = 1;        // Turn on write mode
        #10;                     // Wait for clock edge to write
        
        write_enable = 0;        // Turn off write mode
        #10;                     // Wait a cycle

        // --- TEST 3: Read the data we just wrote ---
        addr = 4'b0010; #10;     // Should now read 1111 (F)

        $finish;
    end

endmodule