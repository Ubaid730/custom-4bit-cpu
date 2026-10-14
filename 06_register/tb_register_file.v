`timescale 1ns/1ps

module tb_register_file();
    reg clk, rst, write_enable_global;
    reg [3:0] write_addr, read_addr_a, read_addr_b, read_addr_c;
    reg [15:0] data_in;
    wire [15:0] data_out_a, data_out_b, data_out_c;

    register_file uut (
        .clk(clk), .rst(rst),
        .write_enable_global(write_enable_global),
        .write_addr(write_addr), .data_in(data_in),
        .read_addr_a(read_addr_a), .data_out_a(data_out_a),
        .read_addr_b(read_addr_b), .data_out_b(data_out_b),
        .read_addr_c(read_addr_c), .data_out_c(data_out_c)
    );

    initial begin clk = 0; forever #5 clk = ~clk; end

    initial begin
        $dumpfile("reg_file.vcd");
        $dumpvars(0, tb_register_file);

        rst = 1; #10; rst = 0;

        // Write 0x0007 into Register 1 (Address 0001)
        write_enable_global = 1; write_addr = 4'b0001; data_in = 16'h0007; #10;
        write_enable_global = 0; #10;

        // Read Register 1 into Output A and Register 0 into Output B
        read_addr_a = 4'b0001; read_addr_b = 4'b0000; read_addr_c = 4'b0001; #10;

        // Write 0xC0DE into Register 15 (Address 1111)
        write_enable_global = 1; write_addr = 4'b1111; data_in = 16'hC0DE; #10;
        write_enable_global = 0; #10;

        // Read Register 15 into Output A, Register 1 into B, Register 15 into C
        read_addr_a = 4'b1111; read_addr_b = 4'b0001; read_addr_c = 4'b1111; #20;

        $display("A = %h (expect c0de), B = %h (expect 0007), C = %h (expect c0de)", data_out_a, data_out_b, data_out_c);
        $finish;
    end
endmodule
