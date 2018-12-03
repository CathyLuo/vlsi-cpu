`include "defines.v"

module candy_alu(
    input wire rst,

    input wire [`AluOpBus] aluop_i,
    input wire [`RegBus] reg1_i,
    input wire [`RegBus] reg2_i,
    input wire [`RegAddBus] wd_i,

    input wire [`RegBus] div_result_i,
    input wire div_ready_i,
    

    output reg [`RegAddBus] wd_o,
    output reg [`RegBus] wdata_o,


);

reg[`RegBus] logicout;
reg[`RegBus] shiftres;
reg[`RegBus] arithmeticres;
reg[`DoubleRegBus] mul_res;


always @ (*) begin
    if (rst == `RstEnable) begin
        logicout <= `ZeroWord;
    end
    else begin
        case (aluop_i)
            `EXE_AND:   begin
                logicout <= reg1_i & reg2_i;
            end
            `EXE_OR:    begin
                logicout <= reg1_i | reg2_i;
            end
            `EXE_XOR:   begin
                logicout <= reg1_i ^ reg2_i;
            end
            `EXE_NOR:   begin
                logicout <= ~(reg1_i | reg2_i);
            end
            default:   begin
                logicout <= `ZeroWord;
            end
        endcase
    end
end

always @ (*) begin
    if (rst == `RstEnable) begin
        shiftres <= `ZeroWord;
    end
    else begin
        case (aluop_i)
            `EXE_SLL:   begin
                shiftres <= reg1_i << reg2_i;
            end
            `EXE_SRA:   begin
                //shiftres <= (reg1_i >> reg2_i) | {24{reg1_i[23]}} << (6'd24-{1'b0, reg2_i[4:0]});
                shiftres <= reg1_i >>> reg2_i ;
            end
            `EXE_SRL:   begin
                shiftres <= reg1_i >> reg2_i;
            end
            default:    begin
                shiftres <= `ZeroWord;
            end
        endcase
    end
end

always @ (*) begin
    if(rst == `RstEnable) begin
    
    end
    else begin
    end
end
endmodule // candy_alu