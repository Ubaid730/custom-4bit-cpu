module instruction_memory(
    input wire [15:0] addr,
    output wire [31:0] instruction
);

    reg [31:0] mem [0:65535];

    initial begin
        // Addr 0: LI R0, 3      -> R0 = 3
        mem[0] = 32'h1000_0003;

        // Addr 1: LI R1, 1      -> R1 = 1
        mem[1] = 32'h1010_0001;

        // Addr 2: SUB R0, R1    -> R0 = R0 - 1 (Loop body starts here)
        mem[2] = 32'h0201_0000;

        // Addr 3: JZ to Addr 5  -> If R0==0, jump to 5 to halt.
        mem[3] = 32'h2100_0005;

        // Addr 4: JMP to Addr 2 -> Unconditionally jump back to the SUB instruction!
        mem[4] = 32'h2000_0002;

        // Addr 5: NOP           -> Halt loop (Program ends)
        mem[5] = 32'h0000_0000;
    end

    assign instruction = mem[addr];

endmodule
