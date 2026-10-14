module register_file(
    input wire clk,
    input wire rst,

    input wire write_enable_global,
    input wire[3:0] write_addr,
    input wire[15:0] data_in,

    input wire[3:0] read_addr_a,
    output wire[15:0] data_out_a,

    input wire[3:0] read_addr_b,
    output wire[15:0] data_out_b,

    input wire[3:0] read_addr_c,
    output wire[15:0] data_out_c
);
    wire [15:0] reg_out_0,  reg_out_1,  reg_out_2,  reg_out_3;
    wire [15:0] reg_out_4,  reg_out_5,  reg_out_6,  reg_out_7;
    wire [15:0] reg_out_8,  reg_out_9,  reg_out_10, reg_out_11;
    wire [15:0] reg_out_12, reg_out_13, reg_out_14, reg_out_15;
    wire [15:0] decoded_write_signals;

    decoder_4to16 decoder_inst(
        .select(write_addr),
        .out(decoded_write_signals)
    );

    register reg0 (.clk(clk), .rst(rst), .we(write_enable_global & decoded_write_signals[0]),  .data_in(data_in), .data_out(reg_out_0));
    register reg1 (.clk(clk), .rst(rst), .we(write_enable_global & decoded_write_signals[1]),  .data_in(data_in), .data_out(reg_out_1));
    register reg2 (.clk(clk), .rst(rst), .we(write_enable_global & decoded_write_signals[2]),  .data_in(data_in), .data_out(reg_out_2));
    register reg3 (.clk(clk), .rst(rst), .we(write_enable_global & decoded_write_signals[3]),  .data_in(data_in), .data_out(reg_out_3));
    register reg4 (.clk(clk), .rst(rst), .we(write_enable_global & decoded_write_signals[4]),  .data_in(data_in), .data_out(reg_out_4));
    register reg5 (.clk(clk), .rst(rst), .we(write_enable_global & decoded_write_signals[5]),  .data_in(data_in), .data_out(reg_out_5));
    register reg6 (.clk(clk), .rst(rst), .we(write_enable_global & decoded_write_signals[6]),  .data_in(data_in), .data_out(reg_out_6));
    register reg7 (.clk(clk), .rst(rst), .we(write_enable_global & decoded_write_signals[7]),  .data_in(data_in), .data_out(reg_out_7));
    register reg8 (.clk(clk), .rst(rst), .we(write_enable_global & decoded_write_signals[8]),  .data_in(data_in), .data_out(reg_out_8));
    register reg9 (.clk(clk), .rst(rst), .we(write_enable_global & decoded_write_signals[9]),  .data_in(data_in), .data_out(reg_out_9));
    register reg10(.clk(clk), .rst(rst), .we(write_enable_global & decoded_write_signals[10]), .data_in(data_in), .data_out(reg_out_10));
    register reg11(.clk(clk), .rst(rst), .we(write_enable_global & decoded_write_signals[11]), .data_in(data_in), .data_out(reg_out_11));
    register reg12(.clk(clk), .rst(rst), .we(write_enable_global & decoded_write_signals[12]), .data_in(data_in), .data_out(reg_out_12));
    register reg13(.clk(clk), .rst(rst), .we(write_enable_global & decoded_write_signals[13]), .data_in(data_in), .data_out(reg_out_13));
    register reg14(.clk(clk), .rst(rst), .we(write_enable_global & decoded_write_signals[14]), .data_in(data_in), .data_out(reg_out_14));
    register reg15(.clk(clk), .rst(rst), .we(write_enable_global & decoded_write_signals[15]), .data_in(data_in), .data_out(reg_out_15));

    mux_16to1 mux_a (
        .d0(reg_out_0),  .d1(reg_out_1),  .d2(reg_out_2),  .d3(reg_out_3),
        .d4(reg_out_4),  .d5(reg_out_5),  .d6(reg_out_6),  .d7(reg_out_7),
        .d8(reg_out_8),  .d9(reg_out_9),  .d10(reg_out_10),.d11(reg_out_11),
        .d12(reg_out_12),.d13(reg_out_13),.d14(reg_out_14),.d15(reg_out_15),
        .select(read_addr_a),
        .out(data_out_a)
    );

    mux_16to1 mux_b (
        .d0(reg_out_0),  .d1(reg_out_1),  .d2(reg_out_2),  .d3(reg_out_3),
        .d4(reg_out_4),  .d5(reg_out_5),  .d6(reg_out_6),  .d7(reg_out_7),
        .d8(reg_out_8),  .d9(reg_out_9),  .d10(reg_out_10),.d11(reg_out_11),
        .d12(reg_out_12),.d13(reg_out_13),.d14(reg_out_14),.d15(reg_out_15),
        .select(read_addr_b),
        .out(data_out_b)
    );

    mux_16to1 mux_c (
        .d0(reg_out_0),  .d1(reg_out_1),  .d2(reg_out_2),  .d3(reg_out_3),
        .d4(reg_out_4),  .d5(reg_out_5),  .d6(reg_out_6),  .d7(reg_out_7),
        .d8(reg_out_8),  .d9(reg_out_9),  .d10(reg_out_10),.d11(reg_out_11),
        .d12(reg_out_12),.d13(reg_out_13),.d14(reg_out_14),.d15(reg_out_15),
        .select(read_addr_c),
        .out(data_out_c)
    );
endmodule
