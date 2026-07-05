module mux_4to1(
    input wire[3:0] in0,
    input wire[3:0] in1,
    input wire[3:0] in2,
    input wire[3:0] in3,
    input wire[1:0] select,
    output reg[3:0] out

);
always @(*)begin
    case(select)
        2'b00: out = in0;
        2'b01: out = in1;
        2'b10: out = in2;
        2'b11: out = in3;
        default: out = 4'b0000;
    endcase
end
endmodule