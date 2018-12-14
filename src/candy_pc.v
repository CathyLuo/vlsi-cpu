`include "defines.v"

module candy_pc(
    input wire clk,
    input wire rst,

    input wire pc_enable,
    output reg [`SRAMAddrWidth] pc,
);

always @(posedge clk) begin
    if(rst == `RstEnable) begin
        pc <= `ZeroWord;
    end
    else if(pc_enable) begin
        pc <= pc + 1'b1;
    end
end

endmodule // candy_pc