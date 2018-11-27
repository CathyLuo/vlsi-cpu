`timescale 1ns/1ps

`include "candy_regs.v"
`include "defines.v"


module candy_regs_tb;

wire clk;
wire rst;

wire reg1_read_enable;
wire reg2_read_enable;

wire [`RegBus] reg1_data;
wire [`RegBus] reg2_data;
wire [`RegAddrBus] reg1_addr;
wire [`RegAddrBus] reg2_addr;

wire write_enable;
wire waddr;
wire wdata;


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
    end

    #600 $finish;
end


always #10 begin
    clk <= ~clk;
end

endmodule