`timescale 1ns/1ps
module tb_dbg();
    reg clk=0, rst=1;
    wire [15:0] leds;
    wire tx_out, halted;
    cpu_top uut(.clk(clk), .rst(rst), .rx_in(1'b1),
                .leds(leds), .tx_out(tx_out), .halted(halted));
    always #5 clk = ~clk;
    integer i;
    initial begin
        #25 rst=0;
        for (i=0; i<45; i=i+1) begin
            @(posedge clk); #1;
            $display("cyc%0d PC=%h IN=%h R0=%h R3=%h R5=%h sp=%h leds=%h halted=%b",
                i, uut.pc_out, uut.instruction,
                uut.reg_file_inst.reg_out_0, uut.reg_file_inst.reg_out_3,
                uut.reg_file_inst.reg_out_5, uut.sp, leds, halted);
        end
        $finish;
    end
endmodule
