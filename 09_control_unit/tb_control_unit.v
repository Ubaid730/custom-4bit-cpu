`timescale 1ns/1ps

module tb_control_unit();

    reg [7:0] opcode;
    wire reg_write_enable;
    wire mem_write_enable;
    wire [2:0] alu_ctrl;
    wire [1:0] pc_source;
    wire [1:0] reg_in_source;
    wire stack_push;
    wire stack_pop;

    // Instantiate the Control Unit
    control_unit uut (
        .opcode(opcode),
        .reg_write_enable(reg_write_enable),
        .mem_write_enable(mem_write_enable),
        .alu_ctrl(alu_ctrl),
        .pc_source(pc_source),
        .reg_in_source(reg_in_source),
        .stack_push(stack_push),
        .stack_pop(stack_pop)
    );

    initial begin
        // Setup GTKWave dumping
        $dumpfile("control_unit_dump.vcd");
        $dumpvars(0, tb_control_unit);

        // Test Sequence
        opcode = 8'h00; #10; // NOP
        opcode = 8'h01; #10; // ADD
        opcode = 8'h02; #10; // SUB
        opcode = 8'h03; #10; // AND
        opcode = 8'h04; #10; // OR
        opcode = 8'h05; #10; // NAND
        opcode = 8'h06; #10; // XOR
        opcode = 8'h07; #10; // SHL
        opcode = 8'h08; #10; // SHR
        opcode = 8'h09; #10; // CMP
        opcode = 8'h10; #10; // LI
        opcode = 8'h11; #10; // LOAD
        opcode = 8'h12; #10; // STORE
        opcode = 8'h20; #10; // JMP
        opcode = 8'h21; #10; // JZ
        opcode = 8'h30; #10; // PUSH
        opcode = 8'h31; #10; // POP
        opcode = 8'h32; #10; // CALL
        opcode = 8'h33; #10; // RET
        opcode = 8'hFF; #10; // Invalid/Default

        $finish;
    end

endmodule
