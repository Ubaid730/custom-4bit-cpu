module stack_pointer(
    input wire clk,
    input wire rst,
    input wire push,
    input wire pop, 
    output reg [3:0] sp 
);

always @(posedge clk or posedge rst) begin
    if(rst)begin
        sp <= 4'b1111;
end
else if(push == 1'b1)begin
    sp <= sp-1;
end
else if(pop == 1'b1)begin
    sp <= sp+1;
end
end

endmodule