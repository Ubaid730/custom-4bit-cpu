// uart_rx.v - simple 8-bit UART receiver matched to uart_tx.v's baud timing.
//
// uart_tx uses BAUD_MAX = 4, i.e. one bit every 5 clocks. This receiver uses
// the same 5-clock bit period so tx and rx are back-to-back connectable in
// simulation (and consistent if you ever synthesize both together).
//
// Frame format: 1 start bit (0), 8 data bits LSB-first, stop bit ignored.
// A small state machine samples each bit at mid-bit; when a full byte lands
// it raises rx_ready (held until software reads it via io_registers @ 0xFFFB)
// and stores the byte in rx_byte. Overruns simply overwrite - acceptable for
// a teaching CPU where the host types far slower than the core polls.

module uart_rx(
    input  wire       clk,
    input  wire       rst,
    input  wire       rx_in,        // serial line, active-low start bit
    output reg [7:0]  rx_byte,
    output reg        rx_ready
);

    localparam BAUD_MAX = 4;        // must match uart_tx

    reg [3:0] baud_count;
    reg [2:0] bit_index;
    reg [7:0] shift_reg;
    reg       busy;

    // States: 0 = idle (wait for falling edge), 1 = start bit, 2 = data bits
    reg [1:0] state;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state     <= 2'd0;
            baud_count<= 4'd0;
            bit_index <= 3'd0;
            shift_reg <= 8'd0;
            busy      <= 1'b0;
            rx_byte   <= 8'd0;
            rx_ready  <= 1'b0;
        end else begin
            case (state)
                2'd0: begin                     // IDLE: hunt for start bit
                    if (!rx_in) begin
                        state      <= 2'd1;
                        baud_count <= 4'd0;
                        bit_index  <= 3'd0;
                        busy       <= 1'b1;
                    end
                end
                2'd1: begin                     // START: verify it isn't noise
                    if (baud_count == {1'b0, BAUD_MAX[3:0]}) begin
                        baud_count <= 4'd0;
                        if (rx_in)              // line went back high -> false
                            state <= 2'd0;
                        else
                            state <= 2'd2;      // real start bit, sample data
                    end else
                        baud_count <= baud_count + 4'd1;
                end
                2'd2: begin                     // DATA: 8 bits, LSB first
                    if (baud_count == {1'b0, BAUD_MAX[3:0]}) begin
                        baud_count    <= 4'd0;
                        shift_reg     <= {rx_in, shift_reg[7:1]};
                        if (bit_index == 3'd7) begin
                            rx_byte  <= {rx_in, shift_reg[7:1]};
                            rx_ready <= 1'b1;
                            state    <= 2'd0;   // leave stop bit to idle logic
                            busy     <= 1'b0;
                        end else
                            bit_index <= bit_index + 3'd1;
                    end else
                        baud_count <= baud_count + 4'd1;
                end
                default: state <= 2'd0;
            endcase
        end
    end

endmodule
