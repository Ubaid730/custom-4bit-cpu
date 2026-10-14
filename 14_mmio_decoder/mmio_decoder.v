module mmio_decoder(
    input wire [15:0] addr,
    input wire mem_write,
    input wire mem_read,
    output wire ram_we,
    output wire ram_re,
    output wire gpio_we,
    output wire gpio_re,
    output wire uart_we
);
    // The top 8 addresses of the 16-bit space are MMIO:
    // 0xFFF0-0xFFFA = GPIO banks, 0xFFFB-0xFFFF = UART
    wire is_gpio  = (addr >= 16'hFFF0) && (addr <= 16'hFFFA);
    wire is_uart  = (addr >= 16'hFFFB);
    wire is_ram   = ~is_gpio & ~is_uart;

    assign ram_we  = mem_write & is_ram;
    assign uart_we = mem_write & is_uart;
    assign gpio_we = mem_write & is_gpio;
    assign ram_re  = mem_read & is_ram;
    assign gpio_re = mem_read & is_gpio;
endmodule
