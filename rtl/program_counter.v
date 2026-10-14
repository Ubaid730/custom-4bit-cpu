module program_counter(
    input wire clk,
    input wire rst,
    input wire[15:0] next_pc,
    output reg[15:0] pc
);
always @(posedge clk or posedge rst) begin
    if(rst)begin
        pc <= 16'b0000000000000000;
    end
    else begin
        pc <= next_pc;
    end
end
endmodule
