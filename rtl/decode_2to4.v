module decoder_2to4(
    input wire[1:0] select,
    output reg[3:0] out
);

always @(*)begin
    case(select)
        2'b00: out = 4'b0001;
        2'b01: out = 4'b0010;
        2'b10: out = 4'b0100;
        2'b11: out = 4'b1000;
        default:out=4'b0000;
    endcase
end
endmodule

// Same idea as the 2to4 above, just wider - we have 16 registers now
module decoder_4to16(
    input wire[3:0] select,
    output reg[15:0] out
);

always @(*)begin
    out = 16'b0000000000000000;
    out[select] = 1'b1;
end
endmodule
