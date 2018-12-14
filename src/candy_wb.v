`include "candy_defines.v"

module candy_wb(
    input wire clk,
    input wire rst,

    input wire wb_enable, 
    input wire [`SRAMDataWidth] result,
    input wire [`SRAMAddrWidth] result_addr,

    output wire write_enable,
    output reg [`SRAMDataWidth] wdata,
    output reg [`SRAMDataWidth] waddr
);

always @ (posedge clk) begin
    if(wb_enable == `WriteEnable) begin
        wdata <= result;
        waddr <= result_addr;
    end
end

endmodule