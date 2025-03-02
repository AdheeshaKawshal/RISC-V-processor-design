//32032f9u0nho
module core(
	input clk,	// clock input first comment
	input rst,	// reset (active high)
    input  [31:0] instruction, // you need to execute this instruction========
	input  [31:0] pc, // the pc of the instruction that needs to execute==========
    input  [31:0] read_data, // byte-aligned read back of the address memory_address
	output [31:0] memory_address, // memory address to read or write==========
	output [31:0] data_to_write, // data to write for store instructions
	output [2:0] func3, // simply the func3 of the store instruction 
	output write_data, // assert high to write to memory
	output [31:0] next_pc, // pc of next instruction to execute
    output [31:0] A,B,C,ins,D
);

	wire  [3:0]  aluctr;
    wire  [2:0]  immsrc;        // 4-bit ALU operation selector
    wire  [31:0] inA,inB,Aout,pcreg,RD,mout;
    wire [31:0] instr;
    wire  [31:0] WD3,muxB,ext,WD,pcplus,pctar,pcnex;
	wire Dwe,Rwe,aluSrc,zero,resultsrc,pcSrc;
	wire  [5:0]  pcaddr;
    wire  [31:0] pcsh,SrcB;
    assign A=Aout;
    assign B=muxB;
    assign C=WD3;
    assign ins=instr;
    assign func3=instr[14:12];
    assign write_data=Dwe;
    assign next_pc=pcplus;
    assign data_to_write=muxB;
    assign memory_address=Aout;
    assign D=RD;
    //assign pcnex=pc;    // have to overwrite default path to run given input instruction
    //assign instr=instruction; // have to overwrite default path to run given input instruction
    rv32i_controller rv32i(
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
    PCreg PC(
        .clk(clk),
        .pcreg(pcsh),
        .out(pcnex)
    );
    mux32bit2_1 PCnext(
    .in1(pcplus),
    .in2(pctar),
    .select(pcSrc),
    .out(pcsh)
);
    PCalu PCplus(
    .pc(pcnex),
    .imm(32'h00000001),
    .targetpc(pcplus)
);
    PCalu PCtarget(
    .pc(pcnex),
    .imm(ext),
    .targetpc(pctar)
);
	 instruction_memory insmem(
      .addr(pcnex),        // Address input (32 bits for 64 locations)
      .rd(instr)  // 32-bit output data
);  //assign Rwe=1'b1;
    
    regfile reg_file(
    .clk(clk),
    .rst_n(rst),
    .we(Rwe),
    .rs1(instr[19:15]), 
    .rs2(instr[24:20]),
    .rs3(instr[11:7]),
    .data_in(WD3),
    .data_out1(inA),
    .data_out2(muxB)
);  
    extender extend(
    .typ(immsrc), 
    .num(instr),
    .out(ext)
);
   	mux32bit2_1 AluIn(
    .in1(muxB),
    .in2(ext),
    .select(aluSrc),
    .out(SrcB)
);
   ALU alu(
	  .ALUop(aluctr),          // 4-bit ALU operation selector
	  .ALUinA(inA),
	  .ALUinB(SrcB), // 32-bit inputs
	  .ALUOut(Aout),     // 32-bit result
	  .Zero (zero)
);
	 mux32bit2_1 muxRTA(
    .in1(muxB),
    .in2(ext),
    .select(stat),
    .out(inB)
);
	data_memory datamem(
    .clk(clk),
	.rst_n(rst),
    .addr(Aout),
    .data_in(muxB),
    .we(Dwe),
    .data_out(RD)
);
	mux32bit2_1 muxD(
    .in1(Aout),
    .in2(RD),
    .select(resultsrc),
    .out(WD3)
);
	
endmodule


module ALU (
  input  [3:0]  ALUop,          // 4-bit ALU operation selector
  input  [31:0] ALUinA, ALUinB, // 32-bit inputs
  output reg [31:0] ALUOut,     // 32-bit result
  output reg Zero              // Zero flag (1 if ALUOut is 0)
);
  always @(*) begin
    case (ALUop)
      4'b0000: ALUOut = ALUinA & ALUinB; // AND
      4'b0001: ALUOut = ALUinA | ALUinB; // OR
      4'b0010: ALUOut = ALUinA + ALUinB; // ADD
      4'b0011: ALUOut = ALUinA - ALUinB; // SUB
      4'b0100: ALUOut = ALUinA ^ ALUinB; // XOR
      4'b0101: ALUOut = ~(ALUinA | ALUinB); // NOR
      4'b0110: ALUOut = ALUinA << ALUinB[4:0]; // Shift Left
      4'b0111: ALUOut = ALUinA >> ALUinB[4:0]; // Shift Right
      4'b1000: ALUOut = (ALUinA < ALUinB) ? 32'b1 : 32'b0; // Set Less Than (SLT)
      default: ALUOut = 32'b0; // Default case
    endcase
    Zero = (ALUOut == 0) ? 1'b1 : 1'b0;
  end
endmodule

module PCalu(
    input wire [31:0] pc,
    input wire [31:0] imm,
    output reg [31:0] targetpc
);
    always @(*) begin
        targetpc=pc+imm;
    end
endmodule

module extender(
    input wire [2:0] typ, 
    input wire [31:0] num,
    output reg [31:0] out
);  reg [11:0] val;
    always @(*) begin
        case(typ)
            3'b010:begin  // S type
                val={num[31:25],num[11:7]};
                out = (val[11] == 1) ? { {20{1'b1}}, val } : { {20{1'b0}}, val };
            end
            3'b011:begin  // I type
                val={num[31:20]};
                out = (val[11] == 1) ? { {20{1'b1}}, val } : { {20{1'b0}}, val };
            end
            3'b001:begin  // U type
                val={num[31:12]};
                out = (val[19] == 1) ? { {12{1'b1}}, val } : { {12{1'b0}}, val };
            end
            default:begin
                out=32'h00000000;
            end 
        endcase
        
    end
endmodule

module data_memory (
    input wire clk, rst_n,
    input wire [31:0] addr,
    input wire [31:0] data_in,
    input wire we,
    output wire [31:0] data_out
);
    reg [31:0] memory [0:63];
	 integer i;
    
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
//            reg [5:0] i;
            for (i = 0; i < 64; i = i + 1) begin
                memory[i] <= 32'b0;
            end
        end else if (we) begin
            memory[addr[5:0]] <= data_in;
            
        end
    end
    assign data_out = (we) ?  memory[addr[5:0]]: memory[addr]; //32'bz
endmodule
module PCreg(
    input clk,
    input [31:0] pcreg,
    output reg[31:0] out

);  
    reg [31:0] PC;
    
    initial begin 
        PC=32'h00000005;
        out=PC;
    end
    
    always @(posedge clk)begin 
        PC =pcreg;
        out <=PC;
        
    end

endmodule

module instruction_memory (
    input [31:0] addr,        // Address input (6 bits for 64 locations)
    output reg [31:0] rd  // 32-bit output data
);

    // Memory array to store instructions
    reg [31:0] RAM [0:63]; // 64 locations of 32 bits each

    // Initialize the memory with instructions
    initial begin
        RAM[0] = 32'h006283B3; // NOP (addi x0, x0, 0)
        RAM[1] = 32'h007020A3; // ADDI x1, x0, 1  (x1 = 1)
        RAM[2] = 32'h007020A3; // ADDI x2, x0, 2  (x2 = 2)
        RAM[3] = 32'h007020A3; // ADD  x3, x1, x2 (x3 = x1 + x2 = 3)
        RAM[4] = 32'h00410234; // ADD  x4, x2, x4 (x4 = x2 + x4)
        RAM[5] = 32'h00000065; // JUMP (Unconditional jump)
        RAM[6] = 32'h00410236; // ADD  x4, x2, x4 (x4 = x2 + x4)
        RAM[7] = 32'h00000067;
        RAM[8] = 32'h00410238; // ADD  x4, x2, x4 (x4 = x2 + x4)
        RAM[9] = 32'h00000069;// More instructions...
    end
	 always @(*) begin
		rd = RAM[addr]; // Read instruction at address `a`
	 end

endmodule
module regfile (
    input wire clk,
    input wire rst_n,
    input wire we,
    input wire [4:0] rs1, rs2, rs3,
    input wire [31:0] data_in,
    output wire [31:0] data_out1,
    output wire [31:0] data_out2
);
    reg [31:0] reg_file [31:0]; // 32 registers
    initial begin
        reg_file[0]=32'h00000000;
        reg_file[1]=32'h00000005;
        reg_file[5]=32'h00000009;
        reg_file[6]=32'h00000005;
    end
    assign data_out1 = reg_file[rs1];
    assign data_out2 = reg_file[rs2];
    integer i=0;
    always @(posedge clk or negedge rst_n) begin  
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1) begin
                reg_file[i] <= 32'b0;
            end
        end else if (we && rs3 != 0) begin
            reg_file[rs3] <= data_in;
        end
    end
endmodule



module rv32i_controller (
    input wire [6:0] opcode, 
    input wire [2:0] func3,
    input wire [6:0] func7,
    input wire zero,  // alu flag
    output reg regWrite,      
    output reg memWrite,             
    output reg [3:0] aluOp, 
    output reg [2:0] extO,   
    output reg aluSrc,          
    output reg pcsrc,resultsrc,
    output reg zer
);
    reg [9:0] func;
    always @(*) begin
        case (opcode) 
            7'b0110011: begin  // R-Type
                func={func7, func3};
                regWrite = 1;
                memWrite = 0;
                aluSrc = 0;
                pcsrc=1'b0;
                resultsrc=1'b0;
                case (func)
                    10'b0000000000:begin
                       aluOp = 4'b0010; //ADD
                    end
                    10'b0100000010:begin
                       aluOp = 4'b0000; //SUB
                    end
                    10'b0100000001:begin
                       aluOp = 4'b0000; //SLL left shift on the value in register rs1 by the shift amount held in the lower 5 bits of register rs2.
                    end
                    10'b0110000010:begin
                       aluOp = 4'b0000; //Slt
                    end
                    10'b0011100000:begin
                       aluOp = 4'b0000; //ADD
                    end
                endcase  
            end
            7'b0000011: begin  // Load (LW)
                regWrite = 1;
                memWrite = 0;
                aluOp = 2'b00;
                aluSrc = 1;
                extO=3'b010;
            end
            7'b0100011: begin  // Store (SW)
                regWrite = 1'b0;
                memWrite = 1'b1;

                resultsrc=1'b1;
                extO=3'b010;
                aluOp = 4'b0010;
                aluSrc = 1'b1;
                pcsrc=1'b0;
            end
            7'b1100011: begin  // Branch (BEQ)
                regWrite = 0;
                memWrite = 0;
                aluOp = 2'b01;
                aluSrc = 0;
            end
            7'b1101111: begin  // JAL
                regWrite = 1;  // Write PC+4 to rd
                memWrite = 0;
               
                aluOp = 2'b00;
                aluSrc = 0;
            end
            7'b0110111: begin  // U type
                regWrite = 1;  // Write PC+4 to rd
                memWrite = 0;
                extO=3'b001;
                aluOp = 2'b00;
                aluSrc = 1;
            end
            default: begin  // Default case (NOP)
                regWrite = 0;
                memWrite = 0;
            
                aluOp = 2'b00;
                aluSrc = 0;
            end
        endcase
    end
endmodule


module mux32bit2_1(
    input wire [31:0] in1,
    input wire [31:0] in2,
    input wire select,
    output reg [31:0] out
);
    always @(*) begin
        out = (select) ? in2 : in1;
    end
endmodule


// module clock_generator (
//     output reg clk
// );
//     initial begin
//         clk = 0;  
//     end
//     always begin
//         #5 clk = ~clk; 
//         #30 $finish;
//     end
// endmodule
