`include "div_f_para.v"

module MSB_get(
    input [`WIDTH-1:0] in,
    output [`WIDTH_LOG_2-1:0] out
);

    reg [`WIDTH_LOG_2-1:0] out_r;
    always@(*) begin
        if(in[`WIDTH-1]) out_r = `WIDTH_LOG_2'd0;
        else if(in[`WIDTH-2]) out_r = `WIDTH_LOG_2'd1;
        else if(in[`WIDTH-3]) out_r = `WIDTH_LOG_2'd2;
        else if(in[`WIDTH-4]) out_r = `WIDTH_LOG_2'd3;
        else if(in[`WIDTH-5]) out_r = `WIDTH_LOG_2'd4;
        else if(in[`WIDTH-6]) out_r = `WIDTH_LOG_2'd5;
        else if(in[`WIDTH-7]) out_r = `WIDTH_LOG_2'd6;
        else if(in[`WIDTH-8]) out_r = `WIDTH_LOG_2'd7;
        else if(in[`WIDTH-9]) out_r = `WIDTH_LOG_2'd8;
        else if(in[`WIDTH-10]) out_r = `WIDTH_LOG_2'd9;
        else if(in[`WIDTH-11]) out_r = `WIDTH_LOG_2'd10;
        else if(in[`WIDTH-12]) out_r = `WIDTH_LOG_2'd11; 
        else if(in[`WIDTH-13]) out_r = `WIDTH_LOG_2'd12;
        else if(in[`WIDTH-14]) out_r = `WIDTH_LOG_2'd13;
        else if(in[`WIDTH-15]) out_r = `WIDTH_LOG_2'd14; 
        else if(in[`WIDTH-16]) out_r = `WIDTH_LOG_2'd15;
        else if(in[`WIDTH-17]) out_r = `WIDTH_LOG_2'd16;
        else if(in[`WIDTH-18]) out_r = `WIDTH_LOG_2'd17; 
        else if(in[`WIDTH-19]) out_r = `WIDTH_LOG_2'd18;
        else if(in[`WIDTH-20]) out_r = `WIDTH_LOG_2'd19;
        else if(in[`WIDTH-21]) out_r = `WIDTH_LOG_2'd20; 
        else if(in[`WIDTH-22]) out_r = `WIDTH_LOG_2'd21; 
        else if(in[`WIDTH-23]) out_r = `WIDTH_LOG_2'd22;
        /*else if(in[`WIDTH-24]) out_r = `WIDTH_LOG_2'd8;
        else if(in[`WIDTH-25]) out_r = `WIDTH_LOG_2'd7; 
        else if(in[`WIDTH-26]) out_r = `WIDTH_LOG_2'd6;
        else if(in[`WIDTH-27]) out_r = `WIDTH_LOG_2'd5;
        else if(in[`WIDTH-28]) out_r = `WIDTH_LOG_2'd4; 
        else if(in[`WIDTH-29]) out_r = `WIDTH_LOG_2'd3;
        else if(in[`WIDTH-30]) out_r = `WIDTH_LOG_2'd2;
        else if(in[`WIDTH-31]) out_r = `WIDTH_LOG_2'd1;*/
        else out_r = `WIDTH_LOG_2'd23; 
    end

    assign out = out_r;

endmodule
