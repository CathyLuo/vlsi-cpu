`include "candy_defines.v"

module candy_tb;

reg clk;
reg rst;

wire [`SRAMDataWidth] sram_data_io;
wire chip_enable_o;
wire write_enable_o;
wire read_enable_o;

candy candy0(
    .clk(clk),
    .rst(rst),
    .sram_data_io(sram_data_io),
    .chip_enable_o(chip_enable_o),
    .write_enable_o(write_enable_o),
    .read_enable_o(read_enable_o)
);

initial begin
    #0 begin
        clk <= 1'b0;
        rst <= `RstEnable;
    end
    #10 begin
        rst <= `RstDisable;
    end
end

always #5 clk <= ~clk;

endmodule // candy_tb