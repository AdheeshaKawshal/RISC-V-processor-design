# RISC-V Core Simulation and Waveform Viewer Script
# This script compiles the design, runs the simulation, and opens GTKWave

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RISC-V Core Simulation Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Step 1: Compile the design
Write-Host "`nStep 1: Compiling Verilog files..." -ForegroundColor Yellow
iverilog -o riscv_core_tb.vvp riscv_core_tb.v

if ($LASTEXITCODE -eq 0) {
    Write-Host "Compilation successful!" -ForegroundColor Green
} else {
    Write-Host "Compilation failed!" -ForegroundColor Red
    exit 1
}

# Step 2: Run the simulation
Write-Host "`nStep 2: Running simulation..." -ForegroundColor Yellow
vvp riscv_core_tb.vvp

if ($LASTEXITCODE -eq 0) {
    Write-Host "Simulation completed!" -ForegroundColor Green
} else {
    Write-Host "Simulation failed!" -ForegroundColor Red
    exit 1
}

# Step 3: Check if VCD file was generated
if (Test-Path "riscv_core_tb.vcd") {
    Write-Host "`nVCD file generated successfully!" -ForegroundColor Green
    
    # Step 4: Open GTKWave
    Write-Host "`nStep 3: Opening GTKWave..." -ForegroundColor Yellow
    gtkwave riscv_core_tb.vcd
} else {
    Write-Host "`nERROR: VCD file not found!" -ForegroundColor Red
    exit 1
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Script completed!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
