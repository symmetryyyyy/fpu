`include "div_f_para.v"
`include "cvt_para.v"

module FPU(
    //clk
    input clk,
    input rst,
    //out hold, in instruction
    output hold,
    input [31:0] inst,
    //GPR input/output
    input [31:0] GPR_out,
    output [31:0] GPR_in
);

    /////////////////////////ID////////////////////////
    wire COP1 = inst[31:26] == 6'h11;
    wire [5:0]opcode = inst[5:0];
    wire [4:0]fs = inst[15:11];
    wire [4:0]ft = inst[20:16];
    wire [4:0]fd = inst[10:6];
    wire [4:0]fmt = inst[25:21];
    wire [63:0]FPR_ft;
    wire [63:0]FPR_fs;
    wire [`CVT_SUB_SEL_WIDTH-1:0]ID_op_sub_sel;       

    /*output into ID/EX*/
    localparam ADD = 6'h0;
    localparam SUB = 6'h1;
    localparam MUL = 6'h2;
    localparam DIV = 6'h3;
    localparam MF = 5'h0;
    localparam MT = 5'h4;
    localparam FMT_S = 5'h10;   //single
    localparam FMT_D = 5'h11;   //double    (not im in this design)
    localparam FMT_W = 5'h14;   //word  (not im in this design)
    localparam FMT_L = 5'h15;   //long  (not im in this design)
    localparam FMT_PS = 5'h16;  //pair single
    //during .S operations, fetch address canbe not even, LSB used to select high word or low word
    wire fmt_s = fmt == FMT_S;
    wire fmt_ps = fmt == FMT_PS;
    wire fmt_not_0 = fmt[4];
    wire op_add = opcode == ADD;
    wire op_sub = opcode == SUB;
    wire op_mul = opcode == MUL;
    wire op_div = opcode == DIV;
    wire ins_mov_FPU = inst[10:0] == 11'h000;
    wire ins_mfc_mtc = COP1 & ins_mov_FPU;
    wire op_mfc = fmt == MF & ins_mfc_mtc;
    wire op_mtc = fmt == MT & ins_mfc_mtc;
    wire op_cvt = ID_op_sub_sel !=`CVT_NONE; 
    wire [1:0] cvt_we;
    wire add_s = op_add & fmt_s;    //add.s
    wire sub_s = op_sub & fmt_s;    //sub.s
    wire mul_s = op_mul & fmt_s;    //mul.s
    wire div_s = op_div & fmt_s;    //div.s
    //wire ID_rd_sel_en = COP1 & (add_s|sub_s|mul_s|div_s);
    wire FPU_write = COP1 & ( op_add | op_div | op_mul | op_sub | op_cvt ) & (fmt_not_0); //indicate that this is an FPU internal op
    wire implemented_op = FPU_write | op_mtc;   //ops that include a write to FPR act
    wire [63:0]ID_FPR_ft = (/*ID_rd_sel_en & */ft[0])? {32'h0,FPR_ft[63:32]} : FPR_ft;
    wire [63:0]ID_FPR_fs = (/*ID_rd_sel_en & */fs[0])? {32'h0,FPR_fs[63:32]} : FPR_fs;
    wire [4:0]ID_fd = op_mtc ? fs : fd; //write register adddress is always fd except MTC1 op{FPR[fs]<-GPR[rt]} 
    wire [1:0]ID_wr = implemented_op? ((implemented_op & op_cvt)? (cvt_we) : (((fmt_ps) & (~op_mtc))? 2'b11 : ((((fmt_s) & fd[0] & (~op_mtc)) | (op_mtc & fs[0]))? 2'b10 : 2'b01))) : 2'b00;  //at .ps ops, write both word, otherwise low word
    wire [0:0]ID_div_sel = op_div & COP1 & fmt_not_0;

    decode_cvt u_decode_cvt(.opcode(opcode),.fmt(fmt),.fd(fd[0]),.we(cvt_we),.cvt_sel(ID_op_sub_sel));

    ////////////////////////////ID/EX//////////////////////////////////
    localparam ID_EX_WIDTH = 64*2 /*ft&fs*/ + 6 /*op*/ + 5 /*fd*/ + 1 /*op_sel*/ + `CVT_SUB_SEL_WIDTH /*op_sub_sel*/
                             + 2 /*wr*/ + 1 /*FPU_write*/ + 1 /*fs[0]*/ + 1 /*mfc1*/;
    reg [ID_EX_WIDTH-1:0] ID_EX_reg;
    always@(posedge clk) begin
        if(rst) ID_EX_reg <= #1 'h0;
        else if(~hold) ID_EX_reg <= #1 {ID_FPR_fs,ID_FPR_ft,opcode,ID_fd,ID_div_sel,ID_op_sub_sel,ID_wr,FPU_write,fs[0],op_mfc};
        else ID_EX_reg <= #1 ID_EX_reg;
    end

    /////////////////////////////////EX/////////////////////////////////
    wire [63:0] EX_FPR_ft;
    wire [63:0] EX_FPR_fs;
    wire [4:0] EX_fd;
    wire [5:0] EX_opcode;
    wire EX_div_sel;
    wire [`CVT_SUB_SEL_WIDTH-1:0]EX_op_sub_sel;    
    wire [1:0] EX_wr;
    wire EX_FPU_write;
    wire EX_fs_0;
    wire EX_mfc;
    assign {EX_FPR_fs,EX_FPR_ft,EX_opcode,EX_fd,EX_div_sel,EX_op_sub_sel,EX_wr,EX_FPU_write,EX_fs_0,EX_mfc} = ID_EX_reg;

    /*div unit*/
    wire [11+`RES_WIDTH-1:0] div_out;
    wire div_by_zero;
    div_f u_div_f(.clk(clk),.rst(rst),.sel(EX_div_sel),.dividend(EX_FPR_fs[31:0]),.divisor(EX_FPR_ft[31:0]),.busy(hold),.div_by_zero(div_by_zero),.zero_div(),.out(div_out));
    /*mul unit*/
    wire [117:0] mul_out;
    mul_s u_mul_s(.a(EX_FPR_fs),.b(EX_FPR_ft),.out(mul_out));
    /*add/sub unit*/
    wire add_sub_f_sel = (EX_opcode == SUB);
    wire [71:0] add_sub_f_out;
    add_sub_f u_add_sub_f(.sel(add_sub_f_sel),.dina(EX_FPR_fs),.dinb(EX_FPR_ft),.dout(add_sub_f_out));
    /*cvt unit*/
    wire [63:0] cvt_out;
    wire cvt_sel = EX_op_sub_sel !=`CVT_NONE;   //by default, zero indicate unsel
    cvt u_cvt(.sel(EX_op_sub_sel),.dina(EX_FPR_fs),.dinb(EX_FPR_ft),.dout(cvt_out));
    /*MFC/MTC path*/
    //done in mux_out

    localparam DIV_PAD_WIDTH = 59 - 11 - `RES_WIDTH;
    wire [DIV_PAD_WIDTH-1:0] div_pad = 'h0;
    wire [117:0] mux_out;
    assign mux_out = EX_mfc?              {54'h0,EX_FPR_fs} :
                     (EX_opcode == MUL) ? mul_out :
                     (EX_opcode == DIV) ? {div_out,div_pad} :
                     cvt_sel?   {54'h0,cvt_out} :
                     (add_sub_f_sel | (EX_opcode == ADD))? {46'h0,add_sub_f_out} : 116'h0; //include zero condition in ADD, caution
    
    ///////////////////////////////EX/WB/////////////////////////////////////
    localparam EX_WB_WIDTH = 118 /*mux_out*/ + 6 /*op*/ + 5 /*fd*/ + 2  /*wr*/ + 1 /*FPU_write*/ 
                            + 1 /*EX_fs_0*/ + 1 /*cvt_sel*/ + 1 /*div_by_zero*/;
    reg [EX_WB_WIDTH-1:0] EX_WB_reg;
    always@(posedge clk) begin
        if(rst) EX_WB_reg <= #1 'h0;
        else if(~hold) EX_WB_reg <= #1 {mux_out,EX_opcode,EX_fd,EX_wr,EX_FPU_write,EX_fs_0,cvt_sel,div_by_zero};
        else EX_WB_reg <= #1 EX_WB_reg;
    end

    /////////////////////////////////////WB/////////////////////////////////
    wire [5:0] WB_opcode;
    wire [117:0] WB_round_in;
    wire WB_cvt_sel;    //valid when op is cvt
    wire [63:0] WB_write_val;
    wire [1:0] WB_we;
    wire WB_sel;
    wire WB_fs_0;
    wire [4:0] WB_fd;
    wire WB_div_by_zero;
    wire WB_p_op = WB_we == 2'b11;

    assign {WB_round_in,WB_opcode,WB_fd,WB_we,WB_sel,WB_fs_0,WB_cvt_sel,WB_div_by_zero} = EX_WB_reg;
    assign GPR_in = WB_round_in[31:0];
    wire [63:0] round1_out;
    wire [63:0] round2_out;
    wire WB_add_sub_f_sel = (WB_opcode == SUB) | (WB_opcode == ADD);

    wire overflow0,overflow1;
    wire underflow0,underflow1;
    wire inexact0,inexact1;
    round1 u_round1(.p_op(WB_p_op),.din(WB_round_in),.dout(round1_out),.overflow(overflow0),.underflow(underflow0),.inexact(inexact0));     //TODO...........
    round2 u_round2(.p_op(WB_p_op),.din(WB_round_in[71:0]),.dout(round2_out),.overflow(overflow1),.underflow(underflow1),.inexact(inexact1));

    assign WB_write_val = WB_cvt_sel? WB_round_in[63:0] : (WB_add_sub_f_sel? round2_out : round1_out);
    wire [3:0] WB_exception_in = WB_add_sub_f_sel? {1'b0,overflow1,underflow1,inexact1} :
                                                    {WB_div_by_zero,overflow0,underflow0,inexact0};

    wire [1:0]wr = WB_we;
    //我们默认对于输出fd为单字格式的时候数据在低字，因此需要根据写fd切换顺序（因此注意PS格式的fd必须为偶数不然会导致word flip）
    wire [63:0]din = WB_sel? ((WB_fd[0])? {WB_write_val[31:0],WB_write_val[63:32]} : WB_write_val) : (WB_fs_0? {GPR_out,32'h0} : {32'h0,GPR_out});
    
    FPR u_FPR(.clk(clk),.wr(wr),.fd(WB_fd[4:1]),.din(din),.ft(ft[4:1]),.fs(fs[4:1]),.FPR_ft(FPR_ft),.FPR_fs(FPR_fs));

    ////////////////////////////////////////exception//////////////////////////
    reg [3:0] exception_reg;
    always@(posedge clk) begin
        if(rst) exception_reg <= #1 4'h0;
        else begin
            if(~hold & WB_sel & (~WB_cvt_sel)) exception_reg <= #1 WB_exception_in;
            else exception_reg <= #1 exception_reg;
        end
    end

endmodule
