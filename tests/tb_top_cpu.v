`timescale 1ns/1ps

module tb_cpu_top();

    reg clk;
    reg rst;

    cpu_top uut (
        .clk(clk),
        .rst(rst)
    );

    // Watch the countdown loop: R0 should go 3 -> 2 -> 1 -> 0 and then PC parks at 5
    initial begin
        $dumpfile("cpu_dump.vcd");
        $dumpvars(0, tb_cpu_top);

        clk = 0;
        rst = 1;
        #25;
        rst = 0;

        // peek after every clock edge for a while
        #30;  $display("t=%0t PC=%h instr=%h R0=%h", $time, uut.pc_out, uut.instruction, uut.reg_file_inst.reg_out_0);
        #60;  $display("t=%0t PC=%h instr=%h R0=%h", $time, uut.pc_out, uut.instruction, uut.reg_file_inst.reg_out_0);
        #60;  $display("t=%0t PC=%h instr=%h R0=%h", $time, uut.pc_out, uut.instruction, uut.reg_file_inst.reg_out_0);
        #60;  $display("t=%0t PC=%h instr=%h R0=%h", $time, uut.pc_out, uut.instruction, uut.reg_file_inst.reg_out_0);
        #60;  $display("t=%0t PC=%h instr=%h R0=%h", $time, uut.pc_out, uut.instruction, uut.reg_file_inst.reg_out_0);
        #60;  $display("t=%0t PC=%h instr=%h R0=%h", $time, uut.pc_out, uut.instruction, uut.reg_file_inst.reg_out_0);
        #60;  $display("t=%0t PC=%h instr=%h R0=%h", $time, uut.pc_out, uut.instruction, uut.reg_file_inst.reg_out_0);
        #60;  $display("t=%0t PC=%h instr=%h R0=%h", $time, uut.pc_out, uut.instruction, uut.reg_file_inst.reg_out_0);
        #60;  $display("t=%0t PC=%h instr=%h R0=%h (expect PC=0005 R0=0000)", $time, uut.pc_out, uut.instruction, uut.reg_file_inst.reg_out_0);

        $finish;
    end

    always #5 clk = ~clk;

endmodule
