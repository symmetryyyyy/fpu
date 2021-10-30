`include "div_f_para.v"

module div32_f_top(
    //clk
    input clk,
    input rst,
    //ctl
    input start,
    output busy, 
    //input
    input [`WIDTH-1:0] dividend,
    input [`WIDTH-1:0] divisor,
    //output
    output [`RES_WIDTH-1:0] res
);
    ////////////////////////////////////////////////////signal////////////////////////////////////////////
    wire [`WIDTH-1:0] u_dividend = dividend;
    wire [`WIDTH-1:0] u_divisor = divisor;
    wire [2*`WIDTH-1:0] init_val;
    wire ld,sl,ct_done;
    wire [`WIDTH_LOG_2-1:0] f;

    ///////////////////////////////////////////////////module/////////////////////////////////////////////
    div_f_core u0(.clk(clk),.rst(rst),.init_val(init_val),.ld(ld),.sl(sl),.res(res),.done(ct_done));
    controller u1(.clk(clk),.rst(rst),.start(start),.busy(busy),.u_dividend(u_dividend),.u_divisor(u_divisor),.init_val(init_val),.ld(ld),.sl(sl),.f_done(ct_done));

endmodule
