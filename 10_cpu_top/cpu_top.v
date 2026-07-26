module cpu_top(
    input wire clk,
    input wire rst
);

    
    wire [3:0] pc_out;
    wire [7:0] instruction;
    wire [3:0] opcode;
    wire [1:0] dest_reg;
    wire [1:0] src_reg;
    wire reg_write_enable;
    wire mem_write_enable;
    wire mem_to_reg;
    wire [1:0] alu_ctrl;
    wire [1:0] pc_source_cu; 
    wire [3:0] reg_data_a;
    wire [3:0] reg_data_b;
    wire [3:0] alu_result;
    
    
    wire zero_flag_raw;
    wire zero_flag_stored;
    
    wire gpio_write_enable;
    wire actual_ram_write_enable;
    wire stack_push;
    wire stack_pop;
    wire [3:0] ram_addr;
    wire [3:0] ram_data_in;
    wire [3:0] ram_data_out;
    wire [3:0] reg_file_data_in;

    assign opcode   = instruction[7:4];
    assign dest_reg = instruction[3:2];
    assign src_reg  = instruction[1:0];
    // assign gpio_write_enable = mem_write_enable & (ram_addr == 4'b1111);
    // assign actual_ram_write_enable = mem_write_enable & (ram_addr != 4'b1111);
    wire ram_re,ram_we,gpio_re,gpio_we,uart_we;
    wire tx_busy;
    wire is_read_op = (opcode == 4'b0110) || (opcode == 4'b1011);
    wire [3:0] gpio_leds;
    wire [3:0] next_pc_val;
    wire [3:0] sp;
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
        .stack_pop(stack_pop),
        .stack_push(stack_push)

    );

    register_file reg_file_inst (
        .clk(clk), .rst(rst),
        .write_enable_global(reg_write_enable),
        .write_addr(dest_reg),
        .data_in(reg_file_data_in),
        .read_addr_a(dest_reg),
        .data_out_a(reg_data_a),
        .read_addr_b(src_reg),
        .data_out_b(reg_data_b)
    );


    alu alu_inst (
        .a(reg_data_a),
        .b(reg_data_b),
        .opcode(alu_ctrl),
        .result(alu_result),
        .zero_flag(zero_flag_raw)
    );

    flags_register flags_inst (
        .clk(clk), .rst(rst),
        .zero_in(zero_flag_raw),
        .zero_out(zero_flag_stored)
    );
    gpio gpio_inst(
        .clk(clk),
        .rst(rst),
        .write_enable(gpio_write_enable),
        .data_in(ram_data_in),
        .leds(gpio_leds)
    );

    //assign ram_addr = reg_data_b;
    assign ram_addr = stack_push ? sp : stack_pop ? (sp+4'b0001) : reg_data_b;
    assign ram_data_in = (opcode == 4'b1100) ? (pc_out + 4'b0001) : 
                     stack_push ? reg_data_b :                    
                     reg_data_a;
    
    data_memory ram_inst (
        .clk(clk),
        .write_enable(ram_we),
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


    assign reg_file_data_in = (opcode == 4'b0101) ? {2'b00, src_reg} :  
                              (opcode == 4'b0110 || opcode == 4'b1011) ?
                              (ram_addr == 4'b1111 ? gpio_leds : ram_data_out) :      
                              alu_result;                               

    wire [3:0] jump_addr = {dest_reg, src_reg}; 

 assign next_pc_val = (pc_source_cu == 2'b10) ? ram_data_out : // If RET, load PC from RAM
                     (pc_source_cu == 2'b01 && !(opcode == 4'b1001 && !zero_flag_stored)) ? jump_addr : 
                     (pc_out + 4'b0001);

endmodule