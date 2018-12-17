`include "candy_defines.v"

module candy_wb_tb;

reg clk;
reg rst;

reg is_mem;

reg wb_enable;
reg [`SRAMDataWidth] result;
reg [`SRAMAddrWidth] sram_result_addr;
reg [`RegAddrBus] reg_addr;

wire sram_write_enable;
wire [`SRAMDataWidth] sram_wdata;
wire [`SRAMAddrWidth] sram_waddr;

wire reg_write_enable;
wire [`RegAddrBus] reg_waddr;
wire [`RegBus] reg_wdata;



candy_wb wb(
    .clk(clk),
    .rst(rst),

    .is_mem(is_mem),
    .wb_enable(wb_enable),
    .result(result),
    .sram_result_addr(sram_result_addr),
    .reg_addr(reg_addr),


    .sram_write_enable(sram_write_enable),
    .sram_wdata(sram_wdata),
    .sram_waddr(sram_waddr),

    .reg_write_enable(reg_write_enable),
    .reg_waddr(reg_waddr),
    .reg_wdata(reg_wdata)
);


initial begin
    #0 begin
        clk <= 1'b0;
        rst <= `RstEnable;
        wb_enable <= 1'b0;
    end
    #10 begin
        rst <= `RstDisable;
        wb_enable <= 1'b1;
    end
    #25 begin
        is_mem <= 1'b1;
        result <= 24'h37c549;
        sram_result_addr <= 17'd11;
    end
    #25 begin
        is_mem <= 1'b0;
        result <= 24'h37c549;
        reg_addr <= 4'h4;
    end
end

always #5 clk <= ~clk;

endmodule // candy_wb_tb
