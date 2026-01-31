//==============================================================================
// Instruction Memory (ROM) - RISC-V Processor
//==============================================================================
// This module implements the instruction memory as a read-only memory (ROM).
// It loads program instructions from a memory file and provides them to the
// processor based on the program counter (PC) address.
//
// SYNTHESIS: This module is SYNTHESIZABLE for FPGA implementation.
// Modern FPGA synthesis tools (Xilinx Vivado, Intel Quartus) support $readmemh
// for initializing block RAM. For ASIC, you may need to use a different approach.
//
// Parameters:
//   - Address width: 32 bits (only lower 6 bits used for 64-word ROM)
//   - Data width: 32 bits (RISC-V instruction width)
//   - Memory depth: 64 words (addresses 0-63)
//
// Memory File Format:
//   - Create a file named "instructions.mem" in the same directory
//   - Each line contains one 32-bit instruction in hexadecimal format
//   - Example instructions.mem:
//     00000013
//     00000093
//     002081B3
//==============================================================================

module ins_mem (
    input  wire        clk,     // Clock signal
    input  wire        rst_n,   // Active-low reset
    input  wire [31:0] addr,    // Address input (32-bit, only [5:0] used)
    output reg  [31:0] rd       // 32-bit instruction output
);

    //==========================================================================
    // ROM Memory Array
    //==========================================================================
    // 64 locations of 32 bits each
    reg [31:0] ROM [0:63];
    integer i;
    
    //==========================================================================
    // Synchronous Reset and Read Logic
    //==========================================================================
    // Initialize ROM on reset and provide synchronous read
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset: Initialize all locations to NOP (addi x0, x0, 0)
            for (i = 0; i < 64; i = i + 1) begin
                ROM[i] <= 32'h00000013;  // NOP instruction
            end
        
        // Load program from memory file
        // If file doesn't exist, ROM will contain all NOPs
        $readmemh("instructions.mem", ROM);
    end
    
    //==========================================================================
    // Asynchronous Read
    //==========================================================================
    // Output instruction at the specified address
    assign rd = ROM[addr[5:0]];
    end
endmodule