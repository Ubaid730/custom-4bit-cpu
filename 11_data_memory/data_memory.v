module data_memory(
    input wire clk,
    input wire write_enable,
    input wire[3:0] addr,
    input wire[3:0] data_in,
    output wire[3:0] data_out

);
    reg[3:0] ram[0:15];
    initial begin
        ram[0] = 4'b1111;
        ram[1] = 4'b1010;
        ram[2] = 4'b0101;
    end
    always @(posedge clk) begin
        if(write_enable) begin
            ram[addr] <= data_in;
        end
    end
    assign data_out = ram[addr];
endmodule

