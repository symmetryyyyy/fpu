// 1024*32 Memory model: Depth is 1024, width is 32-bit
module memory(
clock,
sel,
addr,
wen,
wdata,
rdata
);

input           clock;
input           sel;
input  [31:0]   addr;
input           wen;
input  [31:0]   wdata;
output [31:0]   rdata;

reg    [31:0]   data_cell[1023:0];
reg    [31:0]   rdata;

//write operation
always@(posedge clock)
begin
  if(sel && wen)
    data_cell[addr[11:2]] <= #1 wdata;
end

always@(*)
begin
  rdata = data_cell[addr[11:2]];
end
endmodule