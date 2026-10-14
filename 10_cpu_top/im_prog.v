module instruction_memory(
    input wire [15:0] addr,
    output wire [31:0] instruction
);

    reg [31:0] mem [0:65535];

    initial begin
        mem[0] = 32'h10010000_0000; // Address 0
        mem[1] = 32'h11000100_0100; // Address 1
        mem[2] = 32'h10010001_0001; // Address 2
        mem[3] = 32'h11020100_0100; // Address 3
        mem[4] = 32'h10010002_0002; // Address 4
        mem[5] = 32'h11030100_0100; // Address 5
        mem[6] = 32'h12002000_2000; // Address 6
        mem[7] = 32'h12003000_3000; // Address 7
        mem[8] = 32'h20000006_0006; // Address 8
    end

    assign instruction = mem[addr];
endmodule
