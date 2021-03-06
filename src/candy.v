`include "candy_defines.v"

module candy (input wire clk,
			input wire rst,

	inout [`SRAMDataWidth] sram_data_io,
	output chip_enable_o,
	output write_enable_o,
    output read_enable_o
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
wire [`RegBus] reg1_i;
wire [`RegBus] reg2_i;
wire [`RegBus] res_o;

// sram
wire sram_write_enable;
wire sram_read_enable;
wire [`SRAMAddrWidth] sram_waddr_i;
wire [`SRAMDataWidth] sram_wdata_i;
wire [`SRAMAddrWidth] sram_raddr_i;
wire [`SRAMDataWidth] sram_rdata_i;

//pc
wire [`SRAMAddrWidth] pc;
reg pc_enable;

//if
wire [`SRAMDataWidth] inst;
reg if_enable;
wire is_mem;

//id
wire [`ROP] op;
wire [`ImmWidth] imm_data;
reg id_enable;
wire [`RegAddrBus] rd;

//load
reg load_enable;

//wb
reg wb_enable;
reg [`SRAMAddrWidth] wb_addr; 

reg [2:0] state;

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
	.aluop_i(op),
	.reg1_i(reg1_data),
	.reg2_i(reg2_data),
	.res_o(res_o)
);

candy_sram sram(
	.clk(clk),
	.rst(rst),
	.write_enable_i(sram_write_enable),
	.sram_waddr_i(sram_waddr_i),
	.sram_wdata_i(sram_wdata_i),
	.read_enable_i(sram_read_enable),
	.sram_raddr_i(sram_raddr_i),
	.sram_rdata_i(sram_rdata_i),
	.write_enable_o(write_enable_o),
	.read_enable_o(read_enable_o),
	.sram_data_io(sram_data_io),
	.chip_enable_o(chip_enable_o)
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
	.sram_data(sram_rdata_i),
	.inst(inst),
	.sram_addr(sram_raddr_i),
	.sram_read_enable(read_enable),
	.is_mem(is_mem)
);

candy_id id(
	.clk(clk),
	.rst(rst),
	.inst(inst),
	.op(op),
	.id_enable(id_enable),
	.rs1(reg1_addr),
	.rs2(reg2_addr),
	.rd(rd),
	.imm_data(imm_data),
	.re1(reg1_read_enable),
    .re2(reg2_read_enable)
);

candy_load load(
	.clk(clk),
	.rst(rst),
	.load_enable(load_enable),
	.rd(rd),
	.imm(imm_data),
	.reg_waddr(reg_waddr),
	.reg_wdata(reg_wdata)
);

candy_wb wb(
	.clk(clk),
	.rst(rst),
	.wb_enable(wb_enable),
	.is_mem(is_mem),
	.result(res_o),
	.reg_write_enable(write_enable),
	.reg_addr(rd),
	.sram_write_enable(sram_write_enable),
	.sram_result_addr(sram_waddr_i),
	.sram_waddr(sram_waddr_i),
	.sram_wdata(sram_wdata_i),
	.reg_waddr(reg_waddr),
	.reg_wdata(reg_wdata)
);

always @ (posedge clk) begin
	if (rst == `RstEnable) begin
		state <= 2'b0;
		pc_enable <= 1'b1;
	end
	else begin
		case (state)
			2'b00:  begin
				wb_enable <= 1'b0;
				pc_enable <= 1'b0;
				if_enable <= 1'b1;
				state <= 2'b01;
			end
			2'b01: begin
				if_enable <= 1'b0;
				id_enable <= 1'b1;
				state <= 2'b10;
			end
			2'b10: begin
				load_enable <= 1'b1;
				id_enable <= 1'b0;
				state <= 2'b11;
			end
			2'b11: begin
				wb_enable <= 1'b1;
				load_enable <= 1'b0;
				state <= 2'b00;
				pc_enable <= 1'b1;
			end
		endcase
	end
end

endmodule



