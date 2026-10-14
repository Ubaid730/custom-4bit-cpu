`timescale 1ns/1ps
module tb_dbg();
    reg clk=0, rst=1;
    cpu_top uut(.clk(clk), .rst(rst));
    always #5 clk = ~clk;
    integer i;
    initial begin
        #25 rst=0;
        for (i=0; i<40; i=i+1) begin
            #10;
            $display("cyc%0d PC=%h IN=%h R0=%h sp=%h ramaddr=%h rdo=%h push=%b pop=%b we=%b",
                i, uut.pc_out, uut.instruction, uut.reg_file_inst.reg_out_0,
                uut.sp, uut.ram_addr, uut.ram_data_out,
                uut.stack_push, uut.stack_pop, uut.actual_ram_write_enable);
        end
        $finish;
    end
endmodule
