import sys

def assemble(input_file, output_file):
    # Define our Instruction Set
    opcodes = {
        'NOP': '0000', 'ADD': '0001', 'SUB': '0010', 'AND': '0011',
        'OR': '0100', 'LI': '0101', 'LOAD': '0110', 'STORE': '0111',
        'JMP': '1000', 'JZ': '1001'
    }
    
    registers = {'R0': '00', 'R1': '01', 'R2': '10', 'R3': '11'}

    lines = []
    symbol_table = {}
    address_counter = 0

    # --- PASS 1: Find Labels ---
    with open(input_file, 'r') as f:
        for line in f:
            line = line.strip().split('//')[0].strip() # Remove comments
            if not line: continue
            
            # Check if line is a label (ends with :)
            if line.endswith(':'):
                label_name = line[:-1]
                symbol_table[label_name] = address_counter
            else:
                # It's an instruction, so it takes up one memory slot
                address_counter += 1

    # --- PASS 2: Generate Machine Code ---
    instructions = []
    with open(input_file, 'r') as f:
        for line in f:
            line = line.strip().split('//')[0].strip()
            if not line or line.endswith(':'): continue # Skip empty lines and labels
            
            parts = line.replace(',', '').split()
            mnemonic = parts[0].upper()
            
            if mnemonic not in opcodes:
                print(f"Error: Unknown instruction '{mnemonic}'")
                continue
                
            opcode_bin = opcodes[mnemonic]
            dest_bin = '00'
            src_bin = '00'
            
            if mnemonic in ['ADD', 'SUB', 'AND', 'OR', 'LI', 'LOAD', 'STORE']:
                if len(parts) < 3:
                    print(f"Error: {mnemonic} requires two operands")
                    continue
                dest_reg = parts[1].upper()
                src_val = parts[2]
                
                if dest_reg in registers:
                    dest_bin = registers[dest_reg]
                
                if mnemonic == 'LI':
                    src_bin = format(int(src_val), '02b')[-2:] 
                elif src_val in registers:
                    src_bin = registers[src_val]
                    
            elif mnemonic in ['JMP', 'JZ']:
                if len(parts) < 2:
                    print(f"Error: {mnemonic} requires an address")
                    continue
                
                target = parts[1]
                # Check if target is a label or a raw number
                if target in symbol_table:
                    addr = symbol_table[target]
                else:
                    addr = int(target)
                
                full_addr = format(addr, '04b')
                dest_bin = full_addr[:2]
                src_bin = full_addr[2:]

            instruction = f"{opcode_bin}{dest_bin}{src_bin}"
            instructions.append(instruction)

    # --- Write Verilog Output ---
    with open(output_file, 'w') as f:
        f.write("module instruction_memory(\n")
        f.write("    input wire [3:0] addr,\n")
        f.write("    output wire [7:0] instruction\n")
        f.write(");\n\n")
        f.write("    reg [7:0] mem [0:15];\n\n")
        f.write("    initial begin\n")
        
        for i, inst in enumerate(instructions):
            f.write(f"        mem[{i}] = 8'b{inst}; // Address {i}\n")
            
        for i in range(len(instructions), 16):
            f.write(f"        mem[{i}] = 8'b00000000; // Address {i}\n")
            
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