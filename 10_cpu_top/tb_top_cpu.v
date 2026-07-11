`timescale 1ns/1ps

module tb_cpu_top();

    reg clk;
    reg rst;

    // Instantiate the Top-Level CPU
    cpu_top uut (
        .clk(clk),
        .rst(rst)
    );

    // Generate a clock signal: toggles every 5ns (10ns period)
    always #5 clk = ~clk;

    initial begin
        // Setup GTKWave dumping
        $dumpfile("cpu_loop_dump.vcd");
        $dumpvars(0, tb_cpu_top);

        // Initialize signals
        clk = 0;
        rst = 1; // Hold in reset
        
        #20;     // Wait a little bit for stability
        rst = 0; // Release reset, CPU starts running!
        
        #400;    // Let it run for 40 clock cycles to see the full loop
        $finish;
    end

endmodule