`timescale  1ns / 1ps
module add_sub_f(
    //func sel
    input sel,  //valid if sub
    //din
    input [63:0] dina,
    input [63:0] dinb,
    //dout
    output [71:0] dout
);

    add_core u0(.sel(sel),.dina(dina[31:0]),.dinb(dinb[31:0]),.dout(dout[35:0]));
    add_core u1(.sel(sel),.dina(dina[63:32]),.dinb(dinb[63:32]),.dout(dout[71:36]));
    //def and wiring

    //exception process

    //assignment

endmodule

module add_core(
    input sel,
    input [31:0] dina,
    input [31:0] dinb,
    output [35:0] dout
);

    //exp identify
    wire [7:0] exp_a_val = (dina[30:23] == 8'h0)? 8'h1 : dina[30:23];
    wire [7:0] exp_b_val = (dinb[30:23] == 8'h0)? 8'h1 : dinb[30:23];
    wire [7:0] exp_a = dina[30:23];
    wire [7:0] exp_b = dinb[30:23];
    wire sign_a = dina[31];
    wire sign_b = sel? (~dinb[31]) : dinb[31];      //when selected, a-b instead of a+b
    wire [22:0]frac_a = dina[22:0];
    wire [22:0]frac_b = dinb[22:0];

    //select largest exp
    wire reverse = exp_b > exp_a;     //when valid, apply a neg op at M
    //we perform a + b by default
    wire [7:0] M = (reverse? exp_b_val : exp_a_val) - (reverse? exp_a_val : exp_b_val);
    wire add_zero = reverse? (frac_a == 23'h0) : (frac_b == 23'h0);
    //judge if M >= 24
    //wire M_larger_24 = M >= 8'd24;
    //actually 27bit of signed integer add op is needed
    //convert 25bit signed into aligned 27bit signed
    wire [26:0] add_in_0;
    wire [26:0] add_in_1;
    wire [24:0] shift_M_in; 
    assign add_in_0[1:0] = 2'b00;
    //denorm
    wire top_b = (exp_b == 8'h00)? 1'b0 : 1'b1;
    wire top_a = (exp_a == 8'h00)? 1'b0 : 1'b1;
    //end denorm
    sign_gen u_add_in_0 (.din(reverse? {sign_b,top_b,frac_b} : {sign_a,top_a,frac_a}),.dout(add_in_0[26:2]));
    sign_gen u_shift_M_in (.din(reverse? {sign_a,top_a,frac_a} : {sign_b,top_b,frac_b}),.dout(shift_M_in));
    shift_by_M u_add_in_1 (.M(M),.din(shift_M_in),.dout(add_in_1));
    wire [27:0] add_out = {add_in_0[26],add_in_0} + {add_in_1[26],add_in_1};
    wire sign_bit_out = add_out[27];
    wire [26:0] unsigned_frac_out;
    wire sub_to_zero = unsigned_frac_out == 27'h0;
    unsign_gen u_unsigned_frac_out(.din(add_out),.dout(unsigned_frac_out));
    //output frac is 27 bit
    assign dout[35] = sign_bit_out;
    assign dout[34:27] = sub_to_zero? 8'h0:(reverse? exp_b : exp_a);        //sub_to_zero used to make debug easier
    assign dout[26:0] = unsigned_frac_out;

endmodule

module shift_by_M(
    input [7:0] M,
    input [24:0] din,
    output [26:0] dout 
);

    reg [26:0] dout_reg;
    wire sign_bit = din[24];
    wire din_not_0 = din[23:0] != 24'h0;
    wire [26:0] sign_extend_of_din_not_0;
    genvar idx;
    generate for(idx=0;idx<27;idx=idx+1) begin : u_sign_extend
        assign sign_extend_of_din_not_0[idx] = din_not_0;
    end
	 endgenerate

    wire [23:0] last_bit;
    generate for(idx=0;idx<24;idx=idx+1) begin : u_last_bit
        assign last_bit[idx] = din[idx:0] != 'h0;
    end
	 endgenerate

    //sign extend of din, last bit is the 

    always@(*) begin
        case(M)
        0 : dout_reg={din[24:0],2'b00};
        1 : dout_reg={din[24],din[24:0],1'b0};
        2 : dout_reg={din[24],din[24],din[24:1],last_bit[0]};
        3 : dout_reg={din[24],din[24],din[24],din[24:2],last_bit[1]};
        4 : dout_reg={din[24],din[24],din[24],din[24],din[24:3],last_bit[2]};
        5 : dout_reg={din[24],din[24],din[24],din[24],din[24],din[24:4],last_bit[3]};
        6 : dout_reg={din[24],din[24],din[24],din[24],din[24],din[24],din[24:5],last_bit[4]};
        7 : dout_reg={din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24:6],last_bit[5]};
        8 : dout_reg={din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24:7],last_bit[6]};
        9 : dout_reg={din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24:8],last_bit[7]};
        10 : dout_reg={din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24:9],last_bit[8]};
        11 : dout_reg={din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24:10],last_bit[9]};
        12 : dout_reg={din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24:11],last_bit[10]};
        13 : dout_reg={din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24:12],last_bit[11]};        
        14 : dout_reg={din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24:13],last_bit[12]};
        15 : dout_reg={din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24:14],last_bit[13]};
        16 : dout_reg={din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24:15],last_bit[14]};
        17 : dout_reg={din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24:16],last_bit[15]};
        18 : dout_reg={din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24:17],last_bit[16]};
        19 : dout_reg={din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24:18],last_bit[17]};
        20 : dout_reg={din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24:19],last_bit[18]};
        21 : dout_reg={din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24:20],last_bit[19]};
        22 : dout_reg={din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24:21],last_bit[20]};
        23 : dout_reg={din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24:22],last_bit[21]};
        24 : dout_reg={din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24:23],last_bit[22]};
        25 : dout_reg={din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24],din[24:24],last_bit[23]};
        default: dout_reg = sign_bit? sign_extend_of_din_not_0 : {26'h0,din_not_0};
        endcase
    end //???????????????????????????????????????????????????????????????????????????????????????27bit???????????????????????????????????????????????????????????????????????????????????????bit???1?????????????????????27bit???????????????1?????????????????????????????????0??????????????????bit????????????0


    assign dout = dout_reg;

endmodule

module sign_gen(
    input [24:0] din,
    output [24:0] dout
);

    localparam MAX_VAL_UNSIGNED = 25'h0000000;

    wire sign_bit = din[24];
    wire [23:0] unsigned_in = din[23:0];
    assign dout = sign_bit? (MAX_VAL_UNSIGNED - unsigned_in) : unsigned_in;

endmodule

module unsign_gen(
    input [27:0] din,
    output [26:0] dout
);

    wire sign_bit = din[27];
    wire [26:0]unsigned_in = din[26:0];

    localparam MAX_VAL_UNSIGNED = 27'h0000000;

    assign dout[26:0] = sign_bit? (MAX_VAL_UNSIGNED - unsigned_in) : unsigned_in;

endmodule
