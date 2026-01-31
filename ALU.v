//==============================================================================
// Arithmetic Logic Unit (ALU) - RISC-V Processor
//==============================================================================
// This module implements the ALU for the RISC-V processor.
// It performs arithmetic and logical operations based on the ALU operation code.
//
// SYNTHESIS: This module is FULLY SYNTHESIZABLE for FPGA/ASIC implementation.
//
// Supported Operations:
//   0000 (0): AND    - Bitwise AND
//   0001 (1): OR     - Bitwise OR
//   0010 (2): ADD    - Addition
//   0011 (3): SUB    - Subtraction
//   0100 (4): XOR    - Bitwise XOR
//   0101 (5): NOR    - Bitwise NOR
//   0110 (6): SLL    - Shift Left Logical
//   0111 (7): SRL    - Shift Right Logical
//   1000 (8): SLT    - Set Less Than (signed comparison)
//
// Outputs:
//   - ALUOut: 32-bit result of the operation
//   - Zero: Flag indicating if result is zero (used for branch decisions)
//==============================================================================

module ALU (
    input  wire [3:0]  ALUop,       // ALU operation selector
    input  wire [31:0] ALUinA,      // First operand
    input  wire [31:0] ALUinB,      // Second operand
    output reg  [31:0] ALUOut,      // ALU result
    output reg         Zero         // Zero flag (1 if ALUOut == 0)
);

    //==========================================================================
    // ALU Operation Logic
    //==========================================================================
    // Combinational logic - result computed based on ALUop selector
    
    always @(*) begin
        case (ALUop)
            4'b0000: ALUOut = ALUinA & ALUinB;              // AND
            4'b0001: ALUOut = ALUinA | ALUinB;              // OR
            4'b0010: ALUOut = ALUinA + ALUinB;              // ADD
            4'b0011: ALUOut = ALUinA - ALUinB;              // SUB
            4'b0100: ALUOut = ALUinA ^ ALUinB;              // XOR
            4'b0101: ALUOut = ~(ALUinA | ALUinB);           // NOR
            4'b0110: ALUOut = ALUinA << ALUinB[4:0];        // SLL (shift left)
            4'b0111: ALUOut = ALUinA >> ALUinB[4:0];        // SRL (shift right)
            4'b1000: ALUOut = ($signed(ALUinA) < $signed(ALUinB)) ? 32'b1 : 32'b0;  // SLT (signed)
            default: ALUOut = 32'b0;                        // Default: output zero
        endcase
        
        // Zero flag: Set to 1 if ALU result is zero
        // Used primarily for branch instructions (BEQ, BNE)
        Zero = (ALUOut == 32'b0) ? 1'b1 : 1'b0;
    end

endmodule


//==============================================================================
// PC Arithmetic Unit - RISC-V Processor
//==============================================================================
// This module calculates the target PC for branches and jumps.
// It performs simple addition: targetpc = pc + imm
//
// SYNTHESIS: This module is FULLY SYNTHESIZABLE for FPGA/ASIC implementation.
//
// Usage:
//   - Branch target calculation: PC + sign-extended immediate
//   - Sequential PC: PC + 1 (when imm = 1)
//   - Jump target calculation: PC + jump offset
//
// Note: This is a dedicated adder separate from the main ALU to allow
// parallel computation of next PC and ALU operations.
//==============================================================================

module PCalu (
    input  wire [31:0] pc,          // Current program counter
    input  wire [31:0] imm,         // Immediate value (offset)
    output reg  [31:0] targetpc     // Target PC (pc + imm)
);

    //==========================================================================
    // PC Addition Logic
    //==========================================================================
    // Simple combinational adder for PC calculation
    
    always @(*) begin
        targetpc = pc + imm;
    end

endmodule
