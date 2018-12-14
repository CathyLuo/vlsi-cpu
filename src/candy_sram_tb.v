`include "candy_defines.v"

module candy_sram_tb;

reg clk;
reg rst;

reg write_enable;
reg [`SRAMAddrWidth] waddr;
reg [`SRAMDataWidth] wdata;

reg read_enable;
reg [`SRAMAddrWidth] raddr;

wire [`SRAMDataWidth] rdata;
wire rdata_ready;


candy_sram sram(
    .clk(clk),
    .rst(rst),
    .write_enable(write_enable),
    .waddr(waddr),
    .wdata(wdata),
    .read_enable(read_enable),
    .raddr(raddr),
    .rdata(rdata),
    .rdata_ready(rdata_ready)
);


initial begin

    #0 begin
        clk <= 1'b0;
        rst <= `RstEnable;
    end
    #10 begin
        rst <= `RstDisable;
        read_enable <= 1'b1;
        write_enable <= 1'b0;
        raddr <= 17'b0;
    end
    #10 begin
        raddr <= {16'b0 + 1'b1};
    end
    #10 begin
        raddr <= {15'b0 + 2'b10};
    end
    #10 begin
        read_enable <= 1'b0;
        write_enable <= 1'b1;
        waddr <= 17'b0;
        wdata <= 24'h1234;  
    end
    #10 begin
        read_enable <= 1'b1;
        write_enable <= 1'b0;
        raddr <= 17'b0;
    end
end


always #5 clk <= ~clk;

endmodule // candy_sram_tb
