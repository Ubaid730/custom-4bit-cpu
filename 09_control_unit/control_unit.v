module control_unit(
    input wire[3:0] opcode,
    output reg reg_write_enable,
    output reg mem_write_enable,
    
    output reg[1:0] alu_ctrl,
    output reg[1:0] pc_source,
    output reg stack_push,
    output reg stack_pop
);
    always @(*) begin
        
        reg_write_enable = 1'b0;
        mem_write_enable = 1'b0; 
        
        alu_ctrl = 2'b00;
        pc_source = 2'b00;
        stack_pop = 1'b0;
        stack_push = 1'b0;

        
        case(opcode)
            4'b0000: begin // NOP
                
            end
            4'b0001: begin // ADD
                reg_write_enable = 1'b1;
                alu_ctrl = 2'b00;
            end
            4'b0010: begin // SUB
                reg_write_enable = 1'b1;
                alu_ctrl = 2'b01;
            end
            4'b0011: begin // AND
                reg_write_enable = 1'b1;
                alu_ctrl = 2'b10;
            end
            4'b0100: begin // OR
                reg_write_enable = 1'b1;
                alu_ctrl = 2'b11;
            end
            4'b0101: begin // LI
                reg_write_enable = 1'b1;
            end
            4'b0110: begin // LOAD
                reg_write_enable = 1'b1;
            end
            4'b0111: begin // STORE
                mem_write_enable = 1'b1;
            end
            4'b1000: begin // JMP
                pc_source = 2'b01;
            end
            4'b1001: begin // JZ
                pc_source = 2'b01;
            end
            4'b1010: begin // push
                mem_write_enable = 1'b1;
                stack_push = 1'b1;
            end
            4'b1011: begin // pop
                reg_write_enable = 1'b1;
                stack_pop = 1'b1;
                
            end
            4'b1100: begin // CALL
                mem_write_enable = 1'b1; 
                stack_push = 1'b1;      
                pc_source = 2'b01;       
            end

            4'b1101: begin // RET
                stack_pop = 1'b1;        
                pc_source = 2'b10;       
            end
            default: begin
                // Defaults apply
            end
        endcase
    end
endmodule