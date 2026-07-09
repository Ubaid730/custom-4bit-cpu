module control_unit(
    input wire[3:0] opcode,
    output reg reg_write_enable,
    output reg mem_write_enable,
    output reg[1:0] alu_ctrl
);
always @(*)begin
    reg_write_enable = 1'b0;
    alu_ctrl = 2'b00;
    case(opcode)
        4'b0000:begin
            reg_write_enable = 1'b1;
            alu_ctrl = 2'b00;
        end
        4'b0001:begin
            reg_write_enable = 1'b1;
            alu_ctrl = 2'b00;
        end
        4'b0010:begin
            reg_write_enable = 1'b1;
            alu_ctrl = 2'b01;
        end
        4'b0011:begin
            reg_write_enable = 1'b1;
            alu_ctrl = 2'b10;
        end
        4'b0100:begin
            reg_write_enable = 1'b1;
            alu_ctrl = 2'b11;
        end
        4'b0101:begin
            reg_write_enable = 1'b1;
            mem_write_enable = 1'b0;
            alu_ctrl = 2'b00;
        end
        4'b0110:begin
            reg_write_enable = 1'b1;
            mem_write_enable = 1'b0;
            alu_ctrl = 2'b00;
        end
        4'b0111:begin
            reg_write_enable = 1'b0;
            mem_write_enable = 1'b1;
            alu_ctrl = 2'b00;
        end
        default: begin
                reg_write_enable = 1'b0;
                mem_write_enable = 1'b0;
                alu_ctrl = 2'b00;
            end
    endcase
    end

endmodule