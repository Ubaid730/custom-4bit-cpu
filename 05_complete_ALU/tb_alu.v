`timescale 1ns/1ps

module tb_alu();
    reg [3:0] a, b;
    reg [1:0] opcode;
    wire [3:0] result;
    wire zero_flag;

    alu uut (
        .a(a), .b(b), .opcode(opcode),
        .result(result), .zero_flag(zero_flag)
    );

    initial begin
        $dumpfile("alu.vcd");
        $dumpvars(0, tb_alu);

        // Test 1: ADD (5 + 3 = 8)
        opcode = 2'b00; a = 4'b0101; b = 4'b0011; #10;

        // Test 2: SUB (7 - 3 = 4)
        opcode = 2'b01; a = 4'b0111; b = 4'b0011; #10;

        // Test 3: AND (1010 & 1100 = 1000) -> 10 & 12 = 8
        opcode = 2'b10; a = 4'b1010; b = 4'b1100; #10;

        // Test 4: OR (1010 | 1100 = 1110) -> 10 | 12 = 14
        opcode = 2'b11; a = 4'b1010; b = 4'b1100; #10;

        // Test 5: ZERO FLAG (5 - 5 = 0)
        // The result should be 0, and zero_flag should spike to 1!
        opcode = 2'b01; a = 4'b0101; b = 4'b0101; #10;

        $finish;
    end
endmodule