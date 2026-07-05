`timescale 1ps/1ps

module tb_half_adder();
reg a,b;
wire s,c;
half_adder uut(.A(a),.B(b),.S(s),.C(c));
initial begin
    $dumpfile("half_adder.vcd");
    $dumpvars(0, tb_half_adder);
    #10
            a = 0; b = 0; #10; 
        a = 0; b = 1; #10; 
        a = 1; b = 0; #10; 
        a = 1; b = 1; #10; 
        
        $finish; 
    end
endmodule

