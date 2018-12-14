`include "candy_defines.v"

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
wire [`RegAddrBus]reg_waddr;
wire [`RegBus]reg_wdata;

//alu
wire [`AluOpBus] aluop_i;
wire [`RegBus] reg1_i;
wire [`RegBus] reg2_i;
wire [`RegBus] res_o;

// sram
wire [`SRAMAddrWidth] sram_raddr;
wire [`SRAMAddrWidth] sram_waddr;
reg [`SRAMDataWidth] sram_rdata;
reg [`SRAMDataWidth] sram_wdata;
wire sram_write_enable;
wire sram_read_enable;
reg sram_read_ready;

//pc
reg [`SRAMAddrWidth] pc;
reg pc_enable;

//if
reg [`SRAMDataWidth] inst;
reg if_enable;

//id
reg [`ROP] op;
reg [`ImmWidth] imm_data;
reg id_enable;

//load
reg load_enable;

//wb
reg wb_enable;
reg [`SRAMAddrWidth] wb_addr; 

candy_regs regfile(
	.clk(clk),
	.rst(rst),
	.we(write_enable),
	.waddr(reg_waddr),
	.wdata(reg_wdata),
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
	.reg1_i(reg1_data),
	.reg2_i(reg2_data),
	.res_o(res_o)
);

candy_sram sram(
	.clk(clk),
	.rst(rst),
	.write_enable(write_enable),
	.waddr(waddr),
	.wdata(sram_wdata),
	.read_enable(read_enable),
	.raddr(raddr),
	.rdata(rdata),
	.rdata_ready(rdata_ready)
);

candy_pc pc0(
	.clk(clk),
	.rst(rst),
	.pc_enable(pc_enable),
	.pc(pc)
);

candy_if if0(
	.clk(clk),
	.rst(rst),
	.pc(pc),
	.if_enable(if_enable),
	.data_ready(rdata_ready),
	.sram_data(rdata),
	.inst(inst),
	.sram_addr(raddr),
	.sram_read_enable(read_enable)
);

candy_id id(
	.clk(clk),
	.rst(rst),
	.inst(inst),
	.op(op),
	.rs1(reg1_addr),
	.rs2(reg2_addr),
	.rd(reg_waddr),
	.imm_data(imm_data)
);

candy_load load(
	.clk(clk),
	.rst(rs1),
	.load_enable(load_enable),
	.rd(imm_data),
	.reg_waddr(reg_waddr),
	.reg_wdata(reg_wdata)
);

candy_wb wb(
	.clk(clk),
	.rst(rst),
	.wb_enable(wb_enable),
	.result(res_o),
	.write_enable(sram_write_enable),
	.wdata(sram_wdata),
	.waddr(sram_waddr)
);


endmodule


