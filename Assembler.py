binary=['0000000000000000000000010010011','0000000100000000000000100010011',
        '0000000000100001000000010010011','00000000000100010001000101100011']

for i in range(4):
    print(format(int(binary[i],2),'X'))
    print()
# RV32I Assembler in Python
# Supports R, I, S, B, U, J type instructions

opcode_map = {
    "R": "0110011",
    "I": "0010011",
    "IL": "0000011",
    "S": "0100011",
    "B": "1100011",
    "U": "0110111",
    "J": "1101111",
}

funct3_map = {
    "add": "000", "sub": "000", "sll": "001", "slt": "010", "sltu": "011",
    "xor": "100", "srl": "101", "sra": "101", "or": "110", "and": "111",
    "addi": "000", "xori": "100", "ori": "110", "andi": "111",
    "slli": "001", "srli": "101", "srai": "101",
    "lb": "000", "lh": "001", "lw": "010", "lbu": "100", "lhu": "101",
    "sb": "000", "sh": "001", "sw": "010",
    "beq": "000", "bne": "001", "blt": "100", "bge": "101",
    "bltu": "110", "bgeu": "111"
}

funct7_map = {
    "add": "0000000", "sub": "0100000", "sll": "0000000",
    "slt": "0000000", "sltu": "0000000", "xor": "0000000",
    "srl": "0000000", "sra": "0100000", "or": "0000000", "and": "0000000"
}

registers = {
    "zero": "00000", "ra": "00001", "sp": "00010", "gp": "00011",
    "tp": "00100", "t0": "00101", "t1": "00110", "t2": "00111",
    "s0": "01000", "s1": "01001", "a0": "01010", "a1": "01011",
    "a2": "01100", "a3": "01101", "a4": "01110", "a5": "01111",
    "a6": "10000", "a7": "10001", "s2": "10010", "s3": "10011",
    "s4": "10100", "s5": "10101", "s6": "10110", "s7": "10111",
    "s8": "11000", "s9": "11001", "s10": "11010", "s11": "11011",
    "t3": "11100", "t4": "11101", "t5": "11110", "t6": "11111"
}

def get_register_bin(reg):
    return registers.get(reg, "00000")

def imm_to_bin(imm, bits):
    return format(int(imm) & ((1 << bits) - 1), f'0{bits}b')

def assemble_instruction(instruction):
    parts = instruction.replace(",", "").split()
    inst = parts[0]

    if inst in funct3_map and inst in funct7_map:  # R-Type
        rd, rs1, rs2 = parts[1], parts[2], parts[3]
        return funct7_map[inst] + get_register_bin(rs2) + get_register_bin(rs1) + funct3_map[inst] + get_register_bin(rd) + opcode_map["R"]
    
    elif inst in ["addi", "xori", "ori", "andi", "slli", "srli", "srai"]:  # I-Type
        rd, rs1, imm = parts[1], parts[2], parts[3]
        return imm_to_bin(imm, 12) + get_register_bin(rs1) + funct3_map[inst] + get_register_bin(rd) + opcode_map["I"]

    elif inst in ["lw", "lh", "lb", "lhu", "lbu"]:  # Load (I-Type)
        rd, offset_reg = parts[1], parts[2]
        offset, rs1 = offset_reg.split("(")
        rs1 = rs1[:-1]
        return imm_to_bin(offset, 12) + get_register_bin(rs1) + funct3_map[inst] + get_register_bin(rd) + opcode_map["IL"]

    elif inst in ["sb", "sh", "sw"]:  # S-Type
        rs2, offset_reg = parts[1], parts[2]
        offset, rs1 = offset_reg.split("(")
        rs1 = rs1[:-1]
        imm_bin = imm_to_bin(offset, 12)
        return imm_bin[:7] + get_register_bin(rs2) + get_register_bin(rs1) + funct3_map[inst] + imm_bin[7:] + opcode_map["S"]

    elif inst in ["beq", "bne", "blt", "bge", "bltu", "bgeu"]:  # B-Type
        rs1, rs2, imm = parts[1], parts[2], parts[3]
        imm_bin = imm_to_bin(imm, 13)  # 13-bit for sign extension
        return imm_bin[0] + imm_bin[2:8] + get_register_bin(rs2) + get_register_bin(rs1) + funct3_map[inst] + imm_bin[8:12] + imm_bin[1] + opcode_map["B"]

    elif inst in ["lui", "auipc"]:  # U-Type
        rd, imm = parts[1], parts[2]
        return imm_to_bin(imm, 20) + get_register_bin(rd) + opcode_map["U"]

    elif inst == "jal":  # J-Type
        rd, imm = parts[1], parts[2]
        imm_bin = imm_to_bin(imm, 21)
        return imm_bin[0] + imm_bin[10:20] + imm_bin[9] + imm_bin[1:9] + get_register_bin(rd) + opcode_map["J"]

    else:
        return "ERROR: Unknown instruction"

def assemble_code(code):
    lines = code.strip().split("\n")
    machine_code = [assemble_instruction(line.strip()) for line in lines]
    for i in machine_code:
        code=format(int(i,2),'X')
        s=''
        for j in range(8-len(code)):s+='0'
        print(s+code)
    #return "\n".join()

# Example Assembly Code
assembly_code = """
addi zero, ra, 0
addi x0, x2, 8
addi x1, x1, 1
bne x1, x2, 2
lw x6, 20(x7)
sw x8, 30(x9)
lui x12, 100000
jal x13, 2000
"""

# Convert to Machine Code
machine_code = assemble_code(assembly_code)
