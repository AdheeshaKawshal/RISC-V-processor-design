`include "riscv.v"
`timescale 1ns / 1ns

module tb_rv32i_processor;

    // Testbench signals
    reg clk, rst_n,cl;
    reg [31:0] pc;
    wire  [31:0] Aout, pcreg, WD, mout, dt,A,B,C,ins;
    wire [31:0] instr,read_data,memory_address,data_to_write,next_pc;
    wire [2:0] func3;

    // Instantiate the processor
    core uut (
        .clk(clk),
        .rst(rst_n),
        .instruction(instr), // you need to execute this instruction========
	    .pc(pc), // the pc of the instruction that needs to execute==========
        .read_data(read_data), // byte-aligned read back of the address memory_address
	    .memory_address(memory_address), // memory address to read or write==========
	    .data_to_write(data_to_write), // data to write for store instructions
	    .func3(func3), // simply the func3 of the store instruction 
	    .write_data(write_data), // assert high to write to memory
	    .next_pc(next_pc),
        .A(A),
        .B(B),
        .C(C),
        .D(pcreg),
        .ins(ins)
    );
   // Clock generation with a conditional stop after a certain time
    always begin
        #2 clk = ~clk;  // Toggle the clock every 5 time units (i.e., 10-time unit period)
    end

    always @(posedge clk) begin
    $display("Time=%0t | instr=%h | ReadData=%h | A=%d | B=%d | ALUOut=%h | A=%h B=%h | C=%h",
              $time, ins, pcreg, WD, Aout, dt, A, B,C);
    end

    initial begin
        clk=0;
        rst_n = 1;
        $dumpfile("RISCV_tb.vcd");
        $dumpvars(0,tb_rv32i_processor);
        // Initialize signals


        // Apply reset and wait for a few clock cycles
        // pc = 32'h00000000;
        // #10;
        // pc = 32'h00000001;
        // #10;
        // Wait for a few clock cycles to observe execution
        #100;

        // End simulation
        $finish;
    end

endmodule

