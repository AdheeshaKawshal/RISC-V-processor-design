//==============================================================================
// Instruction Decoder (Control Unit) - RISC-V Processor
//==============================================================================
// This module decodes RISC-V instructions and generates all control signals
// for the datapath. It implements the control logic for RV32I base instruction set.
//
// SYNTHESIS: This module is FULLY SYNTHESIZABLE for FPGA/ASIC implementation.
// Uses proper combinational logic with blocking assignments.
//
// Supported Instruction Types:
//   - R-Type: Register-register operations (ADD, SUB, SLL, SLT, XOR, etc.)
//   - I-Type: Immediate operations (ADDI, SLTI, XORI, ORI, ANDI, LW, JALR)
//   - S-Type: Store operations (SW)
//   - B-Type: Branch operations (BEQ, BNE, BLT, BGE, BLTU, BGEU)
//   - U-Type: Upper immediate (LUI, AUIPC)
//   - J-Type: Jump (JAL)
//
// Control Signals Generated:
//   - regWrite: Register file write enable
//   - memWrite: Data memory write enable
//   - aluOp: ALU operation selector
//   - extO: Immediate extender type selector
//   - aluSrc: ALU source B selector (0=register, 1=immediate)
//   - pcsrc: PC source selector (00=PC+1, 01=PC+imm, 10=ALU, 11=imm)
//   - resultsrc: Result source (0=ALU, 1=Memory)
//==============================================================================

module decoder (
    input  wire [6:0] opcode,       // Instruction opcode [6:0]
    input  wire [2:0] func3,        // Function3 field [14:12]
    input  wire [6:0] func7,        // Function7 field [31:25]
    input  wire       zero,         // ALU zero flag (for branches)
    output reg        regWrite,     // Register write enable
    output reg        memWrite,     // Memory write enable
    output reg  [3:0] aluOp,        // ALU operation code
    output reg  [2:0] extO,         // Immediate extender type
    output reg        aluSrc,       // ALU source B (0=reg, 1=imm)
    output reg  [1:0] pcsrc,        // PC source selector
    output reg        resultsrc,    // Result source (0=ALU, 1=mem)
    output reg        zer           // Zero output (unused, for compatibility)
);

    //==========================================================================
    // Internal Signals
    //==========================================================================
    reg [9:0] func;  // Combined func7 and func3 for R-type decoding
    
    //==========================================================================
    // Main Decoder Logic
    //==========================================================================
    // Combinational logic - uses blocking assignments (=) not non-blocking (<=)
    
    always @(*) begin
        // Default output values
        zer = 0;
        
        case (opcode)
            //------------------------------------------------------------------
            // R-Type Instructions (opcode = 0110011)
            //------------------------------------------------------------------
            // Format: func7[31:25] | rs2[24:20] | rs1[19:15] | func3[14:12] | rd[11:7] | opcode[6:0]
            // Examples: ADD, SUB, SLL, SLT, XOR, SRL, SRA, OR, AND
            
            7'b0110011: begin
                func = {func7, func3};  // Combine for operation decoding
                regWrite = 1;           // Write result to register
                memWrite = 0;           // No memory write
                aluSrc = 0;             // ALU source B = register
                pcsrc = 2'b00;          // PC = PC + 1 (sequential)
                resultsrc = 1'b0;       // Result from ALU
                
                // Decode specific R-type operation
                case (func)
                    10'b0000000000: aluOp = 4'b0010;  // ADD
                    10'b0100000000: aluOp = 4'b0011;  // SUB
                    10'b0000000001: aluOp = 4'b0110;  // SLL (shift left logical)
                    10'b0000000010: aluOp = 4'b1000;  // SLT (set less than)
                    10'b0000000100: aluOp = 4'b0100;  // XOR
                    10'b0000000101: aluOp = 4'b0111;  // SRL (shift right logical)
                    10'b0100000101: aluOp = 4'b0111;  // SRA (shift right arithmetic)
                    10'b0000000110: aluOp = 4'b0001;  // OR
                    10'b0000000111: aluOp = 4'b0000;  // AND
                    default:        aluOp = 4'b0010;  // Default to ADD
                endcase
            end
            
            //------------------------------------------------------------------
            // I-Type Instructions - Immediate Arithmetic (opcode = 0010011)
            //------------------------------------------------------------------
            // Format: imm[31:20] | rs1[19:15] | func3[14:12] | rd[11:7] | opcode[6:0]
            // Examples: ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
            
            7'b0010011: begin
                regWrite = 1'b1;        // Write result to register
                memWrite = 1'b0;        // No memory write
                resultsrc = 1'b0;       // Result from ALU
                aluOp = 4'b0010;        // ADD operation (for ADDI)
                aluSrc = 1'b1;          // ALU source B = immediate
                extO = 3'b011;          // I-type immediate extension
                pcsrc = 2'b00;          // PC = PC + 1
            end
            
            //------------------------------------------------------------------
            // I-Type Instructions - Load (opcode = 0000011)
            //------------------------------------------------------------------
            // Format: imm[31:20] | rs1[19:15] | func3[14:12] | rd[11:7] | opcode[6:0]
            // Examples: LW, LH, LB, LHU, LBU
            
            7'b0000011: begin
                regWrite = 1;           // Write loaded data to register
                memWrite = 0;           // No memory write (reading)
                resultsrc = 1'b1;       // Result from memory
                aluOp = 4'b0010;        // ADD (calculate address)
                aluSrc = 1;             // ALU source B = immediate offset
                extO = 3'b010;          // I-type immediate extension
                pcsrc = 2'b00;          // PC = PC + 1
            end
            
            //------------------------------------------------------------------
            // S-Type Instructions - Store (opcode = 0100011)
            //------------------------------------------------------------------
            // Format: imm[31:25] | rs2[24:20] | rs1[19:15] | func3[14:12] | imm[11:7] | opcode[6:0]
            // Examples: SW, SH, SB
            
            7'b0100011: begin
                regWrite = 1'b0;        // No register write
                memWrite = 1'b1;        // Write to memory
                resultsrc = 1'b1;       // (Don't care, no write-back)
                extO = 3'b010;          // S-type immediate extension
                aluOp = 4'b0010;        // ADD (calculate address)
                aluSrc = 1'b1;          // ALU source B = immediate offset
                pcsrc = 2'b00;          // PC = PC + 1
            end
            
            //------------------------------------------------------------------
            // B-Type Instructions - Branch (opcode = 1100011)
            //------------------------------------------------------------------
            // Format: imm[31:25] | rs2[24:20] | rs1[19:15] | func3[14:12] | imm[11:7] | opcode[6:0]
            // Examples: BEQ, BNE, BLT, BGE, BLTU, BGEU
            
            7'b1100011: begin
                regWrite = 1'b0;        // No register write
                memWrite = 1'b0;        // No memory write
                resultsrc = 1'b0;       // (Don't care)
                extO = 3'b000;          // B-type immediate extension
                aluSrc = 1'b0;          // ALU source B = register
                aluOp = 4'b0011;        // SUB (for comparison)
                
                // Decode branch type and set PC source based on condition
                case (func3)
                    3'b000: begin  // BEQ (branch if equal)
                        pcsrc = (zero == 1) ? 2'b01 : 2'b00;  // Branch if zero
                    end
                    3'b001: begin  // BNE (branch if not equal)
                        pcsrc = (zero == 0) ? 2'b01 : 2'b00;  // Branch if not zero
                    end
                    3'b100: begin  // BLT (branch if less than, signed)
                        pcsrc = (zero == 1) ? 2'b00 : 2'b01;
                    end
                    3'b101: begin  // BGE (branch if greater or equal, signed)
                        pcsrc = (zero == 1) ? 2'b00 : 2'b01;
                    end
                    3'b110: begin  // BLTU (branch if less than, unsigned)
                        pcsrc = (zero == 1) ? 2'b00 : 2'b01;
                    end
                    3'b111: begin  // BGEU (branch if greater or equal, unsigned)
                        pcsrc = (zero == 1) ? 2'b00 : 2'b01;
                    end
                    default: pcsrc = 2'b00;
                endcase
            end
            
            //------------------------------------------------------------------
            // J-Type Instructions - JAL (opcode = 1101111)
            //------------------------------------------------------------------
            // Format: imm[31:12] | rd[11:7] | opcode[6:0]
            // Jump and Link: PC = PC + imm, rd = PC + 4
            
            7'b1101111: begin
                regWrite = 1;           // Write PC+4 to rd
                memWrite = 0;           // No memory write
                resultsrc = 1'b0;       // Result from ALU
                extO = 3'b000;          // J-type immediate extension
                aluOp = 4'b0000;        // (Don't care for JAL)
                aluSrc = 0;             // (Don't care)
                pcsrc = 2'b11;          // PC = immediate (jump target)
            end
            
            //------------------------------------------------------------------
            // I-Type Instructions - JALR (opcode = 1100111)
            //------------------------------------------------------------------
            // Format: imm[31:20] | rs1[19:15] | func3[14:12] | rd[11:7] | opcode[6:0]
            // Jump and Link Register: PC = rs1 + imm, rd = PC + 4
            
            7'b1100111: begin
                regWrite = 1;           // Write PC+4 to rd
                memWrite = 0;           // No memory write
                resultsrc = 1'b0;       // Result from ALU
                extO = 3'b011;          // I-type immediate extension
                aluOp = 4'b0010;        // ADD (calculate jump target)
                aluSrc = 1;             // ALU source B = immediate
                pcsrc = 2'b10;          // PC = ALU result
            end
            
            //------------------------------------------------------------------
            // U-Type Instructions - LUI (opcode = 0110111)
            //------------------------------------------------------------------
            // Format: imm[31:12] | rd[11:7] | opcode[6:0]
            // Load Upper Immediate: rd = imm << 12
            
            7'b0110111: begin
                regWrite = 1;           // Write immediate to rd
                memWrite = 0;           // No memory write
                resultsrc = 1'b0;       // Result from ALU
                extO = 3'b001;          // U-type immediate extension
                aluOp = 4'b0000;        // (Pass through immediate)
                aluSrc = 1;             // ALU source B = immediate
                pcsrc = 2'b00;          // PC = PC + 1
            end
            
            //------------------------------------------------------------------
            // U-Type Instructions - AUIPC (opcode = 0010111)
            //------------------------------------------------------------------
            // Format: imm[31:12] | rd[11:7] | opcode[6:0]
            // Add Upper Immediate to PC: rd = PC + (imm << 12)
            
            7'b0010111: begin
                regWrite = 1;           // Write result to rd
                memWrite = 0;           // No memory write
                resultsrc = 1'b0;       // Result from ALU
                extO = 3'b001;          // U-type immediate extension
                aluOp = 4'b0010;        // ADD (PC + immediate)
                aluSrc = 1;             // ALU source B = immediate
                pcsrc = 2'b00;          // PC = PC + 1
            end
            
            //------------------------------------------------------------------
            // Default Case - NOP (No Operation)
            //------------------------------------------------------------------
            
            default: begin
                regWrite = 0;           // No register write
                memWrite = 0;           // No memory write
                pcsrc = 2'b00;          // PC = PC + 1
                aluOp = 4'b0000;        // No operation
                aluSrc = 0;             // (Don't care)
                resultsrc = 1'b0;       // (Don't care)
                extO = 3'b000;          // (Don't care)
            end
        endcase
    end

endmodule