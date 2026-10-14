module cpu_top(
    input wire clk,
    input wire rst
);


    wire [15:0] pc_out;
    wire [31:0] instruction;
    wire [7:0] opcode;
    wire [3:0] dest_reg;
    wire [3:0] src_reg;
    wire [3:0] src2_reg;
    wire [15:0] immediate;
    wire reg_write_enable;
    wire mem_write_enable;
    wire [2:0] alu_ctrl;
    wire [1:0] pc_source_cu;
    wire [1:0] reg_in_source;
    wire [15:0] reg_data_a;
    wire [15:0] reg_data_b;
    wire [15:0] reg_data_c;
    wire [15:0] alu_result;


    wire zero_flag_raw;
    wire carry_flag_raw;
    wire overflow_flag_raw;
    wire negative_flag_raw;
    wire zero_flag_stored;
    wire carry_flag_stored;
    wire overflow_flag_stored;
    wire negative_flag_stored;

    wire gpio_write_enable;
    wire actual_ram_write_enable;
    wire stack_push;
    wire stack_pop;
    wire [15:0] ram_addr;
    wire [15:0] ram_data_in;
    wire [15:0] ram_data_out;
    wire [15:0] reg_file_data_in;

    assign opcode   = instruction[31:24];
    assign dest_reg = instruction[19:16];
    assign src_reg  = instruction[15:12];
    assign src2_reg = instruction[11:8];
    assign immediate = instruction[15:0];
    wire ram_re,ram_we,gpio_re,gpio_we,uart_we;
    wire tx_busy;
    // LOAD and POP read from memory on the same cycle they execute
    wire is_read_op = (opcode == 8'h11) || (opcode == 8'h31);
    wire [15:0] gpio_leds;
    wire [15:0] next_pc_val;
    wire [15:0] sp;
    program_counter pc_inst (
        .clk(clk), .rst(rst),
        .next_pc(next_pc_val),
        .pc(pc_out)
    );

    instruction_memory rom_inst (
        .addr(pc_out),
        .instruction(instruction)
    );

    control_unit cu_inst (
        .opcode(opcode),
        .reg_write_enable(reg_write_enable),
        .mem_write_enable(mem_write_enable),
        .alu_ctrl(alu_ctrl),
        .pc_source(pc_source_cu),
        .reg_in_source(reg_in_source),
        .stack_pop(stack_pop),
        .stack_push(stack_push)

    );

    register_file reg_file_inst (
        .clk(clk), .rst(rst),
        .write_enable_global(reg_write_enable),
        .write_addr(dest_reg),
        .data_in(reg_file_data_in),
        .read_addr_a(src_reg),
        .data_out_a(reg_data_a),
        .read_addr_b(src2_reg),
        .data_out_b(reg_data_b),
        .read_addr_c(dest_reg),
        .data_out_c(reg_data_c)
    );


    // ALU operand B comes from the right place depending on the instruction type:
    // LI/JMP/jumps -> the 16-bit immediate field
    // STORE/LOAD/PUSH/POP/CALL/RET -> R[src2] (the address lives there)
    // everything else (ADD/SUB/AND...) -> R[src2] as the second operand too
    wire [15:0] alu_b = (reg_in_source == 2'b01) | (pc_source_cu != 2'b00) ? immediate : reg_data_b;

    alu alu_inst (
        .a(reg_data_a),
        .b(alu_b),
        .opcode(alu_ctrl),
        .result(alu_result),
        .zero_flag(zero_flag_raw),
        .carry_flag(carry_flag_raw),
        .overflow_flag(overflow_flag_raw),
        .negative_flag(negative_flag_raw)
    );

    flags_register flags_inst (
        .clk(clk), .rst(rst),
        .zero_in(zero_flag_raw),
        .carry_in(carry_flag_raw),
        .overflow_in(overflow_flag_raw),
        .negative_in(negative_flag_raw),
        .zero_out(zero_flag_stored),
        .carry_out(carry_flag_stored),
        .overflow_out(overflow_flag_stored),
        .negative_out(negative_flag_stored)
    );
    gpio gpio_inst(
        .clk(clk),
        .rst(rst),
        .write_enable(gpio_write_enable),
        .data_in(ram_data_in),
        .leds(gpio_leds)
    );

    // Memory addressing:
    //   PUSH/CALL -> write at SP (before it decrements)
    //   POP/RET   -> read at SP+1 (the value pushed last)
    //   STORE     -> R[src2] holds the address, R[src] holds the data
    //   LOAD      -> R[src2] holds the address, result goes to R[dest]
    assign ram_addr = stack_push ? sp :
                      stack_pop  ? (sp + 16'b1) :
                      reg_data_b;
    assign ram_data_in = (opcode == 8'h32) ? (pc_out + 16'b1) :  // CALL pushes return address
                     stack_push ? reg_data_a :                   // PUSH R[src] onto the stack
                     reg_data_a;                                 // STORE R[src] -> [R src2]

    data_memory ram_inst (
        .clk(clk),
        .write_enable(actual_ram_write_enable),
        .addr(ram_addr),
        .data_in(ram_data_in),
        .data_out(ram_data_out)
    );
    stack_pointer sp_inst(
        .clk(clk),
        .rst(rst),
        .push(stack_push),
        .pop(stack_pop),
        .sp(sp)
    );
    mmio_decoder mmio_inst(
    .addr(ram_addr),
    .mem_write(mem_write_enable),
    .mem_read(is_read_op),
    .ram_we(actual_ram_write_enable),
    .ram_re(ram_re),
    .gpio_we(gpio_write_enable),
    .gpio_re(gpio_re),
    .uart_we(uart_we)
    );
    uart_tx uart_inst(
    .clk(clk),
    .rst(rst),
    .tx_start(uart_we),
    .tx_data(ram_data_in),
    .tx_out(),
    .tx_busy(tx_busy)
);


    assign reg_file_data_in = (reg_in_source == 2'b01) ? immediate :
                              (reg_in_source == 2'b10) ?
                              ((ram_addr >= 16'hFFF0 && ram_addr <= 16'hFFFA) ? gpio_leds : ram_data_out) :
                              alu_result;

    wire [15:0] jump_addr = immediate;

    // Which conditional jumps actually take the branch?
    wire cond_true = (opcode == 8'h21) ? zero_flag_raw :         // JZ
                     (opcode == 8'h22) ? ~zero_flag_raw :        // JNZ
                     (opcode == 8'h23) ? carry_flag_raw :        // JC
                     (opcode == 8'h24) ? ~carry_flag_raw :       // JNC
                     (opcode == 8'h25) ? negative_flag_raw :     // JN
                     (opcode == 8'h26) ? ~negative_flag_raw :    // JNN
                                         1'b1;                   // JMP always jumps

 assign next_pc_val = (pc_source_cu == 2'b10) ? ram_data_out : // If RET, load PC from RAM
                     (pc_source_cu == 2'b01 && cond_true) ? jump_addr :
                     (pc_out + 16'b1);

endmodule
