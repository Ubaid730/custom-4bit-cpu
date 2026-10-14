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
    //   0xFFF0-0xFFFA = GPIO banks
    //   0xFFFB-0xFFFF = UART / system registers
    // WRITE routing (mem_write path only):
    //   0xFFFE/0xFFFF = UART transmit start (writing any other cell of the
    //                   window would silently bit-bang the serial line, so
    //                   GPIO stays inside FFF0..FFFA and the rest of the
    //                   UART window falls through to plain RAM)
    // READ routing (mem_read path only):
    //   everything >= 0xFFF0 answers from io_registers.v instead of the
    //   RAM array (GPIO input view, rx byte, status, cycle counter).
    wire is_gpio  = (addr >= 16'hFFF0) && (addr <= 16'hFFFA);
    wire is_uart  = (addr >= 16'hFFFE);
    wire is_io_rd = (addr >= 16'hFFF0);
    wire is_ram   = ~is_gpio & ~is_uart;

    assign ram_we  = mem_write & is_ram;
    assign uart_we = mem_write & is_uart;
    assign gpio_we = mem_write & is_gpio;
    assign ram_re  = mem_read & is_ram;
    assign gpio_re = mem_read & is_gpio;
endmodule
