//==============================================================================
// RISC-V Core Testbench
//==============================================================================
// This testbench simulates the RISC-V processor core and generates waveforms
// for viewing in GTKWave.
//==============================================================================

`include "riscv_core.v"
`timescale 1ns / 1ps

module tb_riscv_core;

    //==========================================================================
    // Testbench Signals
    //==========================================================================
    reg clk;
    reg rst;
    
    // Outputs from the core
    wire [31:0] instruction;
    wire [31:0] memory_address;
    wire [2:0]  func3;
    wire        write_data;
    
    // Inputs to the core (unused in this simple test)
    reg [31:0] pc;
    reg [31:0] read_data;
    
    // Internal signals for monitoring
    integer cycle_count;

    //==========================================================================
    // DUT (Device Under Test) Instantiation
    //==========================================================================
    riscv_core uut (
        .clk(clk),
        .rst(rst),
        .instruction(instruction),
        .pc(pc),
        .read_data(read_data),
        .memory_address(memory_address),
        .func3(func3),
        .write_data(write_data)
    );

    //==========================================================================
    // Clock Generation
    //==========================================================================
    // Generate 100MHz clock (10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    //==========================================================================
    // Cycle Counter
    //==========================================================================
    always @(posedge clk) begin
        if (!rst)
            cycle_count <= 0;
        else
            cycle_count <= cycle_count + 1;
    end

    //==========================================================================
    // Signal Monitoring
    //==========================================================================
    always @(posedge clk) begin
        if (rst) begin
            $display("Cycle %0d: PC=%h | Instr=%h | MemAddr=%h | MemWE=%b", 
                     cycle_count, uut.next_pc, instruction, memory_address, write_data);
        end
    end

    //==========================================================================
    // Test Stimulus
    //==========================================================================
    initial begin
        // Initialize signals
        rst = 0;
        pc = 32'h00000000;
        read_data = 32'h00000000;
        cycle_count = 0;
        
        // Create VCD file for GTKWave
        $dumpfile("riscv_core_tb.vcd");
        $dumpvars(0, tb_riscv_core);
        
        // Also dump internal signals for better debugging
        $dumpvars(1, uut.regfile.reg_file[0]);
        $dumpvars(1, uut.regfile.reg_file[1]);
        $dumpvars(1, uut.regfile.reg_file[2]);
        $dumpvars(1, uut.regfile.reg_file[3]);
        $dumpvars(1, uut.regfile.reg_file[4]);
        $dumpvars(1, uut.regfile.reg_file[5]);
        
        $display("========================================");
        $display("RISC-V Core Testbench Starting");
        $display("========================================");
        
        // Apply reset for 20ns
        $display("Applying reset...");
        #20;
        rst = 1;
        $display("Reset released at time %0t", $time);
        
        // Run simulation for enough cycles to execute instructions
        #500;
        
        // Display final register values
        $display("\n========================================");
        $display("Final Register File State:");
        $display("========================================");
        $display("x0  = %h", uut.regfile.reg_file[0]);
        $display("x1  = %h", uut.regfile.reg_file[1]);
        $display("x2  = %h", uut.regfile.reg_file[2]);
        $display("x3  = %h", uut.regfile.reg_file[3]);
        $display("x4  = %h", uut.regfile.reg_file[4]);
        $display("x5  = %h", uut.regfile.reg_file[5]);
        
        // End simulation
        $display("\n========================================");
        $display("Simulation completed successfully!");
        $display("Total cycles: %0d", cycle_count);
        $display("VCD file: riscv_core_tb.vcd");
        $display("========================================");
        $finish;
    end
    
    //==========================================================================
    // Timeout Watchdog
    //==========================================================================
    initial begin
        #10000;
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule
