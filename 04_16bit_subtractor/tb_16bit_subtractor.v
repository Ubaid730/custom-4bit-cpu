`timescale 1ns/1ps

module tb_adder_subtractor_16bit();
    reg [15:0] a, b;
    reg sub;
    wire [15:0] sum;
    wire cout;

    adder_subtractor_16bit uut (
        .a(a), .b(b), .sub(sub),
        .sum(sum), .cout(cout)
    );

    initial begin
        $dumpfile("adder_sub_16.vcd");
        $dumpvars(0, tb_adder_subtractor_16bit);

        // Test 1: Addition (0x1234 + 0x0001 = 0x1235)
        sub = 0; a = 16'h1234; b = 16'h0001; #10;

        // Test 2: Subtraction (0x1000 - 0x0001 = 0x0FFF)
        sub = 1; a = 16'h1000; b = 16'h0001; #10;

        // Test 3: Subtraction underflow (0x0000 - 0x0001 = 0xFFFF, borrow -> cout 0)
        sub = 1; a = 16'h0000; b = 16'h0001; #10;

        // Test 4: Equal subtract (0xABCD - 0xABCD = 0)
        sub = 1; a = 16'hABCD; b = 16'hABCD; #10;

        $finish;
    end
endmodule
