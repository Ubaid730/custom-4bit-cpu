// io_registers.v - MMIO readable peripheral registers for the 16-bit CPU.
//
// The mmio_decoder carves the top of the address space into two windows:
//   0xFFF0-0xFFFA : GPIO bank (existing gpio.v owns the LED output)
//   0xFFFB-0xFFFF : UART / system registers
//
// This module adds READ support to the UART window so software can poll
// hardware instead of blindly assuming timings (a bootloader needs this):
//
//   0xFFFB  UART data     write -> transmit byte (low 8 bits)
//                         read  -> last received byte (from uart_rx), or 0
//   0xFFFC  UART status   read  bit0 = tx_busy, bit1 = rx_ready
//                         (writing here does nothing)
//   0xFFFD  CYCLE counter  read-only free-running 16-bit clock counter.
//                         Great for coarse delays / simple time-of-day.
//   0xFFFF  SYSTEM        read  bit0 = 1 always ("signature", lets a test
//                               confirm the decoder + read path work)
//                         write bit0 = 1 -> HALT the CPU (see cpu_top.v)
//
// Reads are combinational (async): the LOAD that targets one of these
// addresses gets its data on the same cycle it is issued, exactly like
// reading a real static peripheral register.

module io_registers(
    input  wire        clk,
    input  wire        rst,
    input  wire [15:0] addr,       // full ram_addr bus; we decode 0xFFFC..0xFFFF
    input  wire        rd_en,      // LOAD targeting the UART/system window
    input  wire        sys_we,     // STORE targeting 0xFFFF
    input  wire [15:0] wr_data,    // STORE payload
    input  wire        tx_busy,
    input  wire        rx_ready,
    input  wire [7:0]  rx_byte,
    output reg  [15:0] rd_data,
    output reg         halt
);

    // Free-running 16-bit cycle counter (wraps every 65536 clocks).
    reg [15:0] cycles;
    always @(posedge clk or posedge rst) begin
        if (rst)
            cycles <= 16'h0000;
        else
            cycles <= cycles + 16'b1;
    end

    // Write strobe: only STOREs to 0xFFFF reach the halt latch.
    wire is_sys  = rd_en ? 1'b0 : (sys_we && addr == 16'hFFFF);
    wire is_stat = (addr == 16'hFFFC);
    wire is_cyc  = (addr == 16'hFFFD);

    always @(posedge clk or posedge rst) begin
        if (rst)
            halt <= 1'b0;
        else if (is_sys && wr_data[0])
            halt <= 1'b1;             // STORE 1 -> R0 stops the machine
    end

    always @(*) begin
        case (addr)
            16'hFFFC:  rd_data = {14'b0, rx_ready, tx_busy};
            16'hFFFD:  rd_data = cycles;
            16'hFFFB:  rd_data = {8'b0, rx_ready ? rx_byte : 8'h00};
            default:   rd_data = {15'b0, 1'b1};   // 0xFFFF signature & others
        endcase
    end

endmodule
