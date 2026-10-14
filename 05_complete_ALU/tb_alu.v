`timescale 1ns/1ps

module tb_alu();
    reg [15:0] a, b;
    reg [2:0] opcode;
    wire [15:0] result;
    wire zero_flag;
    wire carry_flag;
    wire overflow_flag;
    wire negative_flag;

    alu uut (
        .a(a), .b(b), .opcode(opcode),
        .result(result), .zero_flag(zero_flag),
        .carry_flag(carry_flag), .overflow_flag(overflow_flag),
        .negative_flag(negative_flag)
    );

    initial begin
        $dumpfile("alu.vcd");
        $dumpvars(0, tb_alu);

        // Test 1: ADD (0x1234 + 0x000C = 0x1240)
        opcode = 3'b000; a = 16'h1234; b = 16'h000C; #10;

        // Test 2: SUB (0x0007 - 0x0003 = 0x0004)
        opcode = 3'b001; a = 16'h0007; b = 16'h0003; #10;

        // Test 3: AND (0xFF0F & 0x0FF0 = 0x0F00)
        opcode = 3'b010; a = 16'hFF0F; b = 16'h0FF0; #10;

        // Test 4: OR  (0xFF0F | 0x0FF0 = 0xFFF)
        opcode = 3'b011; a = 16'hFF0F; b = 16'h0FF0; #10;

        // Test 5: NAND ( ~(0xF0F0 & 0x0F0F) = 0xFFFF )
        opcode = 3'b100; a = 16'hF0F0; b = 16'h0F0F; #10;

        // Test 6: XOR  (0xAA55 ^ 0x55AA = 0xFFFF)
        opcode = 3'b101; a = 16'hAA55; b = 16'h55AA; #10;

        // Test 7: SHIFT LEFT (0x8001 << 1 = 0x0002 with carry out of MSB)
        opcode = 3'b110; a = 16'h8001; b = 16'h0000; #10;

        // Test 8: SHIFT RIGHT (0x8001 >> 1 = 0x4000)
        opcode = 3'b111; a = 16'h8001; b = 16'h0000; #10;

        // Test 9: ZERO FLAG (5 - 5 = 0)
        // The result should be 0, and zero_flag should spike to 1!
        opcode = 3'b001; a = 16'h0005; b = 16'h0005; #10;

        // Test 10: CARRY FLAG (0xFFFF + 0x0001 = 0x0000, carry = 1)
        opcode = 3'b000; a = 16'hFFFF; b = 16'h0001; #10;

        // Test 11: OVERFLOW FLAG (0x4000 + 0x4000 = 0x8000 -> signed overflow!)
        opcode = 3'b000; a = 16'h4000; b = 16'h4000; #10;

        $finish;
    end
endmodule
