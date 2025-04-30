
# RISC-V Single-Cycle Processor (RV32I)

This project implements a **single-cycle RISC-V processor** in Verilog, supporting the **RV32I** base integer instruction set. The processor executes one instruction per clock cycle and includes modules for instruction decode, control logic, ALU, data memory, register file, and program counter logic.

---

## 🛠 Features

- **RV32I ISA support** (Integer base instruction set)
- **Single-cycle execution** (one instruction per clock)
- Basic instructions: arithmetic, logical, load/store, branch, and jump
- Separate instruction and data memory modules
- Immediate extension and ALU control
- Modular Verilog design with clear separation of functionality

---

## 🧩 Module Overview

| Module Name         | Description |
|---------------------|-------------|
| `RISCV`             | Top-level processor module |
| `ALU`               | Arithmetic Logic Unit for operations like ADD, SUB, AND, OR, XOR, SLT, SLL, SRL |
| `PCreg`             | Program Counter register |
| `PCalu`             | Calculates next PC value (PC + offset) |
| `mux32bit2_1`, `mux32bit4_1` | 2:1 and 4:1 multiplexers for control decisions |
| `instruction_memory`| 64-entry instruction memory |
| `data_memory`       | 64-entry data memory (byte addressable) |
| `regfile`           | 32-register file with read/write logic |
| `extender`          | Extends immediate values based on instruction type |
| `rv32i_controller`  | Control unit to generate control signals based on opcode, func3, func7 |

---

## 📁 File Structure

```
├── RISCV.v               # Top module and processor integration
├── ALU.v                 # ALU implementation
├── PCreg.v               # PC register
├── PCalu.v               # PC calculation logic
├── muxes.v               # Multiplexers (2:1 and 4:1)
├── instruction_memory.v  # 64-entry instruction ROM
├── data_memory.v         # 64-entry RAM with byte addressability
├── regfile.v             # 32-register file
├── extender.v            # Immediate generator
├── rv32i_controller.v    # Control logic for RV32I ISA
├── README.md             # This file
```

---

## 🧪 Sample Program in Instruction Memory

```verilog
RAM[0] = 32'b0000000000000000000000010010011; // ADDI x2, x0, 0
RAM[1] = 32'b0000000100000000000000100010011; // ADDI x4, x0, 16
RAM[2] = 32'b0000000000100001000000010010011; // ADDI x2, x2, 2
RAM[3] = 32'b00000000000100010001000101100011; // BEQ x2, x1, offset
```

Feel free to modify `instruction_memory` to test custom instruction sequences.

---

## 🔧 How to Run

1. **Clone this repo** or copy the Verilog files into your project directory.
2. Use a simulator such as **ModelSim**, **Icarus Verilog**, or **Vivado**.
3. Set `RISCV` as the top module.
4. Observe outputs like:
   - `instruction` – the current instruction being executed
   - `memory_address` – address used for load/store
   - `write_data` – asserted high during store

---

## ✅ Supported Instructions

- Arithmetic: `ADD`, `SUB`, `ADDI`
- Logic: `AND`, `OR`, `XOR`, `SLL`, `SRL`
- Comparison: `SLT`
- Memory: `LW`, `SW`
- Branches: `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`
- Jumps: `JAL`, `JALR`

> **Note**: `LUI`, `AUIPC`, and ECALL are not currently supported.

---

## 📌 To Do / Improvements

- Add support for `LUI`, `AUIPC`, and `JALR` fully
- Implement a multi-cycle or pipelined version
- Include hazard detection and forwarding
- Write testbenches for automated verification

---
