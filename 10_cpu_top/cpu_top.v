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
    wire [1:0] alu_ctrl;       
    wire [3:0] reg_data_a;     
    wire [3:0] reg_data_b;     
    wire [3:0] alu_result;
    wire zero_flag;         

    wire[3:0] ram_addr;
    wire[3:0] ram_data_in;
    wire[3:0] ram_data_out;   

    assign opcode   = instruction[7:4];
    assign dest_reg = instruction[3:2];
    assign src_reg  = instruction[1:0];

    program_counter pc_inst (
        .clk(clk), 
        .rst(rst),
        .next_pc(pc_out + 4'b0001), 
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
        .alu_ctrl(alu_ctrl)
    );

    register_file reg_file_inst (
        .clk(clk), 
        .rst(rst),
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
        .zero_flag(zero_flag)
    );
    assign ram_addr = reg_data_b;
    assign ram_data_in = reg_data_a;
        data_memory ram_inst (
        .clk(clk),
        .write_enable(mem_write_enable),
        .addr(ram_addr),
        .data_in(ram_data_in),
        .data_out(ram_data_out)
    );
    wire[3:0] reg_file_data_in;
    assign reg_file_data_in = (opcode == 4'b0101) ? {2'b00, src_reg} :  // LI
                              (opcode == 4'b0110) ? ram_data_out :      // LOAD
                              alu_result;                               // Default (ADD, SUB, etc.)

endmodule