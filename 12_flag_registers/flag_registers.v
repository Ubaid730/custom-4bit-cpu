module flags_register(
    input wire clk,
    input wire rst,
    input wire zero_in,
    output reg zero_out
);
always @(posedge clk or posedge rst) begin
    if(rst) begin
        zero_out <= 1'b0;
    end
    else begin
        zero_out <= zero_in;
    end
end
endmodule
