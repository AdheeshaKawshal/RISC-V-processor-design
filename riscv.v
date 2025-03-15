module core(
	input clk,	// clock input
	input rst,	// reset (active high)
    output  [31:0] instruction, // you need to execute this instruction========
	input  [31:0] pc, // the pc of the instruction that needs to execute==========
    input  [31:0] read_data, // byte-aligned read back of the address memory_address
	output [31:0] memory_address, // memory address to read or write==========
	output [31:0] data_to_write, // data to write for store instructions
	output [2:0] func3, // simply the func3 of the store instruction 
	output write_data, // assert high to write to memory
	output [31:0] next_pc, // pc of next instruction to execute
    output [31:0] AluOut,Aluin1,Aluin2,extout
);

	wire  [3:0]  aluctr;
    wire  [2:0]  immsrc;        // 4-bit ALU operation selector
    wire  [31:0] inA,inB,Aout,RD,mout;
    wire [31:0] instr;
    wire  [31:0] WD3,muxB,ext,WD,pcplus,pctar,pcnex;
	wire Dwe,Rwe,aluSrc,zero,resultsrc;
    wire [1:0] pcSrc;
	wire  [5:0]  pcaddr;
    wire  [31:0] pcsh,SrcB;
    assign Aluin1=inA;
    assign AluOut=Aout;
    assign extout=ext;
    assign Aluin2=SrcB;
    assign instruction=instr;
    assign func3=instr[14:12];
    assign write_data=Dwe;
    assign next_pc=pcnex;
    assign data_to_write=muxB;
    assign D=zero;
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
    mux32bit4_1 PCnext(
    .in1(pcplus),
    .in2(pctar),
    .in3(Aout),
    .in4(ext),
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
            3'b000:begin  // immedeate type
                val= ((num[31] << 12) | (num[7] << 11) | (num[30:25] << 5) | (num[11:8] << 1));//{num[31],val[7],val[30:25],val[11:8],1'b0};
                out = (val[11] == 1) ? { {12{1'b1}}, val } : { {12{1'b0}}, val };
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
    assign data_out = (we) ?  32'bz: memory[addr]; //32'bz
endmodule
module PCreg(
    input clk,
    input [31:0] pcreg,
    output reg[31:0] out

);  
    reg [31:0] PC;
    
    initial begin 
        PC=32'hffffffff;
        out<=PC;
    end
    always @(posedge clk)begin
        out <=pcreg;
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
        RAM[0]=32'h00008013;
        RAM[1]=32'h00800013;
        RAM[2]=32'h00100013;
        RAM[3]=32'h00001163;
        RAM[4]=32'h01402003;
        RAM[5]=32'h00002F23;
        RAM[6]=32'h186A0037;
        RAM[7]=32'h7D00006F;
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
        reg_file[1]=32'h00000000;
        reg_file[2]=32'h00000000;
        reg_file[5]=32'h00000000;
        reg_file[6]=32'h00000000;
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
    output reg [1:0] pcsrc,         
    output reg resultsrc,
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
                pcsrc=2'b00;
                resultsrc=1'b0;
                case (func)
                    10'b0000000000:begin
                       aluOp = 4'b0010; //ADD
                    end
                    10'b0100000000:begin
                       aluOp = 4'b0011; //SUB
                    end
                    10'b0000000001:begin
                       aluOp = 4'b0110; //SLL left shift on the value in register rs1 by the shift amount held in the lower 5 bits of register rs2.
                    end
                    10'b0000000010:begin
                       aluOp = 4'b1000; //Slt
                    end
                    10'b0000000011:begin
                       aluOp = 4'b0000; //SLTU ---
                    end
                    10'b0000000100:begin
                       aluOp = 4'b0100; //XOR
                    end
                    10'b0000000101:begin
                       aluOp = 4'b0111; //SRL
                    end
                    10'b0100000101:begin
                       aluOp = 4'b0000; //SRA----
                    end
                    10'b0000000110:begin
                       aluOp = 4'b0001; //OR
                    end
                    10'b0100000111:begin
                       aluOp = 4'b0000; //AND
                    end
                endcase  
            end
            7'b0010011: begin  // ADDI/SLTI/SLTIU/XORI/ORI/ANDI
                regWrite = 1'b1;
                memWrite = 1'b0;
                resultsrc=1'b0;
                aluSrc = 1'b1;
                extO=3'b011;
                pcsrc=2'b00;
                case (func3)
                    3'b000:begin
                       aluOp = 4'b0010; //ADDI
                    end
                    10'b010:begin
                       aluOp = 4'b1000; //SLTI
                    end
                    10'b11:begin
                       aluOp = 4'b1000; //SLTIU---
                    end
                    10'b100:begin
                       aluOp = 4'b0100; //XORI
                    end
                    10'b110:begin
                       aluOp = 4'b0001; //ORI
                    end
                    10'b111:begin
                       aluOp = 4'b0000; //ANDI
                    end
                    10'b001:begin
                       aluOp = 4'b0110; //SLLI--
                    end
                    10'b101:begin
                       aluOp = 4'b0111; //SRLI--
                    end
                    10'b000:begin
                       aluOp = 4'b0001; //SRAI--
                    end
                endcase 


            end
            7'b0000011: begin  // Load (LW)
                regWrite = 1;
                memWrite = 0;
                aluOp = 4'b0000;
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
                pcsrc=2'b00;
            end 
            7'b1100011: begin  // Branch (BEQ)
                regWrite = 1'b0;
                resultsrc=1'b0;
                extO=3'b000;
                memWrite = 1'b0;
                aluSrc = 1'b0;
                aluOp = 4'b0011;
                case(func3)
                    3'b000:begin //BEQ
                        aluOp = 4'b0011;
                        pcsrc=(zero==0)? 2'b00:2'b11;
                    end
                    3'b001:begin //BNE
                        aluOp = 4'b0011;
                        pcsrc=(zero==0)? 2'b11:2'b00;
                    end
                    3'b100:begin //BLT
                        aluOp = 4'b0011;
                        pcsrc=(zero)? 2'b00:2'b01;
                    end
                    3'b101:begin //BGE
                        aluOp = 4'b0011;
                        pcsrc=(zero)? 2'b00:2'b01;
                    end
                    3'b110:begin //BLTU
                        aluOp = 4'b0011;
                        pcsrc=(zero)? 2'b00:2'b01;
                    end
                    3'b111:begin //BGEU
                        aluOp = 4'b0011;
                        pcsrc=(zero)? 2'b00:2'b01;
                    end
                endcase
            end 
            7'b1101111: begin  // JAL
                regWrite = 1;  // Write PC+4 to rd
                memWrite = 0;
               
                aluOp = 4'b0000;
                aluSrc = 0;
            end
            7'b1100111: begin  // JALR
                regWrite = 1;  // Write PC+4 to rd
                memWrite = 0;
                resultsrc=1'b0;
                extO=3'b011;
                aluOp = 4'b0010;
                aluSrc = 1;
                pcsrc=2'b10;
            end
            7'b0110111: begin  // LUI
                regWrite = 1;  // Write PC+4 to rd
                memWrite = 0;
                extO=3'b001;
                aluOp = 2'b00;
                aluSrc = 1;
            end
            7'b0010111: begin  // AUPIC
                regWrite = 1;  // Write PC+4 to rd
                memWrite = 0;
                extO=3'b001;
                aluOp = 2'b00;
                aluSrc = 1;
            end
            default: begin  // Default case (NOP)
                regWrite = 0;
                memWrite = 0;
                pcsrc=2'b00;
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
module mux32bit4_1(
    input wire [31:0] in1,
    input wire [31:0] in2,
    input wire [31:0] in3,
    input wire [31:0] in4,
    input wire [1:0] select,
    output reg [31:0] out
);
    always @(*) begin
        case(select)
        2'b00: begin
            out =in1;
        end
        2'b01: begin
            out =in2;
        end
        2'b10: begin
            out =in3;
        end
        2'b11: begin
            out =in4;
        end
        default:begin
            out=32'h00000000;
        end
        endcase

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
