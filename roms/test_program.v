module instruction_memory(
    input wire [15:0] addr,
    output wire [31:0] instruction
);

    reg [31:0] mem [0:65535];

    initial begin
        mem[0] = 32'h10000003; // Address 0
        mem[1] = 32'h10010001; // Address 1
        mem[2] = 32'h02001100; // Address 2
        mem[3] = 32'h21000006; // Address 3
        mem[4] = 32'h20000002; // Address 4
        mem[5] = 32'h00000000; // Address 5
        mem[6] = 32'h20000010; // Address 6
        mem[7] = 32'h00000000; // Address 7
        mem[8] = 32'h00000000; // Address 8
        mem[9] = 32'h00000000; // Address 9
        mem[10] = 32'h00000000; // Address 10
        mem[11] = 32'h00000000; // Address 11
        mem[12] = 32'h00000000; // Address 12
        mem[13] = 32'h00000000; // Address 13
        mem[14] = 32'h00000000; // Address 14
        mem[15] = 32'h00000000; // Address 15
        mem[16] = 32'h1000000A; // Address 16
        mem[17] = 32'h1001002B; // Address 17
        mem[18] = 32'h32000021; // Address 18
        mem[19] = 32'h1002FF00; // Address 19
        mem[20] = 32'h10030035; // Address 20
        mem[21] = 32'h12003200; // Address 21
        mem[22] = 32'h10030000; // Address 22
        mem[23] = 32'h11030200; // Address 23
        mem[24] = 32'h1004FFF0; // Address 24
        mem[25] = 32'h12000400; // Address 25
        mem[26] = 32'h30005000; // Address 26
        mem[27] = 32'h100500FF; // Address 27
        mem[28] = 32'h31050000; // Address 28
        mem[29] = 32'h34000000; // Address 29
        mem[30] = 32'h00000000; // Address 30
        mem[31] = 32'h00000000; // Address 31
        mem[32] = 32'h00000000; // Address 32
        mem[33] = 32'h01030100; // Address 33
        mem[34] = 32'h33000000; // Address 34
    end

    assign instruction = mem[addr];
endmodule
