module alu(
    input[3:0] a,
    input[3:0] b,
    input[1:0] opcode,
    output reg[3:0] result,
    output zero_flag
);
wire[3:0] math_result;
wire math_cout;
wire sub_ctrl = opcode[0];

adder_subtractor math_unit(
    .a(a),
    .b(b),
    .sub(sub_ctrl),
    .sum(math_result),
    .cout(math_cout)
);

always @(*) begin
    case(opcode)
        2'b00:result = math_result;
        2'b01:result = math_result;
        2'b10:result = a&b;
        2'b11:result = a|b;
        default:result = 4'b0000;
    endcase
end
assign zero_flag = (result == 4'b0000);
endmodule