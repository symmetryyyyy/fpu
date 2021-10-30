`timescale  1ns / 1ps
module mul_s(
    //din 
    input [63:0] a,
    input [63:0] b,
    //dout
    output [117:0] out
);

    mul_s_core u0(.a(a[31:0]),.b(b[31:0]),.out(out[58:0]));
    mul_s_core u1(.a(a[63:32]),.b(b[63:32]),.out(out[117:59]));

endmodule

module mul_s_core(
    //din 
    input [31:0] a,
    input [31:0] b,
    //dout
    output [58:0] out
);

    wire [57:0] mul_out;

    //deno/normalized mul
    assign out[58] = a[31] ^ b[31];     //sign bit gen

    wire a_exp_equal_zero = a[30:23] == 8'h0;
    wire b_exp_equal_zero = b[30:23] == 8'h0;

    wire [7:0] a_e = a_exp_equal_zero? 8'h1 : a[30:23]; //denorm condition
    wire [7:0] b_e = b_exp_equal_zero? 8'h1 : b[30:23];

    wire [9:0] a_add_b = {2'h0,a_e} + {2'h0,b_e};
    assign mul_out[57:48] = a_add_b - 10'd126; //exp gen. attention: 126 instead of 127 to generate fraction form x.xxxxxx
    assign mul_out[47:0] = {a_exp_equal_zero? 1'b0 : 1'b1,a[22:0]} *
                           {b_exp_equal_zero? 1'b0 : 1'b1,b[22:0]};  

    //zero mul

    wire mul_zero = (a[22:0] == 23'h0 & a_exp_equal_zero) | (b[22:0] == 23'h0 & b_exp_equal_zero);
    
    //output sel

    wire mul_infinity = a[30:23] == 8'hff | b[30:23] == 8'hff; 
    localparam NAN_FRAC = 23'h7fffff;
    wire nan_involved = mul_infinity & ((a[22:0] == NAN_FRAC) | (b[22:0] == NAN_FRAC));

    assign out[57:0] = nan_involved? 58'h1ffffffffffffff : (mul_infinity? {10'h1ff,48'h0} : (mul_zero? 58'h0 : mul_out));

endmodule
