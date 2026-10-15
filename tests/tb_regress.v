`timescale 1ns/1ps
// tb_regress.v - canonical regression for the 16-bit CPU.
// Runs roms/test_program.v (regenerate with:
//   python3 scripts/assembler.py examples/test_program.asm roms/test_program.v)
// and checks: countdown, conditional jump timing, CALL/RET, STORE/LOAD
// round-trip, GPIO MMIO, PUSH/POP, SP restore, HALT park.
module tb_regress();
    reg clk, rst;
    integer errors = 0;

    cpu_top uut(.clk(clk), .rst(rst), .rx_in(1'b1));
    always #5 clk = ~clk;

    task expect16(input [15:0] got, input [15:0] want, input [8*40:1] name);
    begin
        if (got !== want) begin
            $display("FAIL: %s = %h, expected %h", name, got, want);
            errors = errors + 1;
        end else $display("PASS: %s = %h", name, got);
    end
    endtask

    // wait until PC == target (or bail out after `max cycles)
    task waitForPC(input [15:0] target, input integer max);
    begin
        integer i;
        for (i = 0; i < max; i = i + 1) begin
            @(posedge clk);
            if (uut.pc_out === target) disable waitForPC;
        end
    end
    endtask

    initial begin
        clk = 0; rst = 1; #25; rst = 0;

        // ---- PASS A: countdown 3->2->1->0 (SUB/JZ/JMP loop) ----
        waitForPC(16'h0010, 20);                 // JMP DEMO2 taken
        expect16(uut.reg_file_inst.reg_out_0, 16'h0000, "countdown R0 final");
        expect16(uut.pc_out,                  16'h0010, "PC jumped to DEMO2");

        // ---- PASS B: CALL/RET + memory + GPIO + stack + HALT ----
        waitForPC(16'h001D, 60);                 // HALT word parks the PC
        expect16(uut.reg_file_inst.reg_out_3, 16'h0035, "R3 from ADD_ROUTINE via CALL/RET");
        expect16(uut.ram_inst.ram[16'hFF00],  16'h0035, "ram[0xFF00] written by STORE");
        expect16(uut.leds,                    16'h000A, "GPIO LEDs from MMIO STORE");
        expect16(uut.reg_file_inst.reg_out_5, 16'h0000, "R5 restored by POP");
        expect16(uut.sp,                      16'hFFFE, "SP back to reset value");
        expect16(uut.pc_out,                  16'h001D, "PC parked at HALT (word 29)");

        repeat (10) @(posedge clk);
        expect16(uut.pc_out,                  16'h001D, "PC still parked after idle");

        if (errors == 0) $display("\n*** ALL TESTS PASSED ***\n");
        else             $display("\n*** %0d TEST(S) FAILED ***\n", errors);
        $finish;
    end
endmodule
