`timescale 1ns/1ps
// tb_full_cpu.v - regression testbench for the 16-bit CPU.
// Runs two programs out of roms/test_program.v:
//   PASS A (addr 0..6):  countdown 3->2->1->0 with SUB/JZ/JMP (flag timing!)
//   PASS B (addr 16..):  CALL/RET, STORE/LOAD round-trip, GPIO MMIO, PUSH/POP
module tb_full_cpu();

    reg clk;
    reg rst;

    integer errors = 0;

    cpu_top uut (
        .clk(clk),
        .rst(rst),
        .rx_in(1'b1)
    );

    always #5 clk = ~clk;

    task expect16(input [15:0] got, input [15:0] want, input [8*40:1] name);
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
        $dumpfile("full_cpu.vcd");
        $dumpvars(0, tb_full_cpu);

        clk = 0;
        rst = 1;
        #25;
        rst = 0;

        // ---------- PASS A: countdown ----------
        // 5 cycles: LI R0 / LI R1 / SUB (R0=2) / JZ untaken / JMP LOOP.
        // The register file writes on the clock edge and tb samples right
        // after posedge, so read the value BEFORE the next edge (#9, not #10).
        #45;
        expect16(uut.reg_file_inst.reg_out_0, 16'h0002, "countdown R0 mid-loop");
        expect16(uut.pc_out,                  16'h0004, "PC back at LOOP via JMP");

        // ---------- PASS B: CALL/RET + memory + GPIO + stack ----------
        // program finishes (HALT parks PC at word 29) by ~t=115; wait well past it
        #300;
        expect16(uut.reg_file_inst.reg_out_3, 16'h0035, "R3 after STORE/LOAD roundtrip");
        expect16(uut.leds,               16'h000A, "GPIO LEDs from MMIO STORE");
        expect16(uut.reg_file_inst.reg_out_5, 16'h0000, "R5 restored by POP");
        expect16(uut.sp,                      16'hFFFE, "SP back to reset value");
        expect16(uut.pc_out,                  16'h001D, "PC parked at HALT (word 29)");

        if (errors == 0)
            $display("\n*** ALL TESTS PASSED ***\n");
        else
            $display("\n*** %0d TEST(S) FAILED ***\n", errors);

        $finish;
    end

endmodule
