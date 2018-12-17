`include "candy_defines.v"

module candy_load_tb;

reg clk;
reg rst;
reg ld_en;

reg  [`RegAddrBus] rd;
reg [`ImmWidth] imm;

wire [`RegAddrBus] reg_waddr;
wire [`RegBus] reg_wdata;

candy_load ld(
    .clk(clk),
    .rst(rst),
    .load_enable(ld_en),
    .rd(rd),
    .imm(imm),
    .reg_waddr(reg_waddr),
    .reg_wdata(reg_wdata)
);


initial begin
    #0 begin
        clk <= 1'b0;
        rst <= `RstEnable;
        ld_en <= 1'b1;
    end
    #25 begin
        rst <= `RstDisable;
        rd <= 4'd9;
        imm <= 16'd113;
    end
    #25 begin
        rd <= 4'd10;
        imm <= 16'd32345;
    end
end

always #5 clk <= ~clk;

endmodule // candy_load_tb
