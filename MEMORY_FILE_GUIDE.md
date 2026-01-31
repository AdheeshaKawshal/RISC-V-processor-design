# RISC-V Processor - Memory File Instructions

## Instruction Memory (`instructions.mem`)

The instruction memory now loads programs from an external file called `instructions.mem`. This file should be placed in the same directory as your Verilog files.

### File Format

- **Format**: Hexadecimal (one instruction per line)
- **Width**: 32-bit instructions (8 hex digits)
- **No prefix**: Do NOT include `0x` prefix
- **Comments**: Lines starting with `//` or `#` are ignored

### Example `instructions.mem`

```
00000013    // NOP (addi x0, x0, 0)
00100093    // ADDI x1, x0, 1     (x1 = 1)
00200113    // ADDI x2, x0, 2     (x2 = 2)
002081B3    // ADD  x3, x1, x2    (x3 = x1 + x2 = 3)
00208233    // ADD  x4, x1, x2    (x4 = x1 + x2 = 3)
```

### RISC-V Instruction Encoding Quick Reference

#### R-Type (Register-Register)
```
func7[7] | rs2[5] | rs1[5] | func3[3] | rd[5] | opcode[7]
```
Example: `ADD x3, x1, x2` = `0000000 00010 00001 000 00011 0110011` = `0x002081B3`

#### I-Type (Immediate)
```
imm[12] | rs1[5] | func3[3] | rd[5] | opcode[7]
```
Example: `ADDI x1, x0, 1` = `000000000001 00000 000 00001 0010011` = `0x00100093`

### How to Create Your Program

1. **Write your RISC-V assembly code**
2. **Encode each instruction to hex** (use RISC-V assembler or manual encoding)
3. **Create `instructions.mem`** with one hex value per line
4. **Place the file** in the project directory

### Default Behavior

- If `instructions.mem` is not found, all memory locations default to NOP (`0x00000013`)
- Memory size: 64 instructions (addresses 0-63)
- Unused locations are filled with NOP

## Register File Reset

All registers (x0-x31) are now reset to `0x00000000` when the reset signal is asserted.

- **x0**: Always reads as 0 (RISC-V specification)
- **x1-x31**: Reset to 0, can be written during execution

## Testing Your Program

1. Create your `instructions.mem` file
2. Run simulation:
   ```powershell
   .\compile.ps1
   ```
3. View waveforms in GTKWave or your preferred viewer

## Notes

- The `$readmemh` function is **synthesizable for FPGAs** (Xilinx Vivado, Intel Quartus)
- For ASIC synthesis, you may need to convert to a ROM inference pattern
- Maximum program size: 64 instructions (can be increased by modifying ROM array size)
