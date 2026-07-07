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
        $dumpfile("cpu_top_dump.vcd");
        $dumpvars(0, tb_cpu_top);

        // Initialize
        clk = 0;
        rst = 1; // Hold in reset
        
        #15;     // Wait a little bit
        rst = 0; // Release reset, CPU starts running!
        
        #200;    // Let it run for 20 clock cycles
        $finish;
    end

endmodule