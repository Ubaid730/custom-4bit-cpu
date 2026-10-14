// cpu_top.v - the complete 16-bit CPU SoC core.
//
// Exposes the peripheral side-bands so a testbench (or real FPGA top-level)
// can attach a console / LEDs without touching the internals:
//   leds[15:0] : GPIO output register (STORE to 0xFFF0..0xFFFA)
//   tx_out     : UART TX serial line  (STORE to 0xFFFB..0xFFFF)
//   rx_in      : UART RX serial line  (LOAD from 0xFFFB after uart_rx sync)
//   halted     : set when software STOREs bit0=1 to 0xFFFF (the HALT op)
module cpu_top(
    input  wire        clk,
    input  wire        rst,
    input  wire        rx_in,
    output wire [15:0] leds,
    output wire        tx_out,
    output wire        halted
);


    wire [15:0] pc_out;
    wire [31:0] instruction;
    wire [7:0] opcode;
    wire [3:0] dest_reg;
    wire [3:0] src_reg;
    wire [3:0] src2_reg;
    wire [15:0] immediate;
    wire reg_write_enable;
    wire mem_write_enable;
    wire [2:0] alu_ctrl;
    wire [1:0] pc_source_cu;
    wire [1:0] reg_in_source;
    wire [15:0] reg_data_a;
    wire [15:0] reg_data_b;
    wire [15:0] reg_data_c;
    wire [15:0] alu_result;


    wire zero_flag_raw;
    wire carry_flag_raw;
    wire overflow_flag_raw;
    wire negative_flag_raw;
    wire zero_flag_stored;
    wire carry_flag_stored;
    wire overflow_flag_stored;
    wire negative_flag_stored;
    wire flags_write;   // control unit: only ALU/CMP instructions update flags

    wire gpio_write_enable;
    wire actual_ram_write_enable;
    wire stack_push;
    wire stack_pop;
    wire [15:0] ram_addr;
    wire [15:0] ram_data_in;
    wire [15:0] ram_data_out;
    wire [15:0] reg_file_data_in;

    wire [7:0] raw_opcode = instruction[31:24];
    // HALT (0x34) is a NOP while the machine is already halted, so the PC can
    // never run off the end of the ROM into x-state memory.
    assign opcode   = halted_q ? 8'h00 : raw_opcode;
    assign dest_reg = instruction[19:16];
    assign src_reg  = instruction[15:12];
    assign src2_reg = instruction[11:8];
    // LI / jumps / CALL use the FULL 16-bit operand field [15:0]:
    //   dest lives in [19:16] (harmless overlap with the imm's high byte)
    //   src2  must be forced to 0 so it doesn't alias into the immediate
    assign immediate = instruction[15:0];
    wire is_imm_op = (opcode == 8'h10) ||            // LI
                     (opcode >= 8'h20 && opcode <= 8'h26) || // JMP/JZ/JNZ/JC/JNC/JN/JNN
                     (opcode == 8'h32);               // CALL
    // Register-file read ports must match the WRITE port selection:
    // reg_in_source==01 means "writeback comes from the immediate", which is
    // only true for LI / jumps / CALL. STORE/PUSH/LOAD/... have their own
    // reg_in_source values, so their address register must ALWAYS be read
    // from src2 - otherwise an unconditional `reg_in_source==01` here made
    // every STORE write to ram[0].
    wire is_addr_imm = (opcode == 8'h10) ||                       // LI
                       (opcode >= 8'h20 && opcode <= 8'h26) ||    // jumps
                       (opcode == 8'h32);                         // CALL
    wire ram_re,ram_we,gpio_re,gpio_we,uart_we;
    wire tx_busy;
    // LOAD/POP read RAM into a register; conditional jumps READ the operand
    // registers only - but RET must be excluded here or it would wrongly
    // classify as a "read op" for the MMIO decoder.
    wire is_read_op = (opcode == 8'h11) || (opcode == 8'h31);
    
    wire [15:0] next_pc_val;
    wire [15:0] sp;
    program_counter pc_inst (
        .clk(clk), .rst(rst),
        .next_pc(next_pc_g),
        .pc(pc_out)
    );

    instruction_memory rom_inst (
        .addr(pc_out),
        .instruction(instruction)
    );

    control_unit cu_inst (
        .opcode(opcode),
        .reg_write_enable(reg_write_enable),
        .mem_write_enable(mem_write_enable),
        .alu_ctrl(alu_ctrl),
        .pc_source(pc_source_cu),
        .reg_in_source(reg_in_source),
        .stack_pop(stack_pop),
        .stack_push(stack_push),
        .flags_write(flags_write)
    );

    register_file reg_file_inst (
        .clk(clk), .rst(rst),
        .write_enable_global(reg_write_g),
        // On LI / jumps / CALL the full 16-bit operand lives in [15:0];
        // src2[11:8] is part of that number, so it must not address a register.
        .write_addr(dest_reg),
        .data_in(reg_file_data_in),
        .read_addr_a(src_reg),
        .data_out_a(reg_data_a),
        .read_addr_b(is_imm_op ? 4'b0000 : src2_reg),
        .data_out_b(reg_data_b),
        .read_addr_c(dest_reg),
        .data_out_c(reg_data_c)
    );


    // ALU operand B comes from the right place depending on the instruction type:
    // LI / jumps -> the 16-bit immediate field (the jump TARGET lives there,
    //               and it must never leak into the ALU - that would spray
    //               garbage flags all over the flag register).
    // STORE/LOAD/PUSH/POP/CALL/RET -> R[src2] (the address lives there)
    // everything else (ADD/SUB/AND...) -> R[src2] as the second operand too
    wire [15:0] alu_b = (reg_in_source == 2'b01) ? immediate : reg_data_b;

    alu alu_inst (
        .a(reg_data_a),
        .b(alu_b),
        .opcode(alu_ctrl),
        .result(alu_result),
        .zero_flag(zero_flag_raw),
        .carry_flag(carry_flag_raw),
        .overflow_flag(overflow_flag_raw),
        .negative_flag(negative_flag_raw)
    );

    // Which conditional jumps actually take the branch?
    // They read the STORED flags - the flags latched by the instruction that
    // ran last cycle (CMP / SUB / ADD / ...). In this single-cycle design a
    // jump is fetched & executed while the previous instruction's flags have
    // JUST landed in the flag register, so "CMP Rx, Ry" immediately followed
    // by "JZ label" behaves exactly like a real processor.
    //
    // THE BUG THAT WAS FIXED: previously the flag register latched on EVERY
    // clock edge, so non-ALU instructions (LI, LOAD, jumps themselves...)
    // overwrote the flags with garbage from the idle ALU inputs. Now the
    // control unit raises `flags_write` only for instructions that really
    // compute flags, and the flag register keeps its old value otherwise.
    // That also means flags survive NOPs/LIs between a CMP and its jump.
    //
    // SECOND BUG THAT WAS FIXED: an UNTAKEN conditional jump used to fall
    // through to PC+1 on the same edge that it zeroed the stored flags
    // (the jump itself drives flags_write low via the mux below). A program
    // like "SUB / JZ / JZ / JZ" would therefore lose Z after the first jump
    // and never branch. Fix: any jump that does NOT latch preserves the
    // flags it was testing, so consecutive conditional jumps all see them.
    wire is_jump_op = (opcode >= 8'h20) && (opcode <= 8'h26);

    wire cond_true = (opcode == 8'h21) ? zero_flag_stored :         // JZ
                     (opcode == 8'h22) ? ~zero_flag_stored :        // JNZ
                     (opcode == 8'h23) ? carry_flag_stored :        // JC (borrow)
                     (opcode == 8'h24) ? ~carry_flag_stored :       // JNC
                     (opcode == 8'h25) ? negative_flag_stored :     // JN
                     (opcode == 8'h26) ? ~negative_flag_stored :    // JNN
                                         1'b1;                      // JMP always jumps

    wire flags_write_final = flags_write | (is_jump_op & ~cond_true);

    flags_register flags_inst (
        .clk(clk), .rst(rst),
        .flags_write(flags_write_g),
        .zero_in(zero_flag_raw),
        .carry_in(carry_flag_raw),
        .overflow_in(overflow_flag_raw),
        .negative_in(negative_flag_raw),
        .zero_out(zero_flag_stored),
        .carry_out(carry_flag_stored),
        .overflow_out(overflow_flag_stored),
        .negative_out(negative_flag_stored)
    );
    gpio gpio_inst(
        .clk(clk),
        .rst(rst),
        // Only a real STORE to the GPIO window lights the LEDs - never a stray
        // PUSH/CALL that happens to land in 0xFFF0..0xFFFA.
        .write_enable(gpio_write_g),
        .data_in(ram_data_in),
        .leds(leds)
    );

    // Memory addressing:
    //   PUSH/CALL -> write at SP (before it decrements)
    //   POP/RET   -> read AT SP (SP increments on the same edge that consumes
    //                the read data, so during the cycle SP still points at the
    //                top-of-stack cell - reading sp+1 was the RET->xxxx bug)
    //   STORE     -> R[src2] holds the address, R[src] holds the data
    //   LOAD      -> R[src2] holds the address, result goes to R[dest]
    // ALU ops and jumps never touch RAM. The datapath gate is stack_push |
    // mem_write_enable (the control unit raises mem_write_enable for STORE,
    // PUSH and CALL); using the raw opcode here instead would silently block
    // every STORE because the decoder's mem_write_enable IS the STORE signal.
    wire ram_write_op  = stack_push | mem_write_enable;   // STORE / PUSH / CALL
    wire ram_read_op   = (opcode == 8'h11) || stack_pop;  // LOAD  / POP  / RET

    // THE ADDRESS BUG THAT WAS FIXED: reg_data_b is a REGISTER FILE output,
    // i.e. it only updates on a clock edge. On the very first STORE after an
    // LI loaded the address register, reg_data_b during the STORE cycle still
    // shows the OLD value - so the store landed in the wrong cell (and worse,
    // CALLs jumped with a stale operand). Fix: bypass the register file with
    // the freshly-computed ALU result whenever this instruction reads/writes
    // memory through R[src2]. The ALU computes exactly R[src2] + 0 on these
    // opcodes (alu_ctrl defaults to ADD), so alu_result == what R[src2] WILL
    // be next cycle. This makes STORE/PUSH/LOAD see its operands one cycle
    // earlier - like forwarding in a real pipelined CPU.
    wire [15:0] src2_bypassed = (ram_write_op | (opcode == 8'h11)) ? alu_result
                                                                   : reg_data_b;
    assign ram_addr = (stack_push | stack_pop) ? sp :
                      src2_bypassed;
    // STORE / PUSH write R[src] (assembler puts the stored/pushed register in
    // the src field, and its address in src2); CALL writes the return address.
    // THE CALL BUG THAT WAS FIXED: CALL jumps to the subroutine on the SAME
    // clock edge that writes ram[sp] <= PC+1. In Verilog the RAM samples its
    // data_in just before the edge, so it used to capture pc_out+1 while
    // pc_out was still the CALL's own address - pushing the CALL address
    // itself and making RET loop forever. Fix: latch pc_out+1 into a register
    // during the CALL cycle; by the next edge reg_return_addr already holds
    // the correct value and the RAM captures THAT.
    reg [15:0] reg_return_addr;
    always @(posedge clk or posedge rst) begin
        if (rst)
            reg_return_addr <= 16'h0000;
        else if (opcode == 8'h32)          // CALL: remember where to come back to
            reg_return_addr <= pc_out + 16'b1;
    end

    assign ram_data_in = (opcode == 8'h32) ? (pc_out + 16'b1) :  // CALL pushes PC+1
                     reg_data_a;                                 // STORE/PUSH: R[src]

    // The RAM's real write data: on a CALL cycle use the LATCHED value so the
    // memory captures the correct PC+1 one edge later (see explanation above).
    wire [15:0] ram_write_data = (opcode == 8'h32) ? reg_return_addr : ram_data_in;

    data_memory ram_inst (
        .clk(clk),
        // Only STORE/PUSH/CALL may write, and only when the MMIO decoder says
        // the address is real RAM (not GPIO/UART).
        .write_enable(ram_write_g),
        .addr(ram_addr),
        .data_in(ram_write_data),
        .data_out(ram_data_out)
    );
    stack_pointer sp_inst(
        .clk(clk),
        .rst(rst),
        .push(stack_push_g),
        .pop(stack_pop_g),
        .sp(sp)
    );
    mmio_decoder mmio_inst(
    .addr(ram_addr),
    .mem_write(mem_write_enable),
    .mem_read(is_read_op),
    .ram_we(actual_ram_write_enable),
    .ram_re(ram_re),
    .gpio_we(gpio_write_enable),
    .gpio_re(gpio_re),
    .uart_we(uart_we)
    );
    uart_tx uart_inst(
    .clk(clk),
    .rst(rst),
    // a real STORE to the UART window starts a transmission
    .tx_start(uart_start_g),
    .tx_data(ram_data_in),
    .tx_out(tx_out),
    .tx_busy(tx_busy)
);


    // Register-file writeback mux. Source 2'b10 normally means "RAM"; we give
    // it a sub-choice: if the address sits in an MMIO window, take the
    // peripheral's combinational read data instead of the RAM cell.
    wire ram_or_io = (ram_addr >= 16'hFFF0) ? io_rd_data : ram_data_out;
    assign reg_file_data_in = (reg_in_source == 2'b01) ? immediate :
                              (reg_in_source == 2'b10) ? ram_or_io :
                              alu_result;

    // cond_true / flags_write_final are defined up near the flag register.
    // CALL target: the label address lives in the 16-bit immediate field;
    // jump_addr is shared by JMP / conditional jumps / CALL.
    wire [15:0] jump_addr = immediate;

    // RET pops the stack. THE BUG THAT WAS FIXED: we used to read
    // ram[sp+1], assuming SP had already been incremented by the pop. But in
    // this single-cycle design the POP edge increments SP at the SAME clock
    // edge that latches the new PC - so during the RET cycle sp still points
    // AT the return address slot (CALL wrote PC+1 to sp, then decremented).
    // Reading sp+1 returned an empty stack cell (x) and the PC went to hell.
    // Correct source for both POP and RET is therefore ram[sp] itself.
    wire [15:0] ret_addr = ram_data_out;   // data_memory addr is ram_addr = sp on pop

    // Conditional jumps / CALL also latch their PC on the same edge that
    // changes SP or flags - that is fine here because none of them READ a
    // value produced by their own edge. Only RET needs the fix above.
    assign next_pc_val = (pc_source_cu == 2'b10) ? ret_addr :     // RET -> pop PC from stack
                     (pc_source_cu == 2'b01 && cond_true) ? jump_addr :
                     (pc_out + 16'b1);


    // =====================================================================
    // HALT support (two flavours, both freeze every state element):
    //   1. the HALT instruction (opcode 0x34) parks the core on its own PC;
    //   2. STORE bit0=1 to 0xFFFF latches `halted_q` permanently (until
    //      reset) - the MMIO "power switch" for monitors and OS panics.
    // g_clk_ok is the "clock good" qualifier wired into PC, SP, register
    // file, flags, RAM writes and all MMIO write strobes below.
    // =====================================================================
    // =====================================================================
    // System / status registers (io_registers.v) + UART receiver (uart_rx.v)
    // LOADs aimed at the UART/system window answer combinationally:
    //   0xFFFB rx byte | 0xFFFC {_,_,rx_ready,tx_busy} | 0xFFFD cycle counter
    //   0xFFFF signature bit0=1.  This is what poll loops in bootloaders use.
    // =====================================================================
    wire is_gpio_addr = (ram_addr >= 16'hFFF0) && (ram_addr <= 16'hFFFA);
    wire io_rd_en     = (opcode == 8'h11) && ~is_gpio_addr;   // LOAD into UART/sys win
    wire [15:0] io_rd_data;

    io_registers io_inst(
        .clk(clk), .rst(rst),
        .addr(ram_addr),
        .rd_en(io_rd_en),
        .sys_we(1'b0),              // halt is decoded directly below (halted_q)
        .wr_data(ram_data_in),
        .tx_busy(tx_busy),
        .rx_ready(rx_ready),
        .rx_byte(rx_byte),
        .rd_data(io_rd_data),
        .halt()                     // unused output; cpu_top owns halted_q
    );

    // UART receiver: lets a monitor/bootloader poll 0xFFFC bit1 then read 0xFFFB.
    wire [7:0] rx_byte;
    wire       rx_ready;
    uart_rx rxuart_inst(
        .clk(clk), .rst(rst),
        .rx_in(rx_in),
        .rx_byte(rx_byte),
        .rx_ready(rx_ready)
    );

    wire halt_instr = (raw_opcode == 8'h34);   // raw: opcode is NOP'd once halted
    reg  halted_q;
    reg  halt_arm;                             // one-shot so HALT runs exactly once
    assign halted = halted_q;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            halted_q <= 1'b0;
            halt_arm <= 1'b1;
        end else begin
            if (halt_instr && halt_arm && !halted_q) begin
                halted_q <= 1'b1;              // HALT instruction parks the PC here
                halt_arm <= 1'b0;
            end
            if (ram_write_op && uart_we && ram_addr == 16'hFFFF && ram_data_in[0])
                halted_q <= 1'b1;              // io_registers-style MMIO halt
        end
    end

    wire g_clk_ok = ~halted_q & ~halt_instr;

    wire reg_write_g   = reg_write_enable & g_clk_ok;
    wire gpio_write_g  = gpio_write_enable & ram_write_op & g_clk_ok;
    wire uart_start_g  = uart_we & ram_write_op & g_clk_ok;
    wire ram_write_g   = actual_ram_write_enable & ram_write_op
                         & ~gpio_write_enable & ~uart_we & g_clk_ok;
    wire stack_push_g  = stack_push & g_clk_ok;
    wire stack_pop_g   = stack_pop  & g_clk_ok;
    wire flags_write_g = flags_write_final & g_clk_ok;
    wire [15:0] next_pc_g = g_clk_ok ? next_pc_val : pc_out;   // frozen PC

endmodule
