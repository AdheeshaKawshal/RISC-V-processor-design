`include "decoder.v"
`include "reg_file.v"
`include "ins_mem.v"
`include "ALU.v"
`include "data_mem.v"
`include "mux.v"
`include "extender.v"

module riscv_core(
    // Clock and Reset
    input  wire        clk,              // Clock input
    input  wire        rst,              // Reset (active high)
    
    // Instruction Interface
    output wire [31:0] instruction,      // Current instruction being executed
    input  wire [31:0] pc,               // Program counter input (if externally controlled)
    
    // Memory Interface
    input  wire [31:0] read_data,        // Byte-aligned read data from memory
    output wire [31:0] memory_address,   // Memory address for read/write operations
    output wire [2:0]  func3,            // Function3 field (for store instructions)
    output wire        write_data        // Write enable signal for memory
);

    //==========================================================================
    // Internal Wire Declarations
    //==========================================================================
    
    // ALU signals
    wire [31:0] AluOut, Aluin1, Aluin2, extout;
    wire [31:0] Aout, SrcB;
    wire [3:0]  aluctr;                  // ALU control signal
    wire        zero;                    // ALU zero flag
    
    // Register file signals
    wire [31:0] inA, inB;                // Register file outputs
    wire [31:0] muxB;                    // Second register output
    wire [31:0] WD3;                     // Write-back data to register file
    wire        Rwe;                     // Register write enable
    
    // Memory signals
    wire [31:0] RD;                      // Data memory read output
    wire [31:0] data_to_write;
    wire        Dwe;                     // Data memory write enable
    
    // Instruction and immediate signals
    wire [31:0] instr;                   // Current instruction
    wire [31:0] ext;                     // Sign-extended immediate
    wire [2:0]  immsrc;                  // Immediate type selector
    
    // Program counter signals
    wire [31:0] pcnex;                   // Next PC value
    wire [31:0] pcplus;                  // PC + 1 (sequential)
    wire [31:0] pctar;                   // PC + immediate (branch target)
    wire [31:0] pcsh;                    // Selected next PC
    wire [31:0] next_pc;
    wire [1:0]  pcSrc;                   // PC source selector
    
    // Control signals
    wire        aluSrc;                  // ALU source selector (register vs immediate)
    wire        resultsrc;               // Result source selector (ALU vs memory)
    
    // Unused wires (for future expansion or debugging)
    wire [31:0] mout, WD;
    wire [5:0]  pcaddr;
    wire        zer,status;

    //==========================================================================
    // Output Assignments
    //==========================================================================
    assign Aluin1        = inA;
    assign AluOut        = Aout;
    assign extout        = ext;
    assign Aluin2        = SrcB;
    assign instruction   = instr;
    assign func3         = instr[14:12];
    assign write_data    = Dwe;
    assign next_pc       = pcnex;
    assign data_to_write = muxB;
    assign memory_address = Aout;

    //==========================================================================
    // Control Unit - Instruction Decoder
    //==========================================================================
    // Decodes the instruction and generates all control signals
    decoder rv32i (
        .opcode(instr[6:0]),
        .func3(instr[14:12]),
        .func7(instr[31:25]),
        .zero(zero),
        .regWrite(Rwe),
        .memWrite(Dwe),
        .aluOp(aluctr),
        .extO(immsrc),
        .aluSrc(aluSrc),
        .pcsrc(pcSrc),
        .resultsrc(resultsrc),
        .zer(zer)
    );

    //==========================================================================
    // Program Counter Logic
    //==========================================================================
    
    // PC Register - holds current program counter
    PCreg  PC (
        .clk(clk),
        .pcreg(pcsh),
        .out(pcnex),
        .rst_n(rst)
    );
    
    // PC Multiplexer - selects next PC value
    // 00: PC + 1 (sequential)
    // 01: PC + immediate (branch)
    // 10: ALU result (JALR)
    // 11: Immediate (JAL)
    mux32bit4_1 PCnext (
        .in1(pcplus),
        .in2(pctar),
        .in3(Aout),
        .in4(ext),
        .select(pcSrc),
        .out(pcsh)
    );
    
    // PC + 1 calculation (sequential execution)
    PCalu PCplus (
        .pc(pcnex),
        .imm(32'h00000001),
        .targetpc(pcplus)
    );
    
    // PC + immediate calculation (branch target)
    PCalu PCtarget (
        .pc(pcnex),
        .imm(ext),
        .targetpc(pctar)
    );

    //==========================================================================
    // Instruction Fetch Stage
    //==========================================================================
    // Fetches instruction from instruction memory
    ins_mem insmem (
        .clk(clk),
        .rst_n(rst),
        .addr(pcnex),
        .rd(instr)
    );

    //==========================================================================
    // Instruction Decode / Register File Stage
    //==========================================================================
    
    // Register File - 32 general-purpose registers
    reg_file regfile (
        .clk(clk),
        .rst_n(rst),
        .we(Rwe),
        .rs1(instr[19:15]),              // Source register 1
        .rs2(instr[24:20]),              // Source register 2
        .rs3(instr[11:7]),               // Destination register
        .data_in(WD3),
        .data_out1(inA),
        .data_out2(muxB)
    );
    
    // Immediate Extender - sign-extends immediate values
    extender extend (
        .typ(immsrc),
        .num(instr),
        .out(ext)
    );

    //==========================================================================
    // Execute Stage
    //==========================================================================
    
    // ALU Source Multiplexer - selects between register and immediate
    mux32bit2_1 AluIn (
        .in1(muxB),
        .in2(ext),
        .select(aluSrc),
        .out(SrcB)
    );
    
    // Arithmetic Logic Unit
    ALU alu (
        .ALUop(aluctr),
        .ALUinA(inA),
        .ALUinB(SrcB),
        .ALUOut(Aout),
        .Zero(zero)
    );
    
    // Additional multiplexer (currently unused - for future expansion)
    mux32bit2_1 muxRTA (
        .in1(muxB),
        .in2(ext),
        .select(stat),
        .out(inB)
    );

    //==========================================================================
    // Memory Access Stage
    //==========================================================================
    // Data memory for load/store instructions
    data_mem datamem (
        .clk(clk),
        .rst_n(rst),
        .addr(Aout),
        .data_in(muxB),
        .we(Dwe),
        .data_out(RD)
    );

    //==========================================================================
    // Write Back Stage
    //==========================================================================
    // Result Multiplexer - selects between ALU result and memory data
    mux32bit2_1 muxD (
        .in1(Aout),
        .in2(RD),
        .select(resultsrc),
        .out(WD3)
    );

endmodule
