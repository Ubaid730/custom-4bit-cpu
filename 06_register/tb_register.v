`timescale 1ns/1ps

module tb_register_16bit();
    reg clk;
    reg rst;
    reg write_enable;
    reg [15:0] data_in;
    wire [15:0] data_out;

    // Instantiate the Unit Under Test (UUT)
    register uut (
        .clk(clk),
        .rst(rst),
        .we(write_enable),
        .data_in(data_in),
        .data_out(data_out)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("register.vcd");
        $dumpvars(0, tb_register_16bit);

        rst = 1; write_enable = 0; data_in = 16'h0000; #12;
        rst = 0;

        // Write 0xDEAD
        write_enable = 1; data_in = 16'hDEAD; #10;
        write_enable = 0; #10;

        // Try to write while WE off - should hold 0xDEAD
        data_in = 16'hBEEF; #10;

        // Write 0xBEEF for real
        write_enable = 1; #10;
        write_enable = 0; #10;

        // Reset should clear it back to zero
        rst = 1; #10;
        rst = 0; #10;

        $display("Final data_out = %h (expect 0000 after reset)", data_out);
        $finish;
    end
endmodule
