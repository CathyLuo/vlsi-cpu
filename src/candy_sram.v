`include "candy_defines.v"

module candy_sram(
    input wire clk,
    input wire rst,

    input wire write_enable_i,
    input wire [`SRAMAddrWidth] sram_waddr_i,
    input wire [`SRAMDataWidth] sram_wdata_i,

    input wire read_enable_i,
    input wire [`SRAMAddrWidth] sram_raddr_i,
    output reg [`SRAMDataWidth] sram_rdata_i,

    output reg write_enable_o,
    output reg read_enable_o,
    inout [`SRAMDataWidth] sram_data_io,
    output reg chip_enable_o
);

assign sram_data_io = (!read_enable_i && write_enable_i) ? sram_waddr_i : 24'bz;

always @(posedge clk) begin
    if(read_enable_i ^ write_enable_i) begin
        if(read_enable_i) begin
            chip_enable_o <= 1'b0;
            read_enable_o <= 1'b0;
            write_enable_o <= 1'b1;
            sram_rdata_i <= sram_data_io;
        end
        if(write_enable_i) begin
            chip_enable_o <= 1'b0;
            write_enable_o <= 1'b0;
            read_enable_o <= 1'b1;
        end
    end
    else
        chip_enable_o <= 1'b1;
        write_enable_o <= 1'b1;
        read_enable_o <= 1'b1;
    end
endmodule
