`include "div_f_para.v"

module controller(
    //clk 
    input clk,
    input rst,
    //ctl signal
    input start,
    output busy,
    //input data
    input [`WIDTH-1:0] u_dividend,
    input [`WIDTH-1:0] u_divisor,
    //ctl signal for submodules
    output [`WIDTH*2-1:0]init_val,
    output ld,
    output sl,
    input f_done
);
    /////////////////////////////////////dividend&divisor组合逻辑////////////////////////////////
    wire [`WIDTH_LOG_2-1:0] L1;
    wire [`WIDTH_LOG_2-1:0] L2;

    //MSB_get u_MSB_0 (.in(u_dividend),.out(L1));
    //MSB_get u_MSB_1 (.in(u_divisor),.out(L2));

    ////////////////////////////////////参数定义////////////////////////////////
    localparam state0 = `STATE_WIDTH'h1;   //IDLE
    localparam state1 = `STATE_WIDTH'h2;   //div_s
    //////////////////////////////////变量///////////////////////////////////////
    reg [`STATE_WIDTH-1:0] state;
    reg busy_ff;

    //////////////////////////////////FSM//////////////////////////////////////
    always@(posedge clk) begin
        if(rst) begin
            state <= #1 state0;
        end
        else begin
            case(state)
            state0 : begin  //IDLE
                if(start) begin
                   state <= #1 state1;
                   busy_ff <= #1 1'b1; 
                end 
                else begin
                   state <= #1 state; 
                   busy_ff <= #1 1'b0;    //clear busy bit
                end 
            end
            state1: begin   //div_s
                if(f_done) begin
                   state <= #1 state0;
                   busy_ff <= #1 1'b1; 
                end 
                else begin
                    state <= #1 state;
                    busy_ff <= #1 1'b1;
                end 
            end
            default: begin
                state <= #1 state0;
                busy_ff <= #1 1'b0;
            end 
            endcase
        end
    end

    //////////////////////////////state状态////////////////////////////////
    wire in_idle = state[0];
    wire in_div_s = state[1];

    //////////////////////////////output////////////////////////////////////
    assign busy = busy_ff;
    assign ld = in_idle & start;
    assign sl = in_div_s;
    //assign init_val = {(u_dividend<<L1),(u_divisor<<L2)};
    assign init_val = {u_dividend,u_divisor};

endmodule
