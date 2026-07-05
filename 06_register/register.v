module register(
    input wire clk,
    input wire rst,
    input wire we,
    input wire[3:0] data_in,
    output reg[3:0] data_out
);

always @(posedge clk or posedge rst) begin
    if(rst) begin
        data_out <= 4'b0000;
    end
    else if(we) begin
        data_out<=data_in;
    end
end
endmodule