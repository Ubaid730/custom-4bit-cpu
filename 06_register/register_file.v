module register_file(
    input wire clk,
    input wire rst,

    input wire write_enable_global,
    input wire[1:0] write_addr,
    input wire[3:0] data_in,

    input wire[1:0] read_addr_a,
    output wire[3:0] data_out_a,

    input wire[1:0] read_addr_b,
    output wire[3:0] data_out_b
);
    wire [3:0] reg_out_0, reg_out_1, reg_out_2, reg_out_3;
    wire [3:0] decoded_write_signals;

    decoder_2to4 decoder_inst(
        .select(write_addr),
        .out(decoded_write_signals)
    );

    register reg0 (.clk(clk), .rst(rst), .we(write_enable_global & decoded_write_signals[0]), .data_in(data_in), .data_out(reg_out_0));
    register reg1 (.clk(clk), .rst(rst), .we(write_enable_global & decoded_write_signals[1]), .data_in(data_in), .data_out(reg_out_1));
    register reg2 (.clk(clk), .rst(rst), .we(write_enable_global & decoded_write_signals[2]), .data_in(data_in), .data_out(reg_out_2));
    register reg3 (.clk(clk), .rst(rst), .we(write_enable_global & decoded_write_signals[3]), .data_in(data_in), .data_out(reg_out_3));

        mux_4to1 mux_a (
        .in0(reg_out_0), .in1(reg_out_1), .in2(reg_out_2), .in3(reg_out_3),
        .select(read_addr_a),
        .out(data_out_a)
    );

    mux_4to1 mux_b (
        .in0(reg_out_0), .in1(reg_out_1), .in2(reg_out_2), .in3(reg_out_3),
        .select(read_addr_b),
        .out(data_out_b)
    );
endmodule