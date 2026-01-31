//==============================================================================
// Register File - RISC-V Processor
//==============================================================================
// This module implements the 32-register register file for the RISC-V processor.
// It provides two read ports and one write port for register access.
//
// SYNTHESIS: This module is FULLY SYNTHESIZABLE for FPGA/ASIC implementation.
// Uses synchronous reset and proper sequential logic.
//
// RISC-V Register File Specifications:
//   - 32 general-purpose registers (x0-x31)
//   - x0 is hardwired to zero (writes to x0 are ignored)
//   - 32-bit wide registers
//   - Two asynchronous read ports
//   - One synchronous write port (writes on positive clock edge)
//
// Note: Initial register values are set via reset, not initial blocks.
// For testing, you can modify the reset behavior to load specific values.
//==============================================================================

module reg_file (
    input  wire        clk,         // Clock signal
    input  wire        rst_n,       // Active-low reset
    input  wire        we,          // Write enable
    input  wire [4:0]  rs1,         // Read address 1 (source register 1)
    input  wire [4:0]  rs2,         // Read address 2 (source register 2)
    input  wire [4:0]  rs3,         // Write address (destination register)
    input  wire [31:0] data_in,     // Write data
    output wire [31:0] data_out1,   // Read data 1
    output wire [31:0] data_out2    // Read data 2
);
    //==========================================================================
    // Register Array - 32 registers of 32 bits each
    //==========================================================================
    reg [31:0] reg_file [0:31]; // 32-bit wide register array, 32 registers (x0-x31)
    integer i;

    //==========================================================================
    // Asynchronous Read Ports
    //==========================================================================
    assign data_out1 = reg_file[rs1];
    assign data_out2 = reg_file[rs2];
    
    //==========================================================================
    // Synchronous Write and Reset Logic
    //==========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset: Initialize all registers to zero
            for (i = 0; i < 32; i = i + 1) begin
                reg_file[i] <= 32'h00000000;
            end
        end else if (we && rs3 != 5'b00000) begin
            // Write to register (ignore writes to x0)
            // x0 is hardwired to zero in RISC-V architecture
            reg_file[rs3] <= data_in;
        end
    end

endmodule


module PCreg #(parameter pc_offset = 32'h00000000) (
    input clk,
    input [31:0] pcreg,
    output reg[31:0] out,
    input rst_n 

);  
    reg [31:0] PC;
    always @(posedge clk or negedge rst_n)begin 
       if(!rst_n) begin
        out<= pc_offset;
       end  
       else begin
        out <=pcreg;
       end
    end

endmodule