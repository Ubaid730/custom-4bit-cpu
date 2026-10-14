module register(
    input wire clk,
    input wire rst,
    input wire we,
    input wire[15:0] data_in,
    output reg[15:0] data_out
);

always @(posedge clk or posedge rst) begin
    if(rst) begin
        data_out <= 16'b0000000000000000;
    end
    else if(we) begin
        data_out<=data_in;
    end
end
endmodule
