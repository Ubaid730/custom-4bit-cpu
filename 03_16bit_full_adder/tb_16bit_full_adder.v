`timescale 1ns/1ps

module tb_sixteen_bit_adder();
    reg [15:0] a, b;
    reg cin;
    wire [15:0] sum;
    wire cout;

    sixteen_bit_full_adder uut (
        .a(a), .b(b), .cin(cin),
        .sum(sum), .cout(cout)
    );

    initial begin
        $dumpfile("sixteen_bit_adder.vcd");
        $dumpvars(0, tb_sixteen_bit_adder);

        // Test 1: 0 + 0
        cin = 0; a = 16'h0000; b = 16'h0000; #10;

        // Test 2: 5 + 3
        cin = 0; a = 16'h0005; b = 16'h0003; #10;

        // Test 3: 0xFFFF + 1 (with carry in 0) -> sum 0, cout 1
        cin = 0; a = 16'hFFFF; b = 16'h0001; #10;

        // Test 4: 0x1234 + 0xDCBA + cin 1 -> 0x0000 with carry out
        cin = 1; a = 16'h1234; b = 16'hDCBB; #10;

        // Test 5: 0x8000 + 0x8000 -> 0 with cout
        cin = 0; a = 16'h8000; b = 16'h8000; #10;

        $display("Done.");
        $finish;
    end
endmodule
