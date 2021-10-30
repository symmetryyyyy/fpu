`timescale  1ns / 1ps
module processor(
    input cpu_clock,
    input cpu_reset_b,
    output ins_fetch_req,
    output [31:0]ins_pc,
    input [31:0]instruction
);

    //IF
    /*in sim, PC has no jump. excecute in order*/
    wire hold;
    reg [31:0] PC;
    initial begin
        PC = 32'h0;
    end
    wire clk = cpu_clock;
    wire rst = ~cpu_reset_b;
    always@(posedge clk) begin
        if(rst) begin
            PC <= #1 32'h0000_0000;
        end
        else begin
            if(~hold) PC <= #1 PC + 32'h4;
            else PC <= #1 PC;
        end
    end
    assign ins_pc = PC;
    assign ins_fetch_req = ~hold;

    //GPR&ID
    reg [31:0] GPR_regfile[31:0];
    wire [31:0] GPR_out;
    wire [31:0] GPR_in;
    wire [5:0] opcode = instruction[5:0];
    wire [4:0] fmt = instruction[25:21];
    localparam MF = 5'h0;   //GPR[rt] <- GPR_in  (instruction delay 2 regs)
    localparam MT = 5'h4;   //GPR_out <- GPR[rt] (instruction delay 2 regs)
    wire op_mfc = opcode == MF;
    wire op_mtc = opcode == MT;
    wire [4:0]rs = instruction[15:11];
    wire [4:0]rt = instruction[20:16];
    wire [4:0]rd = instruction[10:6];  
    wire [15:0]immediate = instruction[15:0];
    wire [5:0]op_real = instruction[31:26];
    localparam LUI = 6'b001111;     //GPR[rt] <- immediate<<16
    localparam ORI = 6'b001101;     //GPR[rt] <- GPR[fmt] | immediate

    wire [31:0] GPR_out_wire = GPR_regfile[rt];
    wire [31:0] GPR_fmt = GPR_regfile[fmt];

    //delay reg for instruction's opcode field and rt field;
    reg [31:0] instruction_ff1,instruction_ff2;
    always@(posedge clk) begin
        instruction_ff1 <= #1 instruction;
        instruction_ff2 <= #1 instruction_ff1;
    end
    wire [4:0] rt_ff2_wire = instruction_ff2[20:16];
    wire [4:0] opcode_ff2_wire = instruction_ff2[25:21];
    wire [5:0] op_real_ff2_wire = instruction_ff2[31:26];
    /*we can always fetch GPR[rt_ff2_wire], no need to check if data is acked*/
    assign GPR_out = GPR_regfile[rt_ff2_wire];
    wire MFC1 = opcode_ff2_wire == MF &  op_real_ff2_wire == 6'h11 & instruction_ff2[10:0] == 11'h000;   //decode MFC1 op, COP1 = 0x11

    //all LUI and ORI ops are excecuted in one cycle, here we 
    //break the timing of MIPS ISA, but make coding easier
    genvar i;
    for(i=0;i<32;i=i+1) begin
        initial begin
            GPR_regfile[i] = 32'h0;
        end
    end
    always@(posedge clk) begin
        if(op_real == LUI) begin
            GPR_regfile[rt] <= #1 immediate<<16;
        end
        else if(op_real == ORI) begin
            GPR_regfile[rt] <= #1 GPR_regfile[fmt] | immediate;
        end
        if(MFC1) GPR_regfile[rt_ff2_wire] <= #1 GPR_in;        //individual write channel for MFC1, cause timing breaked
    end

    //EX

    //mem

    //WB

    //FPU
    FPU u_FPU(.clk(clk),.rst(rst),.hold(hold),.inst(instruction),.GPR_out(GPR_out),.GPR_in(GPR_in));

endmodule
