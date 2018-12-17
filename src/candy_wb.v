`include "candy_defines.v"

module candy_wb(
    input wire clk,
    input wire rst,

    input wire is_mem,

    input wire wb_enable,
    input wire [`SRAMDataWidth] result,
    input wire [`SRAMAddrWidth] sram_result_addr,
    input wire [`RegAddrBus] reg_addr,

    output reg sram_write_enable,
    output reg [`SRAMDataWidth] sram_wdata,
    output reg [`SRAMAddrWidth] sram_waddr,

    output reg reg_write_enable,
    output reg [`RegAddrBus] reg_waddr,
    output reg [`RegBus] reg_wdata
);

always @ (posedge clk) begin
    if(wb_enable == `WriteEnable) begin
        if(is_mem) begin
            sram_wdata <= result;
            sram_waddr <= sram_result_addr;
        end
        else begin
            reg_waddr <= reg_addr;
            reg_wdata <= result;
            reg_write_enable <= `WriteEnable;
        end
    end
end

endmodule
