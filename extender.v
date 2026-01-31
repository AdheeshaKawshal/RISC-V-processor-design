//==============================================================================
// Immediate Extender - RISC-V Processor
//==============================================================================
// This module extracts and sign-extends immediate values from RISC-V instructions.
// Different instruction types have different immediate field encodings.
//
// SYNTHESIS: This module is FULLY SYNTHESIZABLE for FPGA/ASIC implementation.
//
// RISC-V Immediate Formats:
//   - I-Type (typ=011): 12-bit immediate [31:20]
//     Used by: ADDI, SLTI, XORI, ORI, ANDI, LW, JALR
//     Format: imm[11:0] = inst[31:20]
//
//   - S-Type (typ=010): 12-bit immediate [31:25, 11:7]
//     Used by: SW, SH, SB
//     Format: imm[11:5] = inst[31:25], imm[4:0] = inst[11:7]
//
//   - B-Type (typ=000): 13-bit immediate [31, 7, 30:25, 11:8]
//     Used by: BEQ, BNE, BLT, BGE, BLTU, BGEU
//     Format: imm[12] = inst[31], imm[10:5] = inst[30:25],
//             imm[4:1] = inst[11:8], imm[11] = inst[7], imm[0] = 0
//
//   - U-Type (typ=001): 20-bit immediate [31:12]
//     Used by: LUI, AUIPC
//     Format: imm[31:12] = inst[31:12], imm[11:0] = 0
//
//   - J-Type (typ=100): 21-bit immediate [31, 19:12, 20, 30:21]
//     Used by: JAL
//     Format: imm[20] = inst[31], imm[10:1] = inst[30:21],
//             imm[11] = inst[20], imm[19:12] = inst[19:12], imm[0] = 0
//
// All immediates are sign-extended to 32 bits.
//==============================================================================

module extender (
    input  wire [2:0]  typ,         // Immediate type selector
    input  wire [31:0] num,         // Input instruction
    output reg  [31:0] out          // Sign-extended immediate output
);

    //==========================================================================
    // Internal Signal
    //==========================================================================
    reg [11:0] val;  // Temporary 12-bit immediate value
    
    //==========================================================================
    // Immediate Extraction and Sign Extension Logic
    //==========================================================================
    
    always @(*) begin
        case (typ)
            //------------------------------------------------------------------
            // S-Type Immediate (Store instructions)
            //------------------------------------------------------------------
            // Extract: imm[11:5] from inst[31:25], imm[4:0] from inst[11:7]
            3'b010: begin
                val = {num[31:25], num[11:7]};
                // Sign-extend from 12 bits to 32 bits
                out = (val[11] == 1) ? {{20{1'b1}}, val} : {{20{1'b0}}, val};
            end
            
            //------------------------------------------------------------------
            // I-Type Immediate (Immediate arithmetic and Load instructions)
            //------------------------------------------------------------------
            // Extract: imm[11:0] from inst[31:20]
            3'b011: begin
                val = num[31:20];
                // Sign-extend from 12 bits to 32 bits
                out = (val[11] == 1) ? {{20{1'b1}}, val} : {{20{1'b0}}, val};
            end
            
            //------------------------------------------------------------------
            // U-Type Immediate (LUI, AUIPC)
            //------------------------------------------------------------------
            // Extract: imm[31:12] from inst[31:12], lower 12 bits are zero
            3'b001: begin
                val = num[31:20];
                // Sign-extend from 12 bits to 20 bits (upper immediate)
                out = (val[11] == 1) ? {{12{1'b1}}, num[31:12]} : {{12{1'b0}}, num[31:12]};
            end
            
            //------------------------------------------------------------------
            // B-Type Immediate (Branch instructions)
            //------------------------------------------------------------------
            // Extract: imm[12]=inst[31], imm[10:5]=inst[30:25],
            //          imm[4:1]=inst[11:8], imm[11]=inst[7], imm[0]=0
            3'b000: begin
                val = {num[31], num[7], num[30:25], num[11:8]};
                // Sign-extend from 12 bits to 32 bits
                out = (val[11] == 1) ? {{20{1'b1}}, val} : {{20{1'b0}}, val};
            end
            
            //------------------------------------------------------------------
            // Default Case
            //------------------------------------------------------------------
            default: begin
                out = 32'h00000000;
            end
        endcase
    end

endmodule
