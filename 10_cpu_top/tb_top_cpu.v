`timescale 1ns/1ps

module tb_cpu_top;
    reg clk;
    reg rst;

    // Instantiate the CPU
    cpu_top uut (
        .clk(clk),
        .rst(rst)
    );

    // Clock generation: 10ns period (5ns high, 5ns low)
    always #5 clk = ~clk;

    initial begin
          $dumpfile("cpu_with_uart.vcd");
        $dumpvars(0, tb_cpu_top);
        // Initialize signals
        clk = 0;
        rst = 1;
        
        // Hold reset for a few cycles to let hardware settle
        #20;
        rst = 0;
        
        // Run for enough cycles to execute the 10 instructions + buffer
        #200;
        
        // Print final state to console
        $display("=========================================");
        $display("Simulation Finished at time %0t", $time);
        $display("=========================================");
        $display("Final Register State:");
        $display("R0 = %0d", uut.reg_file_inst.reg_out_0);
        $display("R1 = %0d", uut.reg_file_inst.reg_out_1);
        $display("R2 = %0d", uut.reg_file_inst.reg_out_2);
        $display("R3 = %0d", uut.reg_file_inst.reg_out_3);
        $display("-----------------------------------------");
        $display("Stack Pointer (SP) = %0d", uut.sp_inst.sp);
        $display("RAM[3] (Memory)    = %0d", uut.ram_inst.ram[3]);
        $display("=========================================");
        
        $finish;
    end

    // Monitor specific signals every time they change
    initial begin
        $monitor("Time=%0t | PC=%0d | Opcode=%b | R0=%0d R1=%0d R2=%0d R3=%0d | SP=%0d",
                 $time, uut.pc_out, uut.opcode, 
                 uut.reg_file_inst.reg_out_0, 
                 uut.reg_file_inst.reg_out_1, 
                 uut.reg_file_inst.reg_out_2, 
                 uut.reg_file_inst.reg_out_3,
                 uut.sp_inst.sp);
    end

endmodule