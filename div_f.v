`include "div_f_para.v"

//output frac:26bit
//output exp:10 bit
//output sign:1 bit

module div_f(
    //clk
    input clk,
    input rst,
    //sel
    input sel,
    //din
    input [31:0] dividend,
    input [31:0] divisor,
    //busy
    output busy,
    //exception
    output div_by_zero,
    output zero_div,
    //dout
    output [11+`RES_WIDTH-1:0] out //output width defined in 'div_f_para.v'
);

    //exception trigger signals
    wire [7:0] dividend_exp = dividend[30:23];
    wire [7:0] divisor_exp = divisor[30:23];
    wire [22:0] dividend_frac = dividend[22:0];
    wire [22:0] divisor_frac = divisor[22:0];
    wire dividend_s = dividend[31];
    wire divisor_s = divisor[31];

    /*output sign bit is always ^*/
    assign out[11+`RES_WIDTH-1] = dividend_s ^ divisor_s;

    //preprocess determine if is exception
    //if so, output is ready within sel cycle
    wire divisor_exp_0 = divisor_exp == 8'h0;
    wire divisor_frac_0 = divisor_frac == 23'h0;
    /*div by zero*/
    wire divisor_0 = divisor_exp_0 & divisor_frac_0;
    assign div_by_zero = divisor_0 & sel;   //divisor is zero and div unit selected
    //localparam NAN = 32'hffff_ffff; //then output Nan
    /*nan involved*/
    wire dividend_exp_ff = dividend_exp == 8'hff;
    wire dividend_frac_not_0 = dividend_frac != 23'h0;
    wire dividend_nan = dividend_exp_ff & dividend_frac_not_0;
    wire divisor_exp_ff = divisor_exp == 8'hff;
    wire divisor_frac_not_0 = divisor_frac != 23'h0;
    wire divisor_nan = divisor_exp_ff & divisor_frac_not_0;

    wire nan_involved = dividend_nan | divisor_nan; //then output nan
    /*0 div*/
    wire dividend_exp_0 = dividend_exp == 8'h0;
    wire dividend_frac_0 = dividend_frac == 23'h0;
    wire dividend_0 = dividend_frac_0 & dividend_exp_0;
    assign zero_div = dividend_0;
    //localparam ZERO = 32'h0000_0000;    //then output zero
    
    /*inf div*/
    wire dividend_inf = dividend_exp_ff & dividend_frac_0;
    wire divisor_inf = divisor_exp_ff & divisor_frac_0;
    wire inf_div = dividend_inf & (~divisor_inf);   //then output inf
    wire inf_div_inf = divisor_inf & dividend_inf;  //then output nan

    /*div inf*/
    wire div_inf = (~dividend_inf) & divisor_inf;   //then output 0(underflow)

    //output stage ctl signal
    wire one_cycle = div_by_zero | nan_involved | zero_div | inf_div | inf_div_inf | div_inf;

    //if none of the above happens, then dividend is normal number
    //divisor is normal number, and they are both above zero
    //MSB canbe found in both float numbers
    /*denorm conditions,frac start width 0*/
    wire dividend_denorm = dividend_exp_0;
    wire divisor_denorm = divisor_exp_0;
    /*norm condition,frac start width 1*/
    wire dividend_norm = (~dividend_denorm);
    wire divisor_norm = (~divisor_denorm);

    wire [24-1:0] dividend_u = {dividend_denorm? 1'b0 : 1'b1,dividend[22:0]};
    wire [24-1:0] divisor_u = {divisor_denorm? 1'b0 : 1'b1,divisor[22:0]};

    //output signal of div32_f_top
    wire busy_ctl_f;
    wire [`RES_WIDTH-1:0] res;

    //ctl signal for div32_f_top unit
    wire start_f_div = sel & (~one_cycle);  //selected and not a one cycle res condition
    reg start_f_div_ff;
    always@(posedge clk) start_f_div_ff <= #1 start_f_div;
    wire start_f_div_actual = start_f_div & (~start_f_div_ff);
    assign busy = start_f_div_actual | busy_ctl_f; //when start valid, its busy so hold the value in ID/EX pipeline regs and other components

    //div32_f_top unit
    div32_f_top u0(.clk(clk),.rst(rst),.start(start_f_div_actual),.busy(busy_ctl_f),.dividend(dividend_u),.divisor(divisor_u),.res(res));

    //output stage
    wire [9:0] exp_out = dividend_exp - divisor_exp + 10'd127;
    assign out[11+`RES_WIDTH-2:0] = (div_by_zero | nan_involved | inf_div_inf)? `NAN : 
                (zero_div | div_inf)? `ZERO :
                inf_div? `INF: {exp_out,res};

endmodule
