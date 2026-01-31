# Fixing Red Highlighting in VS Code for Verilog Modules

## Why Modules Show in Red

When you see module names like `decoder`, `PCreg`, `mux32bit2_1`, etc. highlighted in **red** in your `riscv_core.v` file, it's because:

1. **Your IDE (VS Code) can't find the module definitions** - The modules are defined in separate files (`decoder.v`, `reg_file.v`, `ALU.v`, etc.)
2. **The Verilog linter is checking each file independently** - It doesn't know about the other files unless configured

## This is NORMAL and doesn't affect compilation!

The red highlighting is just a **visual warning** from your editor. Your code **compiles and runs perfectly** with Icarus Verilog because we compile all files together.

## How to Fix the Red Highlighting

### Option 1: Configure VS Code (RECOMMENDED)

I've created a `.vscode/settings.json` file that configures the Verilog extension to:
- Use Icarus Verilog as the linter
- Include all files in the workspace when checking
- Reduce false error warnings

**You may need to reload VS Code** for the settings to take effect:
1. Press `Ctrl+Shift+P`
2. Type "Reload Window"
3. Press Enter

### Option 2: Ignore the Red Highlighting

The red highlighting doesn't affect your code's functionality. As long as compilation works (which it does!), you can safely ignore it.

### Option 3: Install a Better Verilog Extension

Try these VS Code extensions:
- **Verilog-HDL/SystemVerilog** by mshr-h (most popular)
- **TerosHDL** (more advanced, supports multi-file projects better)

## Compilation Commands

```powershell
# Compile the design
iverilog -o riscv_core.vvp riscv_core_tb.v riscv_core.v decoder.v reg_file.v ins_mem.v ALU.v data_mem.v mux.v extender.v

# Run simulation
vvp riscv_core.vvp

# View waveforms
gtkwave riscv_core_tb.vcd
```

## Summary

✅ **Your code is correct and compiles successfully**  
✅ **The simulation runs without errors**  
⚠️ **Red highlighting is just an IDE limitation** - it can be ignored or fixed with proper configuration
