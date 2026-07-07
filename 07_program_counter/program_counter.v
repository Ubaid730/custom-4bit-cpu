module program_counter(
    input wire clk,
    input wire rst,
    input wire[3:0] next_pc,
    output reg[3:0] pc
);
always @(posedge clk or posedge rst) begin
    if(rst)begin
        pc <= 4'b0000;
    end
    else begin
        pc <= next_pc;
    end
end
endmodule