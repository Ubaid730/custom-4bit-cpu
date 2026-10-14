module mux_4to1(
    input wire[15:0] in0,
    input wire[15:0] in1,
    input wire[15:0] in2,
    input wire[15:0] in3,
    input wire[1:0] select,
    output reg[15:0] out

);
always @(*)begin
    case(select)
        2'b00: out = in0;
        2'b01: out = in1;
        2'b10: out = in2;
        2'b11: out = in3;
        default: out = 16'b0000000000000000;
    endcase
end
endmodule

// The big brother of mux_4to1: picks one of 16 sources
module mux_16to1(
    input wire[15:0] d0,  input wire[15:0] d1,  input wire[15:0] d2,  input wire[15:0] d3,
    input wire[15:0] d4,  input wire[15:0] d5,  input wire[15:0] d6,  input wire[15:0] d7,
    input wire[15:0] d8,  input wire[15:0] d9,  input wire[15:0] d10, input wire[15:0] d11,
    input wire[15:0] d12, input wire[15:0] d13, input wire[15:0] d14, input wire[15:0] d15,
    input wire[3:0] select,
    output reg[15:0] out
);

always @(*)begin
    case(select)
        4'b0000: out = d0;
        4'b0001: out = d1;
        4'b0010: out = d2;
        4'b0011: out = d3;
        4'b0100: out = d4;
        4'b0101: out = d5;
        4'b0110: out = d6;
        4'b0111: out = d7;
        4'b1000: out = d8;
        4'b1001: out = d9;
        4'b1010: out = d10;
        4'b1011: out = d11;
        4'b1100: out = d12;
        4'b1101: out = d13;
        4'b1110: out = d14;
        4'b1111: out = d15;
        default: out = 16'b0000000000000000;
    endcase
end
endmodule
