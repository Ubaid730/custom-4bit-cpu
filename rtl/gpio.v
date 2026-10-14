module gpio(
    input wire clk,
    input wire rst,
    input wire write_enable,
    input wire[15:0] data_in,
    output reg[15:0] leds
);

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            leds <= 16'b0000000000000000;
    end
    else if(write_enable) begin
        leds <= data_in;
    end
end
endmodule
