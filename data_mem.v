
module data_mem (
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