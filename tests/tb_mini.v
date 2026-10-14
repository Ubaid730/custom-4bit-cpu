`timescale 1ns/1ps
module tb_mini();
    reg clk, rst;
    cpu_top uut (.clk(clk), .rst(rst));
    always #5 clk = ~clk;
    initial begin
        clk=0; rst=1; #25; rst=0;
        $monitor($time,, " PC=%h instr=%h op=%h imm=%h ris=%h rwe=%h wb=%h R0=%h",
            uut.pc_out, uut.instruction, uut.opcode, uut.immediate,
            uut.reg_in_source, uut.reg_write_g, uut.reg_file_data_in,
            uut.reg_file_inst.reg_out_0);
        #100; $finish;
    end
endmodule
