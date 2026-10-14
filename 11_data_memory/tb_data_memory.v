`timescale 1ns/1ps

module tb_data_memory();

    reg clk;
    reg write_enable;
    reg [15:0] addr;
    reg [15:0] data_in;
    wire [15:0] data_out;

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
        addr = 16'b0000000000000000;
        data_in = 16'b0000000000000000;

        #10; // Wait for initial block in RAM to finish

        // --- TEST 1: Read pre-loaded data ---
        addr = 16'h0000; #10; // Should read FFFF
        addr = 16'h0001; #10; // Should read AAAA

        // --- TEST 2: Write new data ---
        addr = 16'h0002;          // Point to Address 2
        data_in = 16'hBEEF;       // We want to write 0xBEEF
        write_enable = 1;         // Turn on write mode
        #10;                      // Wait for clock edge to write

        write_enable = 0;         // Turn off write mode
        #10;                      // Wait a cycle

        // --- TEST 3: Read the data we just wrote ---
        addr = 16'h0002; #10;     // Should now read BEEF

        // --- TEST 4: High address write/read ---
        addr = 16'hFFFE;
        data_in = 16'h1234;
        write_enable = 1; #10;
        write_enable = 0; #10;
        addr = 16'hFFFE; #10;     // Should read 1234

        $finish;
    end

endmodule
