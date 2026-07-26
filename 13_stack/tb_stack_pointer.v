`timescale 1ns/1ps
module tb_stack_pointer;
    reg clk, rst, push, pop;
    wire [3:0] sp;

    // Instantiate the Unit Under Test (UUT)
    stack_pointer uut (
        .clk(clk), .rst(rst), .push(push), .pop(pop), .sp(sp)
    );

    // Clock generation (10ns period)
    always #5 clk = ~clk;

    initial begin
        // Initialize signals
        $dumpfile("stack.vcd");
        $dumpvars(0, tb_stack_pointer);
        clk = 0; rst = 1; push = 0; pop = 0;
        
        // 1. Test Reset (SP should go to 15 / 4'b1111)
        #10 rst = 0; 
        
        // 2. Test PUSH (SP should drop to 14, then 13)
        #10 push = 1; 
        #10 push = 0;
        #10 push = 1;
        #10 push = 0;
        
        // 3. Test POP (SP should rise back to 14)
        #10 pop = 1;
        #10 pop = 0;
        
        // 4. Finish simulation
        #20 $finish;
    end
endmodule