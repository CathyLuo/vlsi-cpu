`include "candy_defines.v"

module candy_pc_tb;

reg clk;
reg rst;
reg pc_en;

wire [`SRAMAddrWidth] pc;


candy_pc pc0(
    .clk(clk),
    .rst(rst),
    .pc_enable(pc_en),
    .pc(pc)
);


initial begin
    #0 begin
        clk <= 1'b0;
        rst <= `RstEnable;
        pc_en <= 1'b1;
    end
    #25 begin
        rst <= `RstDisable;
    end

end

always #5 clk <= ~clk;

endmodule // candy_pc_tb
