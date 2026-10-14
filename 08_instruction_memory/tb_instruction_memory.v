`timescale 1ns/1ps

// tb_instruction_memory.v - verifies the blank default ROM reads out NOPs.
module tb_instruction_memory();

    reg [15:0] addr;
    wire [31:0] instruction;

    instruction_memory uut (
        .addr(addr),
        .instruction(instruction)
    );

    integer errors = 0;

    task expect32(input [31:0] got, input [31:0] want, input [8*30:1] name);
        begin
            if (got !== want) begin
                $display("FAIL: %s = %h, expected %h", name, got, want);
                errors = errors + 1;
            end else begin
                $display("PASS: %s = %h", name, got);
            end
        end
    endtask

    initial begin
        $dumpfile("instruction_memory_dump.vcd");
        $dumpvars(0, tb_instruction_memory);

        addr = 16'h0000; #10; expect32(instruction, 32'h0000_0000, "ROM[0] blank=NOP");
        addr = 16'h0001; #10; expect32(instruction, 32'h0000_0000, "ROM[1] blank=NOP");
        addr = 16'h0FFF; #10; expect32(instruction, 32'h0000_0000, "ROM[0xFFF] blank=NOP");
        addr = 16'hFFFF; #10; expect32(instruction, 32'h0000_0000, "ROM[0xFFFF] blank=NOP");

        if (errors == 0) $display("*** INSTRUCTION MEMORY TESTS PASSED ***");
        else             $display("*** %0d TEST(S) FAILED ***", errors);
        $finish;
    end

endmodule
