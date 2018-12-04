module div(
    input wire clk,
    input wire rst,

    input wire [`DataBus] rs1,
    input wire [`DataBus] rs2,
    
    input wire signed_div_i;

    input wire write_enable,

    output reg [`ResultWidth] result,
);

always @ (posedge clk) begin
    
end


endmodule // div