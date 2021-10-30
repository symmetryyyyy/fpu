`include "div_f_para.v"

module div_f_core(
    //clk
    input clk,
    input rst,
    //init input
    input [2*`WIDTH-1:0] init_val,
    //ld and sl
    input ld,
    input sl,
    //output 
    output done,
    output [`RES_WIDTH-1:0] res
);
    ////////////////////////////////////////////////////信号定义/////////////////////////////////////////
    //result reg
    reg [`RES_WIDTH-1:0] res_reg;
    //divisor wiring
    wire [`WIDTH-1:0] divisor_val;
    //remainder reg
    reg [`WIDTH:0] remainder_reg;
    //n reg
    reg [`WIDTH_LOG_2-1:0] n;
    //MUX2 output
    wire [`WIDTH-1:0] mux2_out;
    //sub result
    wire [`WIDTH-1:0] sub_out;
    //new_quo signal gen by sub, shift right into res_reg
    wire larger,equal;
    wire new_quo;
    wire last_n;
    wire remainder_0;

    ////////////////////////////////////////////////////组合逻辑//////////////////////////////////////////
    assign divisor_val = init_val[`WIDTH-1:0];
    assign sub_out = remainder_reg - {1'b0,divisor_val}; //main sub to generate new remainder
    assign larger = remainder_reg > {1'b0,divisor_val};    //cmp to generate quotient val
    assign equal = remainder_reg == {1'b0,divisor_val};    //cmp to generate quotient val
    assign last_n = n == `RES_WIDTH_LOG_2'h0;
    assign remainder_0 = remainder_reg == {1'b0,`WIDTH'h0};
    assign new_quo = larger | equal | ((last_n & (~remainder_0))? 1'b1 : 1'b0);        //either larger or equal result in 1'b1 write val
    assign mux2_out = new_quo? sub_out : remainder_reg;
    assign res = res_reg;

    /////////////////////////////////////////////////////时序逻辑/////////////////////////////////////////
    //quo_reg
    always@(posedge clk) begin
        if(ld | rst) begin
            res_reg <= #1 `RES_WIDTH'h0;
        end
        else begin
            if(sl) begin
                res_reg[n] <= #1 new_quo;      //write bits in actual order
            end
            else begin
                res_reg <= #1 res_reg;
            end
        end
    end

    //remainder_reg
    always@(posedge clk) begin
        if(rst) begin
            remainder_reg <= #1 {1'b0,`WIDTH'h0};
        end
        else if(ld) begin
            remainder_reg <= #1 {1'b0,init_val[2*`WIDTH-1:`WIDTH]};
        end
        else begin
            if(sl) begin
                remainder_reg[`WIDTH:1] <= #1 mux2_out;   //shift left, 0 input
                remainder_reg[0] <= #1 1'b0;
            end
            else begin
                remainder_reg <= #1 remainder_reg;     //余项不需要更新或者并不处于计算周期
            end
        end
    end

    //n reg
    localparam N_RELOAD_VAL = `RES_WIDTH_LOG_2'd`RES_WIDTH - `RES_WIDTH_LOG_2'd1;
    always@(posedge clk) begin
        if(ld | rst) begin
            n <= #1 N_RELOAD_VAL;
        end
        else begin
            if(sl) begin
                n <= #1 n - `RES_WIDTH_LOG_2'h1;   //sl下递增1
            end
            else begin
                n <= #1 n;     //否则保持
            end
        end
    end

    /////////////////////////////////done signal/////////////////////////////////////
    assign done = last_n | equal;     //terminate ahead of time when equal happens

endmodule
