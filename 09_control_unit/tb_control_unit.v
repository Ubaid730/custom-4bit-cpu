`timescale 1ns/1ps

module tb_control_unit();

    reg [3:0] opcode;
    wire reg_write_enable;
    wire [1:0] alu_ctrl;

    // Instantiate the Control Unit
    control_unit uut (
        .opcode(opcode),
        .reg_write_enable(reg_write_enable),
        .alu_ctrl(alu_ctrl)
    );

    initial begin
        // Setup GTKWave dumping
        $dumpfile("control_unit_dump.vcd");
        $dumpvars(0, tb_control_unit);

        // Test Sequence
        opcode = 4'b0000; #10; // NOP
        opcode = 4'b0001; #10; // ADD
        opcode = 4'b0010; #10; // SUB
        opcode = 4'b0011; #10; // AND
        opcode = 4'b0100; #10; // OR
        opcode = 4'b1111; #10; // Invalid/Default
        
        $finish;
    end

endmodule