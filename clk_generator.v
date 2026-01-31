module clock_generator (
    output reg clk
);
    initial begin
        clk = 0;  
    end
    always begin
        #5 clk = ~clk; 
        #30 $finish;
    end
endmodule
