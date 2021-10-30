//~ `New testbench
`timescale  1ns / 1ps
`define MAX_CODE_LEN 1000

module tb_processor;

// processor Parameters
parameter PERIOD  = 10;

// processor Inputs
reg   cpu_clock                            = 0 ;
reg   cpu_reset_b                          = 0 ;
wire   [31:0]  instruction                 ;

// processor Outputs
wire  ins_fetch_req                        ;
wire  [31:0]  ins_pc                       ;


initial
begin
    forever #(PERIOD/2)  cpu_clock=~cpu_clock;
end

initial
begin
    cpu_reset_b = 1;
    #(PERIOD*2) cpu_reset_b  =  0;
end

processor  u_processor (
    .cpu_clock               ( cpu_clock             ),
    .cpu_reset_b             ( cpu_reset_b           ),
    .instruction             ( instruction    [31:0] ),

    .ins_fetch_req           ( ins_fetch_req         ),
    .ins_pc                  ( ins_pc         [31:0] )
);

reg [31:0] ins_mem[`MAX_CODE_LEN-1:0];
assign instruction = ins_mem[ins_pc[31:2]];
initial begin
    $readmemh("C:\\Users\\JKDito\\Desktop\\things\\FPU\\code.txt",ins_mem);
end

initial begin
    $dumpfile(".\\vcd\\sim.vcd");
    $dumpvar(0,tb_processor);
end

//testbench monitor of GPR and FPR

wire [31:0] GPR_0 = u_processor.GPR_regfile[0];
wire [31:0] GPR_1 = u_processor.GPR_regfile[1];
wire [31:0] GPR_2 = u_processor.GPR_regfile[2];
wire [31:0] GPR_3 = u_processor.GPR_regfile[3];

wire [31:0] FPR_0 = u_processor.u_FPU.u_FPR.regfile[0][31:0];
wire [31:0] FPR_1 = u_processor.u_FPU.u_FPR.regfile[0][63:32];
wire [31:0] FPR_2 = u_processor.u_FPU.u_FPR.regfile[1][31:0];
wire [31:0] FPR_3 = u_processor.u_FPU.u_FPR.regfile[1][63:32];

endmodule