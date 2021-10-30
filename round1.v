`timescale  1ns / 1ps
module round1(
    input p_op,
    input [117:0] din,
    output [63:0] dout,
    output overflow,
    output underflow,
    output inexact
);
    wire overflow_out0,overflow_out1;
    wire underflow_out0,underflow_out1;
    wire inexact_out0,inexact_out1;
    round1_sub u0(.din(din[58:0]),.dout(dout[31:0]),.overflow_out(overflow_out0),.underflow_out(underflow_out0),.inexact_out(inexact_out0));
    round1_sub u1(.din(din[117:59]),.dout(dout[63:32]),.overflow_out(overflow_out1),.underflow_out(underflow_out1),.inexact_out(inexact_out1));
    assign overflow = p_op? (overflow_out0 | overflow_out1) : overflow_out0;
    assign underflow = p_op? (underflow_out0 | underflow_out1) : underflow_out0;
    assign inexact = p_op? (inexact_out0 | inexact_out1) : inexact_out0;

endmodule

module round1_sub(
    input [58:0] din,
    output [31:0] dout,
    output overflow_out,
    output underflow_out,
    output inexact_out
);
    //find the MSB of frac, actual the num exp need to be sub
    wire [47:0] frac = din[47:0];
    reg [5:0] MSB_frac;
    always@(*) begin
        if(frac[47]) MSB_frac = 0;  //highest bit is 1, no need to shift left
        else if(frac[46]) MSB_frac = 1;
        else if(frac[45]) MSB_frac = 2;
        else if(frac[44]) MSB_frac = 3;
        else if(frac[43]) MSB_frac = 4;
        else if(frac[42]) MSB_frac = 5;
        else if(frac[41]) MSB_frac = 6;
        else if(frac[40]) MSB_frac = 7;
        else if(frac[39]) MSB_frac = 8;
        else if(frac[38]) MSB_frac = 9;
        else if(frac[37]) MSB_frac = 10;
        else if(frac[36]) MSB_frac = 11;
        else if(frac[35]) MSB_frac = 12;
        else if(frac[34]) MSB_frac = 13;
        else if(frac[33]) MSB_frac = 14;
        else if(frac[32]) MSB_frac = 15;
        else if(frac[31]) MSB_frac = 16;
        else if(frac[30]) MSB_frac = 17;
        else if(frac[29]) MSB_frac = 18;
        else if(frac[28]) MSB_frac = 19;
        else if(frac[27]) MSB_frac = 20;
        else if(frac[26]) MSB_frac = 21;
        else if(frac[25]) MSB_frac = 22;
        else if(frac[24]) MSB_frac = 23;
        else if(frac[23]) MSB_frac = 24;
        else if(frac[22]) MSB_frac = 25;
        else if(frac[21]) MSB_frac = 26;
        else if(frac[20]) MSB_frac = 27;
        else if(frac[19]) MSB_frac = 28;
        else if(frac[18]) MSB_frac = 29;
        else if(frac[17]) MSB_frac = 30;
        else if(frac[16]) MSB_frac = 31;
        else if(frac[15]) MSB_frac = 32;
        else if(frac[14]) MSB_frac = 33;
        else if(frac[13]) MSB_frac = 34;
        else if(frac[12]) MSB_frac = 35;
        else if(frac[11]) MSB_frac = 36;
        else if(frac[10]) MSB_frac = 37;
        else if(frac[9]) MSB_frac = 38;
        else if(frac[8]) MSB_frac = 39;
        else if(frac[7]) MSB_frac = 40;
        else if(frac[6]) MSB_frac = 41;
        else if(frac[5]) MSB_frac = 42;
        else if(frac[4]) MSB_frac = 43;
        else if(frac[3]) MSB_frac = 44;
        else if(frac[2]) MSB_frac = 45;
        else if(frac[1]) MSB_frac = 46;
        else if(frac[0]) MSB_frac = 47;
        else MSB_frac = 48;
    end

    localparam underflow_limit = -10'd22;
    localparam underflow_max_exp = -10'd23;

    wire [9:0] exp_actual = din[57:48] - {4'h0,MSB_frac};
    wire underflow = exp_actual[9] & (exp_actual[8:0] < underflow_limit[8:0]);  //when 0.xxxxxxxxxxxx(23 bit of frac)*2^-126 cannot express
    wire denorm = (~underflow) & (exp_actual[9] | exp_actual == 10'h000);
    wire exp_sign = exp_actual[9];
    wire [7:0]exp_low = exp_actual[7:0];
    wire exp_high = exp_actual[8];
    wire overflow = (~exp_sign) & (exp_high | exp_low == 8'hff); //overflow when positive exp is larger than 255 or equal 255

    //rounding is not correct
    wire [47:0] frac_out = underflow? 48'h000000_000000 :
                           overflow? 48'hffffff_ffffff : 
                           denorm?  (frac[47:0] << MSB_frac) >> (10'd1 - exp_actual) :
                           frac[47:0] << MSB_frac;

    //round to nearest. TODO..........
    wire guard_bit = frac_out[24];
    wire round_bit = frac_out[23];
    wire sticky_bit = frac_out[22:0] != 23'h00_0000;
    wire Incr = (round_bit&sticky_bit) | (round_bit&guard_bit&(~sticky_bit));
    wire [22:0]frac_add_one = frac_out[46:24] + 23'h1;
    wire [22:0]frac_normal = frac_out[46:24];
    //process condition when frac_normal[22:0] all bit is 1 and Incr valid
    wire frac_normal_all_one = frac_normal == 23'h7f_ffff;
    wire exp_add = frac_normal_all_one & Incr;

    //sign bit gen
    assign dout[31] = din[58];
    //exp gen
    wire underflow_denorm_out = (exp_actual[9] | ((exp_actual == 10'h000) & (~exp_add)));
    assign dout[30:23] = (underflow_denorm_out)? 8'h00:
                        (overflow)? 8'hff : 
                        (exp_add)? (exp_low + 8'h1) : exp_low;  //underflow and overflow ruled out
    //frac gen
    wire din_nan = overflow & (frac[46:24] == 23'h7fffff);
    assign dout[22:0] = din_nan? 23'h7fffff :(/*exp_add? 23'h0 :*/( Incr? frac_add_one : frac_normal));

    //exception
    assign overflow_out = (~exp_sign) & (exp_high | (exp_low == 8'hff & Incr));
    assign underflow_out = exp_sign & ((exp_actual[8:0] < underflow_max_exp[8:0]) | ((exp_actual[8:0] == underflow_max_exp) & exp_add));
    assign inexact_out = (round_bit) | (sticky_bit);

endmodule
