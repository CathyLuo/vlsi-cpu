`include "defines.v"

module candy (input wire clk,
			input wire rst

);

wire reg1_read_enable;
wire reg2_read_enable;

wire [`RegBus] reg1_data;
wire [`RegBus] reg2_data;
wire [`RegAddrBus] reg1_addr;
wire [`RegAddrBus] reg2_addr;

wire write_enable;
wire [`RegAddrBus]waddr;
wire [`RegBus]wdata;

//alu
wire [`AluOpBus] aluop_i;
wire [`RegBus] reg1_i;
wire [`RegBus] reg2_i;
wire [`RegBus] res_o;

//div
reg signed_div_i;
reg[23:0] opdata1_i;
reg[23:0] opdata2_i;
reg start_i;
reg annul_i;

wire [23:0]	quotient_o;
wire [23:0]	remainder_o;
wire ready_o;


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

candy_alu alu(
	.clk(clk),
	.rst(rst),
	.aluop_i(aluop_i),
	.reg1_i(reg1_i),
	.reg2_i(reg2_i),
	.res_o(res_o)
);
   
div div0(
	.clk(clk),
    .rst(rst),
    .signed_div_i(signed_div_i),
    .opdata1_i(opdata1_i),
    .opdata2_i(opdata2_i),
    .start_i(start_i),
    .annul_i(annul_i),
    .remainder_o(remainder_o),
    .quotient_o(quotient_o),
    .ready_o(ready_o));

endmodule


