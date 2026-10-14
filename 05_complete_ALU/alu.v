module alu(
    input[15:0] a,
    input[15:0] b,
    input[2:0] opcode,
    output reg[15:0] result,
    output zero_flag,
    output carry_flag,
    output overflow_flag,
    output negative_flag
);
wire[15:0] math_result;
wire math_cout;
// Opcode 0xx = ADD/SUB (math), everything else is bitwise or shift
wire math_op = ~opcode[2];
wire sub_ctrl = opcode[0];

adder_subtractor_16bit math_unit(
    .a(a),
    .b(b),
    .sub(sub_ctrl),
    .sum(math_result),
    .cout(math_cout)
);

always @(*) begin
    case(opcode)
        3'b000:result = math_result;      // ADD
        3'b001:result = math_result;      // SUB
        3'b010:result = a&b;              // AND
        3'b011:result = a|b;              // OR
        3'b100:result = ~(a&b);           // NAND
        3'b101:result = a^b;              // XOR
        3'b110:result = {a[14:0], 1'b0};  // SHIFT LEFT
        3'b111:result = {1'b0, a[15:1]};  // SHIFT RIGHT (logical)
        default:result = 16'h0000;
    endcase
end

assign zero_flag = (result == 16'h0000);
assign negative_flag = result[15];
// Carry only meaningful for ADD/SUB
assign carry_flag = math_op ? math_cout : 1'b0;
// Signed overflow: pos+pos=neg or neg+neg=pos (ADD/SUB only)
wire signed_overflow = (~a[15] & ~b[15] & math_result[15]) |
                       ( a[15] &  b[15] & ~math_result[15]);
assign overflow_flag = math_op ? signed_overflow : 1'b0;
endmodule
