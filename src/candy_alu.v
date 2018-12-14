`include "candy_defines.v"

module candy_alu(
    input wire clk,
    input wire rst,

    input wire [`AluOpBus] aluop_i,
    input wire [`RegBus] reg1_i,
    input wire [`RegBus] reg2_i,
  
    output reg [`RegBus] res_o
);

wire [`RegBus] mul_op1;
wire [`RegBus] mul_op2;
wire [48:0] mul_result;

reg [`RegBus] add_op1;
reg [`RegBus] add_op2;
wire [24:0] sum_result;

assign mul_op1 = reg1_i;
assign mul_op2 = reg2_i;

reg [23:0] wdata_o;

walltree_mul wm(
    .op1(mul_op1),
    .op2(mul_op2),
    .result(mul_result)
);

csa24 csa0O(
    .op1(add_op1),
    .op2(add_op2),
    .result(sum_result)
);

always @ (*) begin
    if (rst == `RstEnable) begin
        wdata_o <= `ZeroWord;
    end
    else begin
        $display("1 %b", aluop_i);
        case (aluop_i)
            `EXE_NOT:   begin
                wdata_o <= ~(reg1_i);
            end
            `EXE_NEG:   begin
                wdata_o <= ~(reg1_i) + 1;
            end
            `EXE_AND:   begin
                $display("1 code %b", `EXE_AND);
                wdata_o <= (reg1_i & reg2_i);
            end
            `EXE_OR:    begin
                wdata_o <= (reg1_i | reg2_i);
            end
            `EXE_XOR:   begin
                wdata_o <= (reg1_i ^ reg2_i);
            end
        endcase
    end
end

always @ (*) begin
    if (rst == `RstEnable) begin
        wdata_o <= `ZeroWord;
    end
    else begin
        $display("2 %b", aluop_i);
        case (aluop_i) 
            `EXE_SLL:   begin
                wdata_o <= reg1_i << reg2_i;
            end
            `EXE_SRA:   begin
                //shiftres <= (reg1_i >> reg2_i) | {24{reg1_i[23]}} << (6'd24-{1'b0, reg2_i[4:0]});
                wdata_o <= reg1_i >>> reg2_i ;
            end
            `EXE_SRL:   begin
                wdata_o <= reg1_i >> reg2_i;
            end
        endcase
    end
end

always @ (*) begin
    if(rst == `RstEnable) begin
        wdata_o <= `ZeroWord;
    end
    else begin
        $display("3 %b", aluop_i);
        
        case (aluop_i)        
            `EXE_ADD: begin
                add_op1 <= reg1_i;
                add_op2 <= reg2_i;
                wdata_o <= sum_result[23:0];
            end
            `EXE_SUB: begin
                add_op1 <= reg1_i;
                add_op2 <= ~reg2_i + 1;
                wdata_o <= sum_result[23:0];
            end
            `EXE_MUL: begin
                wdata_o <= mul_result[23:0];
            end
        endcase
    end
end

always @ (posedge clk) begin
    res_o <= wdata_o;
end


endmodule // candy_alu


