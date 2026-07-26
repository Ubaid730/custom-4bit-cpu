module uart_tx(
    input wire clk,
    input wire rst,
    input wire tx_start,      
    input wire [3:0] tx_data, 
    output reg tx_out,        
    output reg tx_busy        
);

    reg [2:0] bit_index;  
    reg [5:0] shift_reg;  
    reg [3:0] baud_count; 


    localparam BAUD_MAX = 4'd4;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_out    <= 1'b1;  
            tx_busy   <= 1'b0;
            bit_index <= 3'd0;
            shift_reg <= 6'b0;
            baud_count<= 4'd0;
        end
        else if (tx_start && !tx_busy) begin
            // Latch the frame: {stop_bit, data[3], data[2], data[1], data[0], start_bit}
            shift_reg <= {1'b1, tx_data, 1'b0};
            tx_out    <= 1'b0;  
            tx_busy   <= 1'b1;
            bit_index <= 3'd0;
            baud_count<= 4'd0;
        end
        else if (tx_busy) begin
            if (baud_count == BAUD_MAX) begin
                baud_count <= 4'd0;
                if (bit_index == 3'd5) begin
                    
                    tx_busy <= 1'b0;
                    tx_out  <= 1'b1; 
                end
                else begin
                    bit_index <= bit_index + 3'd1;
                    shift_reg <= {1'b1, shift_reg[5:1]}; 
                    tx_out    <= shift_reg[1];            
                end
            end
            else begin
                baud_count <= baud_count + 4'd1;
            end
        end
    end

    
    always @(negedge tx_busy) begin
        if (tx_busy)
            $display("[UART TX] Sent: 4'b%b (hex: %h)", tx_data, tx_data);
    end
    

endmodule