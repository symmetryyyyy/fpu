`timescale  1ns / 1ps
module FPR(
    //clk
    input clk,
    //wr
    input [1:0]wr,
    input [3:0] fd,
    input [63:0] din,
    //rd
    input [3:0] ft,
    input [3:0] fs,
    output [63:0] FPR_ft,
    output [63:0] FPR_fs
);

    reg [63:0] regfile[15:0];

    //varification code
    genvar i;
    generate for(i=0;i<16;i=i+1) begin : u_init
       initial regfile[i] = 64'h0000000000000000; 
    end
	 endgenerate

    wire wr_en = wr != 2'b00;

    //wr port
    always@(posedge clk) begin
        if(wr_en) begin
            if(wr[1] & wr[0]) regfile[fd] <= #1 din;
            else if(wr[1] & ~wr[0]) regfile[fd] <= #1 {din[63:32],regfile[fd][31:0]};
            else regfile[fd] <= #1 {regfile[fd][63:32],din[31:0]};  
        end
    end

    //rd port
    assign FPR_fs = regfile[fs];
    assign FPR_ft = regfile[ft];

endmodule
