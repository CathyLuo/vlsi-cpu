`include "candy_defines.v"

module candy_if(
    input wire clk,
    input wire rst,
    input wire [`SRAMAddrWidth] pc,
    
    input wire if_enable,

    input wire data_ready,
    input wire [`SRAMDataWidth] sram_data,

    output reg [`SRAMDataWidth] inst,
    output reg [`SRAMAddrWidth] sram_addr,
    output reg sram_read_enable
);

always @ (posedge clk) begin
    if(rst == `RstEnable) begin
        sram_addr <= 17'b0;
        inst <= 24'b0;
        sram_read_enable <= `ReadDisable;
    end
    else begin
        if(if_enable == `LoadEnable) begin
            sram_read_enable <= `ReadEnable;
            sram_addr <= pc;
            if(data_ready == `ReadReady) begin
                inst <= sram_data;
            end
        end
        else begin
            sram_read_enable <= `ReadDisable;
        end
    end
end

endmodule // candy_if