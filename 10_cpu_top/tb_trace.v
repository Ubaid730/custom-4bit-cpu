`timescale 1ns/1ps
module tb_trace();
    reg clk, rst;
    cpu_top uut (.clk(clk), .rst(rst));
    always #5 clk = ~clk;
    initial begin
        clk=0; rst=1; #25; rst=0;
        $monitor($time,, " PC=%h op=%h R0=%h R3=%h R5=%h Z=%h sp=%h leds=%h ram_addr=%h ram_we=%b ram_do=%h retq=%h",
            uut.pc_out, uut.opcode,
            uut.reg_file_inst.reg_out_0, uut.reg_file_inst.reg_out_3, uut.reg_file_inst.reg_out_5,
            uut.flags_inst.zero_out, uut.sp, uut.gpio_leds,
            uut.ram_addr, uut.ram_inst.write_enable, uut.ram_data_out,
            uut.data_memory.ram[uut.ram_addr]);
        #600; $finish;
    end
endmodule
