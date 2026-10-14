module adder_subtractor(
    input[3:0] a,
    input[3:0] b,
    input sub,
    output[3:0] sum,
    output cout
);

wire[3:0] b_modified;
assign b_modified = b^{4{sub}};
four_bit_full_adder our_adder(
    .a(a),
    .b(b_modified),
    .cin(sub),
    .sum(sum),
    .cout(cout)
);
endmodule