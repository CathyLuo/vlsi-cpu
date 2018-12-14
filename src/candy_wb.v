module candy_wb(
    input wire clk,
    input wire rst,

    input wire wb_enable, 
    input wire [`SRAMDataWidth] result,
    input wire [`SRAMAddrWidth] result_addr,

    output wire write_enable,
    output wire [`SRAMDataWidth] wdata,
    output wire [`SRAMDataWidth] waddr,
);

always @ (posedge clk) begin
    if(wb_enable == `write_enable) begin
        wdata <= result;
        waddr <= result_addr;
    end
end

endmodule