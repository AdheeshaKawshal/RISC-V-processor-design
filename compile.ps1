# Compile RISC-V Core with Icarus Verilog
# This script compiles all the necessary Verilog files together

# Compile the design with testbench
iverilog -o riscv_core.vvp `
    RISCV_tb.v `
    riscv_core.v `
    decoder.v `
    reg_file.v `
    ins_mem.v `
    ALU.v `
    data_mem.v `
    mux.v `
    extender.v

# Check if compilation was successful
if ($LASTEXITCODE -eq 0) {
    Write-Host "Compilation successful! Output: riscv_core.vvp" -ForegroundColor Green
    Write-Host ""
    Write-Host "To run the simulation, use:" -ForegroundColor Cyan
    Write-Host "  vvp riscv_core.vvp" -ForegroundColor Yellow
} else {
    Write-Host "Compilation failed with errors!" -ForegroundColor Red
    exit 1
}
