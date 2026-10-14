module instruction_memory(
    input wire [15:0] addr,
    output wire [31:0] instruction
);

    reg [31:0] mem [0:65535];

    initial begin
        mem[0] = 32'h10000003_0003; // Address 0
        mem[1] = 32'h10010001_0001; // Address 1
        mem[2] = 32'h2001100_1100; // Address 2
        mem[3] = 32'h21000005_0005; // Address 3
        mem[4] = 32'h20000002_0002; // Address 4
        mem[5] = 32'h0000_0000; // Address 5
    end

    assign instruction = mem[addr];
endmodule
