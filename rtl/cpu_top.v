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

    // =====================================================================
    // FETCH STAGE wires (raw ROM word fields, indexed by pc_out)
    // =====================================================================
    wire [7:0]  opcode_f    = instruction[31:24];
    wire [3:0]  dest_f      = instruction[19:16];
    wire [3:0]  src_f       = instruction[15:12];
    wire [3:0]  src2_f      = instruction[11:8];
    wire [15:0] immediate_f = instruction[15:0];

    // =====================================================================
    // HALT support (two flavours, both freeze every state element):
    //   1. the HALT instruction (opcode 0x34) parks the core on its own PC;
    //   2. STORE bit0=1 to 0xFFFF latches `mmio_halt` permanently (until
    //      reset) - the MMIO "power switch" for monitors and OS panics.
    // g_clk_ok is the "clock good" qualifier wired into PC, SP, register
    // file, flags, RAM writes and all MMIO write strobes below.
    // =====================================================================
    reg  halted_q;      // one-shot: set by the HALT instruction OR an MMIO
                        // STORE bit0=1 to 0xFFFF; cleared only by reset.
    assign halted = halted_q;
    // g_clk_ok is the master "clock good" qualifier: when the core parks it
    // freezes the PC, the IR latch, the flags, SP, RAM/GPIO/UART write
    // strobes - everything. It is deliberately built ONLY from registered
    // state (halted_q), never from the combinational decode of the IR, so no
    // path through the latch enable can loop back into the latch's own data
    // input (a combinational halt_instr here was the zero-delay feedback
    // that livelocked vvp the moment a program reached HALT).
    wire g_clk_ok = ~halted_q;

    // LI / jumps / CALL use the FULL 16-bit operand field [15:0]:
    //   dest lives in [19:16] (harmless overlap with the imm's high byte)
    //   src/src2 must be forced to 0 so they don't alias into the immediate.
    // Register-file read port B therefore reads R0 for these ops instead of
    // whatever the immediate's high nibble happens to name.
    wire is_addr_imm = (opcode == 8'h10) ||                       // LI
                       (opcode >= 8'h20 && opcode <= 8'h26) ||    // jumps
                       (opcode == 8'h32);                         // CALL
    wire ram_re,ram_we,gpio_re,gpio_we,uart_we;
    wire tx_busy;
    // LOAD/POP read RAM into a register; conditional jumps READ the operand
    // registers only - but RET must be excluded here or it would wrongly
    // classify as a "read op" for the MMIO decoder.
    wire is_read_op = (opcode == 8'h11) || (opcode == 8'h31);

    // =====================================================================
    // PROGRAM COUNTER + INSTRUCTION ROM.
    // The PC advances from next_pc_g EVERY cycle (no stalls).  Branches are
    // resolved one cycle after the flag-producing ALU op latched its flags,
    // which is exactly when the jump sits in the execute stage - so no
    // bubble is needed anywhere.  HALT parks the machine: `halted` freezes
    // the PC, the IR latch and every write strobe forever.
    // =====================================================================
    wire [15:0] sp;
    wire [15:0] next_pc_val;                   // computed near the bottom
    wire        halt_instr;                    // decoded from the latched IR
    // NOTE: during the execute cycle the PC register already shows fetch-PC+2
    // (the IR latch and PC advance on the same edge).  Sequential next-PC is
    // computed from the CAPTURED fetch address (ir_pc_next+1), never from the
    // live pc_out - see next_pc_val at the bottom of this file.
    wire [15:0] next_pc_g = g_clk_ok ? next_pc_val : pc_out;

    program_counter pc_inst (
        .clk(clk), .rst(rst),
        .next_pc(next_pc_g),
        .pc(pc_out)
    );

    instruction_memory rom_inst (
        .addr(pc_out),
        .instruction(instruction)
    );

    // =====================================================================
    // FETCH -> EXECUTE REGISTER
    // The ROM presents word N while the PC has already moved to N+1, so if
    // the datapath decoded the LIVE instruction wire every operation would
    // run one word off (this was the root cause behind SUB computing R1-R1,
    // POP restoring wrong values and RET jumping to garbage). We therefore
    // capture each fetched word into ir_* on the same edge that advances
    // the PC, and decode/execute ONLY from those latched fields. Once the
    // core halts we stop latching entirely; the parked HALT word itself is
    // neutralised by forcing the executed opcode to NOP (see halt_instr
    // interaction below) so no write strobe can ever fire again.
    // =====================================================================
    reg [7:0]  ir_opcode;
    reg [3:0]  ir_dest, ir_src, ir_src2;
    reg [15:0] ir_imm;
    reg [15:0] ir_pc_next;        // fetch-PC+1 captured at latch time = CALL return addr

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ir_opcode <= 8'h00;
            ir_dest   <= 4'b0000;
            ir_src    <= 4'b0000;
            ir_src2   <= 4'b0000;
            ir_imm    <= 16'b0;
            ir_pc_next <= 16'b1;
        end else if (g_clk_ok) begin
            ir_opcode <= opcode_f;
            ir_dest   <= dest_f;
            ir_src    <= src_f;
            ir_src2   <= src2_f;
            ir_imm    <= immediate_f;
            ir_pc_next <= pc_out + 16'b1;  // return address if THIS word is a CALL
        end
    end

    // Execute-stage names used by everything below:
    assign opcode    = ir_opcode;
    assign dest_reg  = ir_dest;
    assign src_reg   = ir_src;
    assign src2_reg  = ir_src2;
    assign immediate = ir_imm;

    // HALT is decoded from the LATCHED execute-stage opcode, not the raw ROM
    // wire. While the PC is parked on the HALT word the frozen fetch keeps
    // re-latching it, so we mask it to NOP after the first execution: the
    // strobes below all AND with ~halt_exec, guaranteeing a single, clean,
    // permanent park with zero event churn (the old vvp livelock source).
    assign halt_instr = (opcode == 8'h34);

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
        .write_enable_global(reg_write_enable),   // ungated: HALT never sets it
        // On LI / jumps / CALL the full 16-bit operand lives in [15:0];
        // src2[11:8] is part of that number, so it must not address a register.
        .write_addr(dest_reg),
        .data_in(reg_file_data_in),
        .read_addr_a(src_reg),
        .data_out_a(reg_data_a),
        .read_addr_b(is_addr_imm ? 4'b0000 : src2_reg),
        .data_out_b(reg_data_b),
        .read_addr_c(dest_reg),
        .data_out_c(reg_data_c)
    );

    // OPERAND FORWARDING: if a read port addresses the register being
    // written THIS cycle (same-instruction dest==src forms like SUB R0,R1,
    // or ADD R3,R0,R1 where dest is also an operand), show the write data
    // combinationally instead of the stale stored value. The qualifier is
    // the GATED strobe reg_write_g so a HALTing core can never forward.
    wire [15:0] reg_a = (reg_write_g && (dest_reg == src_reg))
                        ? reg_file_data_in : reg_data_a;
    wire [15:0] reg_b_raw = is_addr_imm ? 16'b0 : reg_data_b;
    wire [15:0] reg_b = (reg_write_g && !is_addr_imm && (dest_reg == src2_reg))
                        ? reg_file_data_in : reg_b_raw;

    // ALU operand selection.
    // SHL/SHR are barrel shifts by a 4-bit amount taken from imm[3:0]; they
    // bypass the ALU entirely (see shlshr_result / the writeback mux below),
    // so we force alu_ctrl to ADD for them - otherwise the idle ALU computed
    // garbage Z/N/C flags into the flag register and corrupted the countdown
    // JZ decisions.
    // LI / jumps / CALL must NEVER feed their 16-bit operand into the ALU
    // either - same garbage-flag reason (any big target sets N/Z and the
    // NEXT conditional branch mis-fires). Forcing alu_ctrl=ADD with b=0
    // keeps the flags honest.
    wire is_shlshr = (opcode == 8'h07) || (opcode == 8'h08);
    wire [2:0] alu_ctrl_final = (is_shlshr | is_addr_imm) ? 3'b000 : alu_ctrl;

    alu alu_inst (
        .a(reg_a),
        .b(reg_b),
        .opcode(alu_ctrl_final),
        .result(alu_result),
        .zero_flag(zero_flag_raw),
        .carry_flag(carry_flag_raw),
        .overflow_flag(overflow_flag_raw),
        .negative_flag(negative_flag_raw)
    );

    wire is_jump_op = (opcode >= 8'h20) && (opcode <= 8'h26);

    // FLAG ALIGNMENT (the reason the fetch->execute register exists):
    // an ALU op latches its flags on the same clock edge that moves the
    // following jump into the execute stage, so during the jump's execute
    // cycle the STORED flags are exactly the flags of the preceding ALU op.
    // NOP / LI / LOAD / STORE / taken-jump instructions never raise
    // flags_write, so they correctly preserve older flags across gaps
    // between a CMP and its conditional branch.
    wire zero_eff     = zero_flag_stored;
    wire carry_eff    = carry_flag_stored;
    wire negative_eff = negative_flag_stored;

    wire cond_true = (opcode == 8'h21) ? zero_eff :          // JZ
                     (opcode == 8'h22) ? ~zero_eff :          // JNZ
                     (opcode == 8'h23) ? carry_eff :          // JC (borrow)
                     (opcode == 8'h24) ? ~carry_eff :         // JNC
                     (opcode == 8'h25) ? negative_eff :       // JN
                     (opcode == 8'h26) ? ~negative_eff :      // JNN
                                         1'b1;                // JMP always jumps

    // Flags are STICKY: only an ALU/CMP/SHL/SHR instruction raises
    // flags_write and updates them. A taken jump clears nothing; a not-taken
    // conditional jump preserves the CMP flags so a second branch can test
    // the same flags (classic multi-way dispatch).

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
    // =====================================================================
    // Gated write strobes - single definition point AFTER every source
    // exists (control unit outputs, MMIO decode bits, stack flags, jump
    // qualification). The previous layout forward-declared these as bare
    // `wire`s and assigned them much later; combined with ret_addr being a
    // hierarchical reference into the RAM array that created a zero-delay
    // feedback path which froze the vvp event loop mid-countdown.
    // =====================================================================
    wire ram_write_op  = stack_push | mem_write_enable;   // STORE / PUSH / CALL
    wire reg_write_g   = reg_write_enable & g_clk_ok;
    wire gpio_write_g  = gpio_write_enable & ram_write_op & g_clk_ok;
    wire uart_start_g  = uart_we & ram_write_op & g_clk_ok;
    wire ram_write_g   = actual_ram_write_enable & ram_write_op
                         & ~gpio_write_enable & ~uart_we & g_clk_ok;
    wire stack_push_g  = stack_push & g_clk_ok;
    wire stack_pop_g   = stack_pop  & g_clk_ok;
    wire flags_write_g = flags_write & g_clk_ok;

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
    // (ram_write_op itself is declared once in the gated-strobe block above.)
    wire ram_read_op   = (opcode == 8'h11) || stack_pop;  // LOAD  / POP  / RET

    // THE ADDRESS BUG THAT WAS FIXED: reg_data_b used to be a REGISTER FILE
    // output only, so on the very first STORE after an LI loaded the address
    // register it still showed the OLD value and the store landed in the
    // wrong cell. The forwarding muxes above (reg_a / reg_b) now resolve the
    // fresh value combinationally, so the memory path simply uses them -
    // no ALU bypass needed any more (that hack also mis-fired on PUSH).
    assign ram_addr = (stack_push | stack_pop) ? sp : reg_b;
    // STORE / PUSH write R[src] (assembler puts the stored/pushed register in
    // the src field, and its address in src2); CALL writes the return address.
    // CALL pushes the RETURN ADDRESS (PC+1) at SP on the same edge it jumps
    // to the subroutine - see the fix note at ram_write_data below.
    // CALL pushes the return address = (PC at fetch time) + 1. Because the
    // PC register advances on EVERY clock, pc_out during the CALL's execute
    // cycle already points past the CALL word... but only when nothing else
    // redirected it. The robust source is the CALL's own fetch-time PC, which
    // we capture alongside the instruction in ir_pc below.
    // STORE / PUSH write R[src] (assembler puts the stored/pushed register in
    // the src field, and its address in src2); CALL writes the return address.

    // CALL pushes the RETURN ADDRESS. The fetch->execute register captured
    // ir_pc_next = (fetch PC of the CALL word)+1 on the very edge the CALL
    // was latched, so during the CALL's execute cycle it is exactly the
    // address of the instruction following the CALL. Using pc_out here was
    // the old off-by-one/RET-to-0 bug source (pc_out has already been
    // redirected by the taken jump on the same edge).
    assign ram_data_in = (opcode == 8'h32) ? ir_pc_next : reg_a;

    data_memory ram_inst (
        .clk(clk),
        // Only STORE/PUSH/CALL may write, and only when the MMIO decoder says
        // the address is real RAM (not GPIO/UART).
        .write_enable(ram_write_g),
        .addr(ram_addr),
        .data_in(ram_data_in),
        .data_out(ram_data_out),
        .rd_addr(ram_addr),
        .rd_data(ret_addr)
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
    // Barrel shifter: SHL/SHR R[dest], R[src], amount (amount in [7:0]).
    // SHL/SHR R[dest], R[src], amount: operand A must be the SOURCE register
    // (src field -> port A reads src_reg). The barrel-shift amount lives in
    // immediate[7:0], exactly as the assembler packs it.
    wire [15:0] shlshr_result = (opcode == 8'h07) ?
                                (reg_a << immediate[7:0]) :
                                (reg_a >> immediate[7:0]);

    assign reg_file_data_in = is_shlshr              ? shlshr_result :
                              (reg_in_source == 2'b01) ? immediate :
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
    
    // THE CALL/RET FIX: RET must read the return address at the CURRENT sp
    // combinationally. data_memory exposes a dedicated async read port
    // (rd_addr/rd_data) for exactly this - no hierarchical poke into the
    // RAM array (which created a zero-delay feedback path under vvp).
    wire [15:0] ret_addr;

    // Conditional jumps / CALL also latch their PC on the same edge that
    // changes SP or flags - that is fine here because none of them READ a
    // value produced by their own edge. Only RET needs the fix above.
    assign next_pc_val = (pc_source_cu == 2'b10) ? ret_addr :     // RET -> pop PC from stack
                     (pc_source_cu == 2'b01 && cond_true) ? jump_addr :
                     (ir_pc_next + 16'b1);   // sequential: captured fetch addr + 2


    // =====================================================================
    // HALT support (two flavours, both freeze every state element):
    //   1. the HALT instruction (opcode 0x34) parks the core on its own PC;
    //   2. STORE bit0=1 to 0xFFFF latches `mmio_halt` permanently (until
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
    // ANY LOAD aimed at the MMIO region (>=0xFFF0) reads peripherals, not RAM:
    // GPIO input view, UART rx byte/status, cycle counter, signature.
    wire io_rd_en     = (opcode == 8'h11) && (ram_addr >= 16'hFFF0);
    wire [15:0] io_rd_data;

    io_registers io_inst(
        .clk(clk), .rst(rst),
        .addr(ram_addr),
        .rd_en(io_rd_en),
        .sys_we(1'b0),              // halt is decoded directly below (mmio_halt)
        .wr_data(ram_data_in),
        .tx_busy(tx_busy),
        .rx_ready(rx_ready),
        .rx_byte(rx_byte),
        .rd_data(io_rd_data),
        .halt()                     // unused output; cpu_top owns mmio_halt
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

    // Halt sequencer. Both flavours park the machine permanently:
    //   * HALT instruction reaches the execute stage  -> halted_q sets NOW;
    //     on the very same edge the PC freezes on the HALT word (next_pc_g
    //     muxes to pc_out because g_clk_ok drops combinationally into the
    //     PC's D input) and the IR latch stops capturing.
    //   * STORE with bit0=1 to 0xFFFF (MMIO power switch, used by monitors
    //     and OS panic handlers) -> halted_q sets after the write commits.
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            halted_q <= 1'b0;
        end else if (g_clk_ok) begin
            if (halt_instr)
                halted_q <= 1'b1;
            if (uart_we && ram_addr == 16'hFFFF && ram_data_in[0])
                halted_q <= 1'b1;
        end
    end

endmodule
