`include "candy_defines.v"

module candy_sram(
    input wire clk, 
	input wire rst,

	input wire write_enable,
	input wire [`SRAMAddrWidth] waddr,
	input wire [`SRAMDataWidth] wdata,

	input wire read_enable,
	input wire [`SRAMAddrWidth] raddr,
	output wire [`SRAMDataWidth] rdata,
    output wire rdata_ready
);

reg [`SRAMDataWidth] SRAM [`SRAMAddrWidth];

initial $readmemh ("sram.data", SRAM);

always @ (posedge clk) begin
	if (read_enable && !write_enable) begin
		rdata <= SRAM[raddr];
        rdata_ready <= `ReadReady;
	end
    if(rdata_ready == `ReadReady) begin
        rdata_ready <= `ReadNotReady;
    end
end

always @ (posedge clk) begin
	if(write_enable && read_enable) begin
		SRAM[waddr] <= wdata;
	end
end

endmodule 