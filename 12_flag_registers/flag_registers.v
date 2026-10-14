module flags_register(
    input wire clk,
    input wire rst,
    input wire zero_in,
    input wire carry_in,
    input wire overflow_in,
    input wire negative_in,
    output reg zero_out,
    output reg carry_out,
    output reg overflow_out,
    output reg negative_out
);
always @(posedge clk or posedge rst) begin
    if(rst) begin
        zero_out <= 1'b0;
        carry_out <= 1'b0;
        overflow_out <= 1'b0;
        negative_out <= 1'b0;
    end
    else begin
        zero_out <= zero_in;
        carry_out <= carry_in;
        overflow_out <= overflow_in;
        negative_out <= negative_in;
    end
end
endmodule
