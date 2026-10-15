module four_bit_full_adder(
    input[3:0] a,
    input[3:0] b,
    input cin,
    output[3:0] sum,
    output cout
);
wire c1,c2,c3;

full_adder fa0(.a(a[0]), .b(b[0]), .cin(cin), .s(sum[0]), .c(c1));  
full_adder fa1(.a(a[1]), .b(b[1]), .cin(c1), .s(sum[1]), .c(c2));    
full_adder fa2(.a(a[2]), .b(b[2]), .cin(c2), .s(sum[2]), .c(c3));    
full_adder fa3(.a(a[3]), .b(b[3]), .cin(c3), .s(sum[3]), .c(cout));  

endmodule