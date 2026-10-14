`timescale 1ns/1ps

module tb_cpu_top();

    reg clk;
    reg rst;
    wire [15:0] leds;
    wire        tx_out;
    wire        halted;

    cpu_top uut (
        .clk(clk),
        .rst(rst),
        .rx_in(1'b1),
        .leds(leds),
        .tx_out(tx_out),
        .halted(halted)
    );

    // Watch the countdown loop: R0 should go 3 -> 2 -> 1 -> 0, branch to DONE
    // and park there. If the program ends with HALT, `halted` goes 1 and the
    // PC freezes forever (no more x-state run-away).
    initial begin
        $dumpfile("build/cpu_dump.vcd");
        $dumpvars(0, tb_cpu_top);

        clk = 0;
        rst = 1;
        #25;
        rst = 0;

        repeat (9) begin
            @(posedge clk);
            $display("t=%0t PC=%h instr=%h R0=%h halted=%b",
                     $time, uut.pc_out, uut.instruction,
                     uut.reg_file_inst.reg_out_0, halted);
        end

        // let it sit a while - PC must not move once halted
        repeat (20) @(posedge clk);
        $display("FINAL   PC=%h R0=%h halted=%b (expect PC parked, R0=0000)",
                 uut.pc_out, uut.reg_file_inst.reg_out_0, halted);
        if (halted && uut.pc_out !== 16'hxxxx) $display("TEST PASSED");
        else $display("TEST FAILED");

        $finish;
    end

    always #5 clk = ~clk;

endmodule
