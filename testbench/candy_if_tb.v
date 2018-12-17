`include "candy_defines.v"

module candy_if_tb;

reg clk;
reg rst;
reg [`SRAMAddrWidth] pc;

reg if_enable;

reg data_ready;
reg [`SRAMDataWidth] sram_data;

wire [`SRAMDataWidth] inst;
wire [`SRAMAddrWidth] sram_addr;
wire sram_read_enable;
wire is_mem;



candy_if ifetch(
    .clk(clk),
    .rst(rst),

    .pc(pc),
    .if_enable(if_enable),

    .data_ready(data_ready),
    .sram_data(sram_data),

    .inst(inst),
    .sram_addr(sram_addr),
    .sram_read_enable(sram_read_enable),
    .is_mem(is_mem)
);


initial begin
    #0 begin
        clk <= 1'b0;
        rst <= `RstEnable;
        if_enable <= 1'b0;
    end
    #10 begin
        rst <= `RstDisable;
    end
    #25 begin
        if_enable <= 1'b1;
        // Start memory request
        pc <= 17'h012;
        if_enable <= 1'b1;
    end
    #10 begin
        // Data from SRAM is ready now
        data_ready <= 1'b1;
        sram_data <= 24'h027890;
    end
end

always #5 clk <= ~clk;

endmodule // candy_if_tb
