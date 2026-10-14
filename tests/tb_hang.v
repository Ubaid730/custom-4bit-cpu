`timescale 1ns/100ps
module tb_hang();
    reg clk=0, rst;
    cpu_top uut(.clk(clk), .rst(rst), .rx_in(1'b1));
    always #5 clk = ~clk;
    integer i;
    initial begin
        rst=1; #25; rst=0;
        for (i=0; i<80; i=i+1) begin
            @(posedge clk);
            $display("t=%0t PC=%h ir_op=%h R0=%h R3=%h sp=%h leds=%h halt=%b ramwe=%b push=%b pop=%b",
              $time, uut.pc_out, uut.ir_opcode,
              uut.reg_file_inst.reg_out_0, uut.reg_file_inst.reg_out_3,
              uut.sp, uut.leds, uut.halted_q,
              uut.ram_write_g, uut.stack_push_g, uut.stack_pop_g);
        end
        $finish;
    end
endmodule
