// data_memory.v - 64K x 16-bit RAM.
// NOTE: uninitialized cells read as 0 (not x) so a stray LOAD/RET from an
// empty stack slot returns address 0 and the program survives instead of
// propagating x through the PC.
module data_memory(
    input wire clk,
    input wire write_enable,
    input wire[15:0] addr,
    input wire[15:0] data_in,
    output wire[15:0] data_out,

    // Dedicated asynchronous (combinational) read port. The write-side
    // data_out above is an async read of the same array too, but this port
    // exists so consumers that need a guaranteed-current value (RET reading
    // the return address at sp) have an explicit, named interface instead
    // of poking the internal array hierarchically.
    input  wire[15:0] rd_addr,
    output wire[15:0] rd_data
);
    reg[15:0] ram[0:65535];
    integer i;
    initial begin
        for (i = 0; i < 65536; i = i + 1)
            ram[i] = 16'h0000;   // deterministic power-on state
    end
    always @(posedge clk) begin
        if(write_enable) begin
            ram[addr] <= data_in;
        end
    end
    assign data_out = ram[addr];
    assign rd_data  = ram[rd_addr];
endmodule
