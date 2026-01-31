//==============================================================================
// 2-to-1 Multiplexer (32-bit) - RISC-V Processor
//==============================================================================
// Selects between two 32-bit inputs based on a 1-bit select signal.
//
// SYNTHESIS: This module is FULLY SYNTHESIZABLE for FPGA/ASIC implementation.
//
// Operation:
//   - select = 0: output = in1
//   - select = 1: output = in2
//
// Usage Examples:
//   - ALU source selection (register vs immediate)
//   - Result selection (ALU output vs memory data)
//   - Data path routing
//==============================================================================

module mux32bit2_1 (
    input  wire [31:0] in1,         // Input 0 (selected when select=0)
    input  wire [31:0] in2,         // Input 1 (selected when select=1)
    input  wire        select,      // Select signal (0 or 1)
    output wire [31:0] out          // Output (either in1 or in2)
);

    //==========================================================================
    // Multiplexer Logic
    //==========================================================================
    // Simple conditional assignment - synthesizes to 2:1 mux
    assign out = select ? in2 : in1;

endmodule


//==============================================================================
// 4-to-1 Multiplexer (32-bit) - RISC-V Processor
//==============================================================================
// Selects between four 32-bit inputs based on a 2-bit select signal.
//
// SYNTHESIS: This module is FULLY SYNTHESIZABLE for FPGA/ASIC implementation.
//
// Operation:
//   - select = 00: output = in1
//   - select = 01: output = in2
//   - select = 10: output = in3
//   - select = 11: output = in4
//
// Usage Examples:
//   - PC source selection (PC+1, PC+imm, ALU result, or immediate)
//   - Multi-way data path routing
//==============================================================================

module mux32bit4_1 (
    input  wire [31:0] in1,         // Input 00
    input  wire [31:0] in2,         // Input 01
    input  wire [31:0] in3,         // Input 10
    input  wire [31:0] in4,         // Input 11
    input  wire [1:0]  select,      // 2-bit select signal
    output reg  [31:0] out          // Output (one of the four inputs)
);

    //==========================================================================
    // Multiplexer Logic
    //==========================================================================
    // Case statement for 4-way selection - synthesizes to 4:1 mux
    
    always @(*) begin
        case (select)
            2'b00:   out = in1;
            2'b01:   out = in2;
            2'b10:   out = in3;
            2'b11:   out = in4;
            default: out = 32'h00000000;  // Default to zero (should never occur)
        endcase
    end

endmodule
