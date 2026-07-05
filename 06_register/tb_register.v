`timescale 1ns/1ps

module tb_register_4bit();
    reg clk;
    reg rst;
    reg write_enable;
    reg [3:0] data_in;
    wire [3:0] data_out;

    // Instantiate the Unit Under Test (UUT)
    register uut (
        .clk(clk),
        .rst(rst),
        .we(write_enable),
        .data_in(data_in),
        .data_out(data_out)
    );

    // Clock generation (Toggles every 5ns -> 10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("register_4bit.vcd");
        $dumpvars(0, tb_register_4bit);

        // Test 1: Asynchronous Reset (Output should immediately clear to 0000)
        rst = 1; write_enable = 0; data_in = 4'b0000; #10;
        rst = 0; // Release reset
        
        // Test 2: Write data (Load 5 into register on the next clock edge)
        data_in = 4'b0101; write_enable = 1; #10; 
        
        // Test 3: Hold data (WE=0, should ignore data_in=10 and keep 5)
        write_enable = 0; data_in = 4'b1010; #10;
        
        // Test 4: Overwrite data (Load 12 into register on the next clock edge)
        write_enable = 1; data_in = 4'b1100; #10;
        
        // Test 5: Reset again (Output should immediately clear to 0000)
        rst = 1; #10;

        $finish;
    end
endmodule