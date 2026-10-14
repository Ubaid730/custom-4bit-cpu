module sixteen_bit_full_adder(
    input[15:0] a,
    input[15:0] b,
    input cin,
    output[15:0] sum,
    output cout
);
wire c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15;

full_adder fa0 (.a(a[0]),  .b(b[0]),  .cin(cin), .s(sum[0]),  .c(c1));
full_adder fa1 (.a(a[1]),  .b(b[1]),  .cin(c1),  .s(sum[1]),  .c(c2));
full_adder fa2 (.a(a[2]),  .b(b[2]),  .cin(c2),  .s(sum[2]),  .c(c3));
full_adder fa3 (.a(a[3]),  .b(b[3]),  .cin(c3),  .s(sum[3]),  .c(c4));
full_adder fa4 (.a(a[4]),  .b(b[4]),  .cin(c4),  .s(sum[4]),  .c(c5));
full_adder fa5 (.a(a[5]),  .b(b[5]),  .cin(c5),  .s(sum[5]),  .c(c6));
full_adder fa6 (.a(a[6]),  .b(b[6]),  .cin(c6),  .s(sum[6]),  .c(c7));
full_adder fa7 (.a(a[7]),  .b(b[7]),  .cin(c7),  .s(sum[7]),  .c(c8));
full_adder fa8 (.a(a[8]),  .b(b[8]),  .cin(c8),  .s(sum[8]),  .c(c9));
full_adder fa9 (.a(a[9]),  .b(b[9]),  .cin(c9),  .s(sum[9]),  .c(c10));
full_adder fa10(.a(a[10]), .b(b[10]), .cin(c10), .s(sum[10]), .c(c11));
full_adder fa11(.a(a[11]), .b(b[11]), .cin(c11), .s(sum[11]), .c(c12));
full_adder fa12(.a(a[12]), .b(b[12]), .cin(c12), .s(sum[12]), .c(c13));
full_adder fa13(.a(a[13]), .b(b[13]), .cin(c13), .s(sum[13]), .c(c14));
full_adder fa14(.a(a[14]), .b(b[14]), .cin(c14), .s(sum[14]), .c(c15));
full_adder fa15(.a(a[15]), .b(b[15]), .cin(c15), .s(sum[15]), .c(cout));

endmodule
