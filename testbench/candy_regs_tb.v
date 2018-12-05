`timescale 1ns/1ns

`include "candy_regs.v"
`include "candy_defines.v"


module candy_regs_tb;

reg clk;
reg rst;

reg reg1_read_enable;
reg reg2_read_enable;

wire [`RegBus] reg1_data;
wire [`RegBus] reg2_data;
reg [`RegAddrBus] reg1_addr;
reg [`RegAddrBus] reg2_addr;

reg write_enable;
reg [`RegAddrBus]waddr;
reg [`RegBus]wdata;

candy_regs regfile(
	.clk(clk),
	.rst(rst),
	.we(write_enable),
	.waddr(waddr),
	.wdata(wdata),
	.re1(reg1_read_enable),
	.raddr1(reg1_addr),
	.rdata1(reg1_data),
	.re2(reg2_read_enable),
	.raddr2(reg2_addr),
	.rdata2(reg2_data)
);

initial begin
    #0 begin
    clk <= 1'b0;
    rst <= `RstDisable;
	reg1_read_enable <= 1'b0;
	reg2_read_enable <= 1'b0;
	write_enable <= 1'b0;    

	wdata <= 24'b0;
	reg1_addr <= 4'b0;
	reg2_addr <= 4'b0;
	end

	#20
	//test case 1:
	write_enable <= 1'b1;
	#10
	waddr <= 4'h1;
	wdata <= 24'h124b36;
	#10
	waddr <= 4'h2;
	wdata <= 24'h655356;
	#10
	waddr <= 4'h3;
	wdata <= 24'h5a0024;
	#10
	waddr <= 4'h4;
	wdata <= 24'h5a0034;
	#20
	write_enable <= 1'b0;

	#10
	reg1_read_enable <= 1'b1;
	reg1_addr <= 4'h3;
	#10
	reg2_read_enable <= 1'b1;
	reg2_addr <= 4'h4;	
	
    #60 rst <= `RstEnable;
    #20 rst <= `RstDisable;
    
end


always #5 clk <= ~clk;

endmodule