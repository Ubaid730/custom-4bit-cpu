`timescale 1ns/1ps

module tb_full_adder();
    reg a, b, cin;
    wire sum, cout;

    full_adder uut (
        .a(a), .b(b), .cin(cin),
        .s(sum), .c(cout)
    );

    initial begin
        $dumpfile("full_adder.vcd");
        $dumpvars(0, tb_full_adder);

        // Testing all 8 combinations
        a=0; b=0; cin=0; #10; // 0+0+0 = 0
        a=0; b=0; cin=1; #10; // 0+0+1 = 1
        a=0; b=1; cin=0; #10; // 0+1+0 = 1
        a=0; b=1; cin=1; #10; // 0+1+1 = 2 (Sum 0, Carry 1)
        a=1; b=0; cin=0; #10; // 1+0+0 = 1
        a=1; b=0; cin=1; #10; // 1+0+1 = 2 (Sum 0, Carry 1)
        a=1; b=1; cin=0; #10; // 1+1+0 = 2 (Sum 0, Carry 1)
        a=1; b=1; cin=1; #10; // 1+1+1 = 3 (Sum 1, Carry 1)

        $finish;
    end
endmodule