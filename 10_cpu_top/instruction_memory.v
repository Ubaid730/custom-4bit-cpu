module instruction_memory(
    input wire [3:0] addr,
    output wire [7:0] instruction
);

    reg [7:0] mem [0:15];

    initial begin
        mem[0] = 8'b01010011; // Address 0
        mem[1] = 8'b01010101; // Address 1
        mem[2] = 8'b00100001; // Address 2
        mem[3] = 8'b10010101; // Address 3
        mem[4] = 8'b10000010; // Address 4
        mem[5] = 8'b00000000; // Address 5
        mem[6] = 8'b00000000; // Address 6
        mem[7] = 8'b00000000; // Address 7
        mem[8] = 8'b00000000; // Address 8
        mem[9] = 8'b00000000; // Address 9
        mem[10] = 8'b00000000; // Address 10
        mem[11] = 8'b00000000; // Address 11
        mem[12] = 8'b00000000; // Address 12
        mem[13] = 8'b00000000; // Address 13
        mem[14] = 8'b00000000; // Address 14
        mem[15] = 8'b00000000; // Address 15
    end

    assign instruction = mem[addr];
endmodule
