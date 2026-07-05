`timescale 1ns/1ps

module tb_adder_subtractor();
    reg [3:0] a, b;
    reg sub;
    wire [3:0] sum;
    wire cout;

    adder_subtractor uut (
        .a(a), .b(b), .sub(sub),
        .sum(sum), .cout(cout)
    );

    initial begin
        $dumpfile("adder_sub.vcd");
        $dumpvars(0, tb_adder_subtractor);

        // Test 1: Addition (5 + 3 = 8)
        sub = 0; a = 4'b0101; b = 4'b0011; #10;
        
        // Test 2: Subtraction (7 - 3 = 4)
        sub = 1; a = 4'b0111; b = 4'b0011; #10;

        // Test 3: Subtraction with larger numbers (10 - 4 = 6)
        // 10 is 1010, 4 is 0100
        sub = 1; a = 4'b1010; b = 4'b0100; #10;

        $finish;
    end
endmodule