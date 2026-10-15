`timescale 1ns/1ps
module tb_probe();
    reg clk, rst;
    cpu_top uut (.clk(clk), .rst(rst));
    always #5 clk = ~clk;
    initial begin
        clk=0; rst=1; #25; rst=0;
        $monitor($time,, " PC=%h instr=%h op=%h imm16=%h jump=%h R3=%h leds=%h",
            uut.pc_out, uut.instruction, uut.opcode, uut.immediate,
            uut.jump_addr, uut.reg_file_inst.reg_out_3, uut.leds);
        #400; $finish;
    end
endmodule
