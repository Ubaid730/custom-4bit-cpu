module control_unit(
    input wire[7:0] opcode,
    output reg reg_write_enable,
    output reg mem_write_enable,

    output reg[2:0] alu_ctrl,
    output reg[1:0] pc_source,
    output reg[1:0] reg_in_source,   // 00 = ALU, 01 = immediate, 10 = RAM/MMIO read
    output reg stack_push,
    output reg stack_pop
);
    always @(*) begin

        reg_write_enable = 1'b0;
        mem_write_enable = 1'b0;

        alu_ctrl = 3'b000;
        pc_source = 2'b00;
        reg_in_source = 2'b00;
        stack_pop = 1'b0;
        stack_push = 1'b0;


        case(opcode)
            8'h00: begin // NOP

            end
            8'h01: begin // ADD
                reg_write_enable = 1'b1;
                alu_ctrl = 3'b000;
            end
            8'h02: begin // SUB
                reg_write_enable = 1'b1;
                alu_ctrl = 3'b001;
            end
            8'h03: begin // AND
                reg_write_enable = 1'b1;
                alu_ctrl = 3'b010;
            end
            8'h04: begin // OR
                reg_write_enable = 1'b1;
                alu_ctrl = 3'b011;
            end
            8'h05: begin // NAND
                reg_write_enable = 1'b1;
                alu_ctrl = 3'b100;
            end
            8'h06: begin // XOR
                reg_write_enable = 1'b1;
                alu_ctrl = 3'b101;
            end
            8'h07: begin // SHL
                reg_write_enable = 1'b1;
                alu_ctrl = 3'b110;
            end
            8'h08: begin // SHR
                reg_write_enable = 1'b1;
                alu_ctrl = 3'b111;
            end
            8'h09: begin // CMP (SUB but nobody writes the result!)
                alu_ctrl = 3'b001;
            end
            8'h10: begin // LI
                reg_write_enable = 1'b1;
                reg_in_source = 2'b01;
            end
            8'h11: begin // LOAD
                reg_write_enable = 1'b1;
                reg_in_source = 2'b10;
            end
            8'h12: begin // STORE
                mem_write_enable = 1'b1;
            end
            8'h20: begin // JMP
                pc_source = 2'b01;
            end
            8'h21: begin // JZ
                pc_source = 2'b01;
            end
            8'h22: begin // JNZ
                pc_source = 2'b01;
            end
            8'h23: begin // JC
                pc_source = 2'b01;
            end
            8'h24: begin // JNC
                pc_source = 2'b01;
            end
            8'h25: begin // JN
                pc_source = 2'b01;
            end
            8'h26: begin // JNN
                pc_source = 2'b01;
            end
            8'h30: begin // push
                mem_write_enable = 1'b1;
                stack_push = 1'b1;
            end
            8'h31: begin // pop
                reg_write_enable = 1'b1;
                reg_in_source = 2'b10;
                stack_pop = 1'b1;

            end
            8'h32: begin // CALL
                mem_write_enable = 1'b1;
                stack_push = 1'b1;
                pc_source = 2'b01;
            end

            8'h33: begin // RET
                stack_pop = 1'b1;
                pc_source = 2'b10;
            end
            default: begin
                // Defaults apply
            end
        endcase
    end
endmodule
