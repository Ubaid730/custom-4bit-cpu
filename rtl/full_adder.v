module full_adder(input a,input b,input cin,output s,output c);
wire temp_sum,carry1,carry2;
half_adder ha1 (
    .A(a),
    .B(b),
    .S(temp_sum),
    .C(carry1)
);
half_adder ha2(
    .A(cin),
    .B(temp_sum),
    .S(s),
    .C(carry2)
);
assign c = carry1|carry2;
endmodule