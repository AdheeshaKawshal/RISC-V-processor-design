module test (
    input [3:0]a,
    input [3:0]b,
    output [3:0]c
);
    adder add1(
        .a(a),
       .b(b),
       .c(c)
    );
endmodule

module adder(
    input wire[3:0] a,
    input wire[3:0] b,
    output reg [3:0] c
);
    always @(*) begin
        c=a+b;
    end
endmodule
