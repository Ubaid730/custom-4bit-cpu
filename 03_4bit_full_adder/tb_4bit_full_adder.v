`timescale 1ns/1ps

module tb_four_bit_adder();
    reg [3:0] a, b;
    reg cin;
    wire [3:0] sum;
    wire cout;

    // FIXED: Match the module name exactly
    four_bit_full_adder uut (
        .a(a), .b(b), .cin(cin),
        .sum(sum), .cout(cout)
    );

    initial begin
        $dumpfile("four_bit_adder.vcd");
        $dumpvars(0, tb_four_bit_adder);

        // Test 1: 0 + 0
        cin = 0; a = 4'b0000; b = 4'b0000; #10;
        
        // Test 2: 5 + 3 = 8
        cin = 0; a = 4'b0101; b = 4'b0011; #10;
        
        // Test 3: 15 + 1 = 16 (This will overflow our 4 bits!)
        // 15 is 1111. 16 is 10000 (5 bits). 
        // We should see sum = 0000 and cout = 1!
        cin = 0; a = 4'b1111; b = 4'b0001; #10;

        $finish;
    end
endmodule