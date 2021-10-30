`include "cvt_para.v"

module cvt(
    //select cvt
    input [2:0] sel,
    //din
    input [63:0] dina,  //fs
    input [63:0] dinb,  //ft
    //dout
    output [63:0] dout
);

    reg [63:0] dout_reg;

    wire [31:0] float_2_word_out;   //TODO....
    float2word u_float2word(.din(dina[31:0]),.dout(float_2_word_out));
    wire [31:0] word_2_float_out;   //TODO....
    word2float u_word2float(.din(dina[31:0]),.dout(word_2_float_out));

    always@(*) begin
        case(sel)
        `CVT_PS_S: dout_reg = {dina,dinb[31:0]};
        `CVT_S_W: dout_reg = {32'h0,word_2_float_out};
        `CVT_W_S: dout_reg = {32'h0,float_2_word_out};
        `CVT_S_PL: dout_reg = {32'h0,dina[31:0]};
        `CVT_S_PU: dout_reg = {32'h0,dina[63:32]};
        default: dout_reg = 64'h0;
        endcase
    end

    assign dout = dout_reg;

endmodule

module float2word(
    input [31:0] din,
    output [31:0] dout
);

    wire [7:0] exp = din[30:23];
    assign dout[31] = din[31];
    wire [22:0] frac = din[22:0];

    wire [53:0] frac_sl_exp_min_127 = {1'b1,frac}<<(exp-8'd127);
    wire guard_bit = frac_sl_exp_min_127[23];
    wire round_bit = frac_sl_exp_min_127[22];
    wire sticky_bit = frac_sl_exp_min_127[21:0] != 22'h0_0000;
    wire Incr = (round_bit&sticky_bit) | (round_bit&guard_bit&(~sticky_bit)); 
    //overfow happens only when din is positive
    //wire round_val_overfow = (frac_sl_exp_min_127[53:23] == 31'h7fff_ffff) & Incr & din[31];

    reg [30:0] pos_int_val;
    always@(*) begin
        if(exp<8'd127)
            pos_int_val = 31'h0;
        else if(exp>8'd157/* | round_val_overfow*/)     //always consider overfow caused by rounding
            pos_int_val = 31'h7fff_ffff;
        else
            pos_int_val = frac_sl_exp_min_127[53:23] + Incr;
    end

    assign dout[30:0] = din[31]? ((~pos_int_val)+31'h1) : pos_int_val;

endmodule

module word2float(
    input [31:0] din,
    output [31:0] dout
);

    assign dout[31] = din[31];
    wire [31:0] din_int_val = din[31]? ({1'b0,(~din[30:0])}+32'h1) : din[30:0];
    reg [4:0] MSB;
    wire [31:0] dout_frac_in = din_int_val << MSB;
    always@(*) begin
        if(din_int_val[31]) MSB = 5'd0;
        else if(din_int_val[30]) MSB = 5'd1;
        else if(din_int_val[29]) MSB = 5'd2;
        else if(din_int_val[28]) MSB = 5'd3;
        else if(din_int_val[27]) MSB = 5'd4;
        else if(din_int_val[26]) MSB = 5'd5;
        else if(din_int_val[25]) MSB = 5'd6;
        else if(din_int_val[24]) MSB = 5'd7;
        else if(din_int_val[23]) MSB = 5'd8;
        else if(din_int_val[22]) MSB = 5'd9;
        else if(din_int_val[21]) MSB = 5'd10;
        else if(din_int_val[20]) MSB = 5'd11;
        else if(din_int_val[19]) MSB = 5'd12;
        else if(din_int_val[18]) MSB = 5'd13;
        else if(din_int_val[17]) MSB = 5'd14;
        else if(din_int_val[16]) MSB = 5'd15;
        else if(din_int_val[15]) MSB = 5'd16;
        else if(din_int_val[14]) MSB = 5'd17;
        else if(din_int_val[13]) MSB = 5'd18;
        else if(din_int_val[12]) MSB = 5'd19;
        else if(din_int_val[11]) MSB = 5'd20;
        else if(din_int_val[10]) MSB = 5'd21;
        else if(din_int_val[9]) MSB = 5'd22;
        else if(din_int_val[8]) MSB = 5'd23;
        else if(din_int_val[7]) MSB = 5'd24;
        else if(din_int_val[6]) MSB = 5'd25;
        else if(din_int_val[5]) MSB = 5'd26;
        else if(din_int_val[4]) MSB = 5'd27;
        else if(din_int_val[3]) MSB = 5'd28;
        else if(din_int_val[2]) MSB = 5'd29;
        else if(din_int_val[1]) MSB = 5'd30;
        else MSB = 5'd31;
    end
    
    wire guard_bit = dout_frac_in[8];
    wire round_bit = dout_frac_in[7];
    wire sticky_bit = dout_frac_in[6:0] != 7'h00;
    wire Incr = (round_bit&sticky_bit) | (round_bit&guard_bit&(~sticky_bit)); 
    wire [22:0] out_frac_base = dout_frac_in[30:8];
    wire out_frac_base_max = out_frac_base == 23'h7f_ffff;
    wire out_frac_all_zero = out_frac_base_max & Incr;
    assign dout[30:23] = (din == 32'h0000_0000)? 8'h00 : ((out_frac_all_zero)? 8'd127 + 8'd32 - MSB : 8'd127 + 8'd31 - MSB);
    assign dout[22:0] = out_frac_all_zero? 23'h00_0000 : (out_frac_base + Incr);

endmodule

module decode_cvt(
    input [5:0] opcode,
    input [4:0] fmt,
    input fd,
    output [1:0] we,
    output [2:0] cvt_sel
);
    localparam FMT_S = 5'h10;   //single
    localparam FMT_D = 5'h11;   //double    (not im in this design)
    localparam FMT_W = 5'h14;   //word  (not im in this design)
    localparam CVT_PS_S_V = {5'h10,6'h26};
    localparam CVT_S_W_V = {FMT_W,6'h20};
    localparam CVT_W_S_V = {FMT_S,6'h24};
    localparam CVT_S_PL_V = {5'h16,6'h28};
    localparam CVT_S_PU_V = {5'h16,6'h20};  //validated! fmt!=0(used in FPU ID stage)

    reg [2:0]cvt_sel_reg;
    reg [1:0]we_reg;
    wire [1:0]we_by_fd = fd? 2'b10 : 2'b01;
    always@(*) begin
        case({fmt,opcode})
        CVT_PS_S_V: {we_reg,cvt_sel_reg} = {2'b11,`CVT_PS_S};
        CVT_S_W_V: {we_reg,cvt_sel_reg} = {we_by_fd,`CVT_S_W};
        CVT_W_S_V: {we_reg,cvt_sel_reg} = {we_by_fd,`CVT_W_S};
        CVT_S_PL_V: {we_reg,cvt_sel_reg} = {2'b01,`CVT_S_PL};
        CVT_S_PU_V: {we_reg,cvt_sel_reg} = {2'b10,`CVT_S_PU};
        default: {we_reg,cvt_sel_reg} = {2'b00,`CVT_NONE};        
        endcase
    end

    assign cvt_sel = cvt_sel_reg;
    assign we = we_reg;

endmodule