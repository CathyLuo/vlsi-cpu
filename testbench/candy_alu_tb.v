`include "candy_defines.v"

module candy_alu_tb;

reg clk;
reg rst;

reg [`AluOpBus] aluop_i;
reg [`RegBus] reg1_i;
reg [`RegBus] reg2_i;

wire [`RegBus] res_o;


candy_alu alu(
    .clk(clk),
    .rst(rst),
    .aluop_i(aluop_i),
    .reg1_i(reg1_i),
    .reg2_i(reg2_i),
    .res_o(res_o)
);


initial begin
    #0 begin
        clk <= 1'b0;
        rst <= `RstEnable;
    end
    #25 begin
        rst <= `RstDisable;
        aluop_i <= `EXE_MUL;
        reg1_i <= 24'd113;
        reg2_i <= 24'd32345;
    end
end

always #5 clk <= ~clk;

endmodule // candy_alu_tb