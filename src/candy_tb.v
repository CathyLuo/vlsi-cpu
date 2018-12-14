`include "candy_defines.v"

module candy_tb;

reg clk;
reg rst;

reg [`SRAMDataWidth] sram_rdata;
wire [`SRAMAddrWidth] sram_raddr;
wire [`SRAMAddrWidth] sram_waddr;
wire [`SRAMDataWidth] sram_wdata;

candy candy0(
    .clk(clk),
    .rst(rst),
    .sram_raddr(sram_raddr),
    .sram_rdata(sram_rdata),
    .sram_waddr(sram_waddr),
    .sram_wdata(sram_wdata)
);

initial begin
    #0 begin
        clk <= 1'b0;
        rst <= `RstEnable;
    end
    #10 begin
        rst <= `RstDisable;
    end
end

always #5 clk <= ~clk;

endmodule // candy_tb