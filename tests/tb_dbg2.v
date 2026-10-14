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
        for (i=0; i<8; i=i+1) begin
            @(posedge clk); #1;
            $display("cyc%0d PC=%h IN=%h R3=%h R4=%h R8=%h ramaddr=%h rdo=%h rwe=%b aluB=%h aluR=%h bypass=%h",
                i, uut.pc_out, uut.instruction,
                uut.reg_file_inst.reg_out_3, uut.reg_file_inst.reg_out_4,
                uut.reg_file_inst.reg_out_8,
                uut.ram_addr, uut.ram_data_out, uut.ram_inst.write_enable,
                uut.alu_b, uut.alu_result, uut.src2_bypassed);
        end
        $finish;
    end
endmodule
