`include "candy_defines.v"

module candy_id_tb;

reg clk;
reg rst;
reg [`RegBus] inst;
reg id_enable;

wire [`ROP] op;
wire [`RegAddrBus] rs1;
wire [`RegAddrBus] rs2;
wire [`RegAddrBus] rd;

wire [`ImmWidth] imm_data;
wire re1;
wire re2;



candy_id ld0(
    .clk(clk),
    .rst(rst),
    .inst(inst),
    .id_enable(id_enable),
    .op(op),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .imm_data(imm_data),
    .re1(re1),
    .re2(re2)
);


initial begin
    #0 begin
        clk <= 1'b0;
        rst <= `RstEnable;
        id_enable <= 1'b0;
    end
    #10 begin
        rst <= `RstDisable;
    end
    #25 begin
        id_enable <= 1'b1;
        // R Type
        inst <= 24'h027890;
    end
    #25 begin
        // I Type
        inst <= 24'h478900;
    end
    #25 begin
        // S Type
        inst <= 24'h878900;
    end
    #25 begin
        // U Type
        inst <= 24'hc78900;
    end
end

always #5 clk <= ~clk;

endmodule // candy_load_tb
