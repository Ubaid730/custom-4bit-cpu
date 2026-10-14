module adder_subtractor_16bit(
    input[15:0] a,
    input[15:0] b,
    input sub,
    output[15:0] sum,
    output cout
);

wire[15:0] b_modified;
assign b_modified = b^{16{sub}};
sixteen_bit_full_adder our_adder(
    .a(a),
    .b(b_modified),
    .cin(sub),
    .sum(sum),
    .cout(cout)
);
endmodule
