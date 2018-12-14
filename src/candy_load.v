`include "candy_defines.v"

module candy_load(
    input wire clk,
    input wire rst,

    input wire load_enable,
    input wire [`RegAddrBus] rd,
    input wire [`ImmWidth] imm,

    output reg [`RegAddrBus] reg_waddr,
    output reg [`RegBus] reg_wdata
);

always @ (posedge clk) begin
    reg_waddr <= rd;
    reg_wdata <= imm;
end
endmodule // candy_load