`timescale 1ns/1ps

module tb_register_file();
    reg clk, rst, write_enable_global;
    reg [1:0] write_addr, read_addr_a, read_addr_b;
    reg [3:0] data_in;
    wire [3:0] data_out_a, data_out_b;

    register_file uut (
        .clk(clk), .rst(rst), 
        .write_enable_global(write_enable_global),
        .write_addr(write_addr), .data_in(data_in),
        .read_addr_a(read_addr_a), .data_out_a(data_out_a),
        .read_addr_b(read_addr_b), .data_out_b(data_out_b)
    );

    initial begin clk = 0; forever #5 clk = ~clk; end

    initial begin
        $dumpfile("reg_file.vcd");
        $dumpvars(0, tb_register_file);
        
        rst = 1; #10; rst = 0;
        
        // Write 7 into Register 1 (Address 01)
        write_enable_global = 1; write_addr = 2'b01; data_in = 4'b0111; #10;
        write_enable_global = 0; #10;

        // Read Register 1 into Output A and Register 0 into Output B
        read_addr_a = 2'b01; read_addr_b = 2'b00; #10;

        // Write 12 into Register 3 (Address 11)
        write_enable_global = 1; write_addr = 2'b11; data_in = 4'b1100; #10;
        write_enable_global = 0; #10;

        // Read Register 3 into Output A and Register 1 into Output B
        read_addr_a = 2'b11; read_addr_b = 2'b01; #20;
        
        $finish;
    end
endmodule