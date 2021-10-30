`timescale  1ns / 1ps
module round2(
    input p_op,
    input [71:0] din,
    output [63:0] dout,
    output overflow,
    output underflow,
    output inexact
);

    wire overflow_out0,overflow_out1;
    wire underflow_out0,underflow_out1;
    wire inexact_out0,inexact_out1;
    round2_core u0(.din(din[35:0]),.dout(dout[31:0]),.overflow_out(overflow_out0),.underflow_out(underflow_out0),.inexact_out(inexact_out0));
    round2_core u1(.din(din[71:36]),.dout(dout[63:32]),.overflow_out(overflow_out1),.underflow_out(underflow_out1),.inexact_out(inexact_out1));
    assign overflow = p_op? (overflow_out0 | overflow_out1) : overflow_out0;
    assign underflow = p_op? (underflow_out0 | underflow_out1) : underflow_out0;
    assign inexact = p_op? (inexact_out0 | inexact_out1) : inexact_out0;

endmodule

/*input frac has format xx.xxxxx, process has to convert it into x.xxxx first*/
module round2_core(
    input [35:0] din,
    output [31:0] dout,
    output overflow_out,
    output underflow_out,
    output inexact_out
);

    assign dout[31] = din[35];
    wire [7:0] exp_in = din[34:27];
    wire [26:0] frac_in = din[26:0];
    
    wire [4:0] MSB;
    wire exp_less_MSB = exp_in <= MSB;
    wire [7:0] exp_sub_MSB = exp_less_MSB? (MSB - exp_in + 8'h1) : 8'h0;   //canbe optimized
    wire shift_right = frac_in[26];
    wire [25:0] frac_in_val = shift_right? (frac_in >> 1) : ((frac_in << MSB)>>exp_sub_MSB);
    //wire [25:0] frac_shift_right = frac_in_val >> exp_sub_MSB;              //denorm conditions
    wire frac_val_all_1 = frac_in_val[24:2] == 23'h7fffff;
    round2_MSB_get u_GET(.in(frac_in[25:0]),.out(MSB));
    wire exp_ff = exp_in == 8'hff;
    wire exp_fe = exp_in == 8'hfe;
    wire overflow = exp_ff | (exp_fe & shift_right);
    wire exp_0 = exp_in == 8'h00;
    wire underflow = (~shift_right) & exp_less_MSB;
    assign dout[30:23] = overflow? 8'hff : ( underflow? 8'h00 : (shift_right? (exp_in + 8'h1) : (exp_in - MSB)));
    wire guard_bit = frac_in_val[2];
    wire round_bit = frac_in_val[1];
    wire sticky_bit = frac_in_val[0];
    wire Incr = (round_bit&sticky_bit) | (round_bit&guard_bit&(~sticky_bit));
    assign dout[22:0] = (frac_val_all_1 & Incr)? 23'h000000 : ((Incr? (frac_in_val[24:2] + 23'h1) : frac_in_val[24:2]));
    assign overflow_out = overflow;
    assign underflow_out = 1'b0;
    assign inexact_out = (round_bit) | (sticky_bit);

endmodule

`define WIDTH 26
`define WIDTH_LOG_2 5

module round2_MSB_get(
    input [`WIDTH-1:0] in,
    output [`WIDTH_LOG_2-1:0] out
);

    reg [`WIDTH_LOG_2-1:0] out_r;
    always@(*) begin
        if(in[`WIDTH-1]) out_r = 0;
        else if(in[`WIDTH-2]) out_r = 1;
        else if(in[`WIDTH-3]) out_r = 2;
        else if(in[`WIDTH-4]) out_r = 3;
        else if(in[`WIDTH-5]) out_r = 4;
        else if(in[`WIDTH-6]) out_r = 5;
        else if(in[`WIDTH-7]) out_r = 6;
        else if(in[`WIDTH-8]) out_r = 7;
        else if(in[`WIDTH-9]) out_r = 8;
        else if(in[`WIDTH-10]) out_r = 9;
        else if(in[`WIDTH-11]) out_r = 10;
        else if(in[`WIDTH-12]) out_r = 11; 
        else if(in[`WIDTH-13]) out_r = 12;
        else if(in[`WIDTH-14]) out_r = 13;
        else if(in[`WIDTH-15]) out_r = 14; 
        else if(in[`WIDTH-16]) out_r = 15;
        else if(in[`WIDTH-17]) out_r = 16;
        else if(in[`WIDTH-18]) out_r = 17; 
        else if(in[`WIDTH-19]) out_r = 18;
        else if(in[`WIDTH-20]) out_r = 19;
        else if(in[`WIDTH-21]) out_r = 20; 
        else if(in[`WIDTH-22]) out_r = 21; 
        else if(in[`WIDTH-23]) out_r = 22;
        else if(in[`WIDTH-24]) out_r = 23;
        else if(in[`WIDTH-25]) out_r = 24;/* 
        else if(in[`WIDTH-26]) out_r = 25;
        else if(in[`WIDTH-27]) out_r = `WIDTH-27;
        else if(in[`WIDTH-28]) out_r = `WIDTH-28; 
        else if(in[`WIDTH-29]) out_r = `WIDTH-29;
        else if(in[`WIDTH-30]) out_r = `WIDTH-30;
        else if(in[`WIDTH-31]) out_r = `WIDTH-31;*/
        else out_r = `WIDTH-1; 
    end

    assign out = out_r;

endmodule
