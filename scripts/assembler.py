import sys

# 16-bit CPU assembler - matches the opcode map in control_unit.v
# Instruction format (32 bits):
#   opcode[31:24] | dest[19:16] | src[15:12] | src2[11:8] | imm/pad[7:0]
#   For LI / jumps / CALL the 16-bit immediate lives in instruction[15:0]

def assemble(input_file, output_file):
    # Define our Instruction Set (now a full byte-wide opcode)
    opcodes = {
        'NOP': 0x00, 'ADD': 0x01, 'SUB': 0x02, 'AND': 0x03,
        'OR': 0x04, 'NAND': 0x05, 'XOR': 0x06, 'SHL': 0x07,
        'SHR': 0x08, 'CMP': 0x09,
        'LI': 0x10, 'LOAD': 0x11, 'STORE': 0x12,
        'JMP': 0x20, 'JZ': 0x21, 'JNZ': 0x22, 'JC': 0x23,
        'JNC': 0x24, 'JN': 0x25, 'JNN': 0x26,
        'PUSH': 0x30, 'POP': 0x31, 'CALL': 0x32, 'RET': 0x33,
        'HALT': 0x34
    }

    # R0..R15, all 4 bits wide now
    registers = {'R%d' % i: i for i in range(16)}

    reg_reg_ops   = ['ADD', 'SUB', 'AND', 'OR', 'NAND', 'XOR', 'CMP']
    reg_imm_ops   = ['SHL', 'SHR']              # R[dest] = R[src] shifted by imm
    reg_reg_dest  = ['LOAD', 'STORE']           # LOAD dest,[src2] / STORE src,[src2]
    reg_only_ops  = ['PUSH', 'POP']             # PUSH R[src] / POP R[dest]
    jump_ops      = ['JMP', 'JZ', 'JNZ', 'JC', 'JNC', 'JN', 'JNN', 'CALL']

    lines = []
    symbol_table = {}
    address_counter = 0

    # --- PASS 1: Find Labels ---
    with open(input_file, 'r') as f:
        for line in f:
            line = line.split('//')[0].split(';')[0].strip() # Remove comments
            if not line: continue

            # Check if line is a label (ends with :)
            if line.endswith(':'):
                label_name = line[:-1]
                symbol_table[label_name] = address_counter
            else:
                # It's an instruction, so it takes up one memory slot
                address_counter += 1

    def parse_num(text):
        text = text.strip()
        if text.lower().startswith('0x'):
            return int(text, 16)
        return int(text)

    # --- PASS 2: Generate Machine Code ---
    instructions = []
    errors = []
    with open(input_file, 'r') as f:
        for raw in f:
            line = raw.split('//')[0].split(';')[0].strip()
            if not line or line.endswith(':'): continue # Skip empty lines and labels

            parts = line.replace(',', ' ').split()
            mnemonic = parts[0].upper()

            if mnemonic not in opcodes:
                errors.append(f"Error: Unknown instruction '{mnemonic}' in line: {line}")
                continue

            opcode = opcodes[mnemonic]
            dest = src = src2 = 0
            imm = 0

            try:
                if mnemonic in ('NOP', 'RET', 'HALT'):
                    pass

                elif mnemonic in reg_reg_ops:
                    # ADD/SUB/... R[dest], R[src]        -> src2 field = R[src]
                    #           R[dst], R[a], R[b]       -> dst = R[a] op R[b]
                    if len(parts) < 3: raise ValueError(f"{mnemonic} requires two operands")
                    if len(parts) >= 4:
                        dest = registers[parts[1].upper()]
                        src  = registers[parts[2].upper()]
                        src2 = registers[parts[3].upper()]
                    else:
                        dest = registers[parts[1].upper()]
                        src  = registers[parts[2].upper()]
                        src2 = src

                elif mnemonic in reg_imm_ops:
                    # SHL/SHR R[dest], R[src], amount   (amount 0..15)
                    if len(parts) < 4: raise ValueError(f"{mnemonic} requires R[dest], R[src], amount")
                    dest = registers[parts[1].upper()]
                    src  = registers[parts[2].upper()]
                    src2 = 0                     # cpu_top reads port C as the shift value
                    imm  = parse_num(parts[3]) & 0xF

                elif mnemonic == 'LI':
                    # LI R[dest], imm16
                    if len(parts) < 3: raise ValueError("LI requires a destination register")
                    dest = registers[parts[1].upper()]
                    imm = parse_num(parts[2]) & 0xFFFF

                elif mnemonic in reg_reg_dest:
                    # LOAD R[dest], R[src2]  /  STORE R[src], R[src2]
                    if len(parts) < 3: raise ValueError(f"{mnemonic} requires two operands")
                    if mnemonic == 'LOAD':
                        dest = registers[parts[1].upper()]
                        src2 = registers[parts[2].upper()]
                    else:
                        src = registers[parts[1].upper()]
                        src2 = registers[parts[2].upper()]

                elif mnemonic in reg_only_ops:
                    # PUSH R[src] / POP R[dest]
                    if len(parts) < 2: raise ValueError(f"{mnemonic} requires a register")
                    if mnemonic == 'PUSH':
                        src = registers[parts[1].upper()]
                    else:
                        dest = registers[parts[1].upper()]

                elif mnemonic in jump_ops:
                    # JMP/JZ/.../CALL label-or-address (16-bit)
                    if mnemonic != 'CALL' and len(parts) < 2:
                        raise ValueError(f"{mnemonic} requires an address")
                    if len(parts) >= 2:
                        target = parts[1]
                        # Check if target is a label or a raw number
                        if target in symbol_table:
                            addr = symbol_table[target]
                        else:
                            addr = parse_num(target)
                        imm = addr & 0xFFFF
                    if mnemonic == 'CALL':
                        # CALL also accepts "CALL label, Rn" to put the
                        # return value in R[n]
                        if len(parts) >= 3:
                            dest = registers[parts[2].upper()]

                # The hardware takes the operand of LI / jumps / CALL from
                # instruction[15:0], so for those opcodes the full 16-bit
                # immediate must be placed there (src/src2 fields overlap
                # with it and are forced to 0).  SHL/SHR keep their shift
                # amount in [3:0] only.
                if mnemonic in ('LI',) or mnemonic in jump_ops:
                    src = src2 = 0
                    word = ((opcode & 0xFF) << 24) | ((dest & 0xF) << 16) | \
                           (imm & 0xFFFF)
                else:
                    word = ((opcode & 0xFF) << 24) | ((dest & 0xF) << 16) | \
                           ((src & 0xF) << 12) | ((src2 & 0xF) << 8) | (imm & 0xFF)
                instructions.append(word)

            except KeyError:
                errors.append(f"Error: Bad register name in line: {line}")
            except ValueError as e:
                errors.append(f"Error: {e} in line: {line}")

    if errors:
        for e in errors:
            print(e)
        sys.exit(1)

    # --- Write Verilog Output ---
    with open(output_file, 'w') as f:
        f.write("module instruction_memory(\n")
        f.write("    input wire [15:0] addr,\n")
        f.write("    output wire [31:0] instruction\n")
        f.write(");\n\n")
        f.write("    reg [31:0] mem [0:65535];\n\n")
        f.write("    initial begin\n")

        for i, word in enumerate(instructions):
            f.write(f"        mem[{i}] = 32'h{word:08X}; // Address {i}\n")

        f.write("    end\n\n")
        f.write("    assign instruction = mem[addr];\n")
        f.write("endmodule\n")

    print(f"Successfully assembled {len(instructions)} instructions into {output_file}")
    print(f"Symbols found: {symbol_table}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python assembler.py input.asm output.v")
    else:
        assemble(sys.argv[1], sys.argv[2])
