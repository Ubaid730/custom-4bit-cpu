module mmio_decoder(
    input wire [3:0] addr,
    input wire mem_write,
    input wire mem_read,
    output wire ram_we,
    output wire ram_re,
    output wire gpio_we,
    output wire gpio_re,
    output wire uart_we
);
    assign ram_we  = mem_write & (addr < 4'b1110);
    assign uart_we = mem_write & (addr == 4'b1110);
    assign gpio_we = mem_write & (addr == 4'b1111);
    assign ram_re  = mem_read & (addr < 4'b1110);
    assign gpio_re = mem_read & (addr == 4'b1111);
endmodule