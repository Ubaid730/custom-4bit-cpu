// instruction_memory.v - the program ROM (16-bit CPU edition).
//
// This is the DEFAULT/blank ROM: it boots to a single NOP so the CPU sits in
// a safe one-instruction halt loop until you assemble a real program.
// To run your own code, assemble it with assembler.py (it emits a full
// instruction_memory module containing your program) and pass that file to
// sim_all.sh INSTEAD of this one:
//     ./sim_all.sh tb_top_cpu program.v
module instruction_memory(
    input wire [15:0] addr,
    output wire [31:0] instruction
);

    reg [31:0] mem [0:65535];

    initial begin
        // Blank ROM: every word defaults to 32'h0000_0000 = NOP.
        // The PC walks into address 0..N of zeros forever; harmless.
    end

    assign instruction = mem[addr];

endmodule
