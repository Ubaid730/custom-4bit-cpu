module instruction_memory(
    input wire[3:0] addr,
    output wire[7:0] instruction
);
reg[7:0] mem[0:15];
initial begin
    mem[0] = 8'b0001_00_01;
    mem[1] = 8'b0010_01_10; 
    mem[2] = 8'b0011_10_11; 
    mem[3] = 8'b0000_00_00; 
end
assign instruction = mem[addr];
endmodule