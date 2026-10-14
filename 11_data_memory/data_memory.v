module data_memory(
    input wire clk,
    input wire write_enable,
    input wire[15:0] addr,
    input wire[15:0] data_in,
    output wire[15:0] data_out

);
    reg[15:0] ram[0:65535];
    initial begin
        ram[0] = 16'hFFFF;
        ram[1] = 16'hAAAA;
        ram[2] = 16'h0505;
    end
    always @(posedge clk) begin
        if(write_enable) begin
            ram[addr] <= data_in;
        end
    end
    assign data_out = ram[addr];
endmodule


