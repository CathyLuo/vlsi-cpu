`include "defines.v"

module candy_alu(
    input wire rst,

    input wire [`AluOpBus] aluop_i,
    input wire [`RegBus] reg1_i,
    input wire [`RegBus] reg2_i,
    input wire [`RegAddBus] wd_i,

    input wire [`RegBus] div_result_i,
    input wire div_ready_i,
    
    output reg [`RegBus] wdata_o,

    output reg [`RegBus] div_opdata1_o;
    output reg [`RegBus] div_opdata2_o;
    output reg div_start_o;
    output reg signed_div_o;

    output reg stallreq_for_div;
);

wire [`RegBus] op1;
wire [`RegBus] op2;
wire [48:0] mul_result;

wire [`RegBus] add_op1;
wire [`RegBus] add_op2;
wire [24:0] sum_result;

assign mul_op1 = reg1_i;
assign mul_op2 = reg2_i;

assign add_op1 = reg1_i;
assign add_op2 = reg2_i;

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
        case (aluop_i)
            `EXE_AND:   begin
                wdata_o <= reg1_i & reg2_i;
            end
            `EXE_OR:    begin
                wdata_o <= reg1_i | reg2_i;
            end
            `EXE_XOR:   begin
                wdata_o <= reg1_i ^ reg2_i;
            end
            `EXE_NOR:   begin
                wdata_o <= ~(reg1_i | reg2_i);
            end
            default:   begin
                wdata_o <= `ZeroWord;
            end
        endcase
    end
end

always @ (*) begin
    if (rst == `RstEnable) begin
        wdata_o <= `ZeroWord;
    end
    else begin
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
            default:    begin
                wdata_o <= `ZeroWord;
            end
        endcase
    end
end

always @ (*) begin
    if(rst == `RstEnable) begin
        wdata_o <= `ZeroWord;
    end
    else begin
        case (aluop_i)
            `EXE_AND: begin
                wdata_o <= sum_result[23:0];
            end
            `EXE_SUB: begin
                reg2_i <= ~reg2_i + 1'b1;
                wdata_o <= sum_result[23:0];
            end
            `EXE_MUL: begin
                wdata_o <= mul_result[23:0];
            end
        endcase
    end
end

always @ (*) begin
	if(rst == `RstEnable) begin
	    stallreq_for_div <= `NoStop;
		div_opdata1_o <= `ZeroWord;
		div_opdata2_o <= `ZeroWord;
		div_start_o <= `DivStop;
		signed_div_o <= 1'b0;
	end else begin
		stallreq_for_div <= `NoStop;
		div_opdata1_o <= `ZeroWord;
		div_opdata2_o <= `ZeroWord;
		div_start_o <= `DivStop;
		signed_div_o <= 1'b0;
		case (aluop_i) 
			`EXE_DIV:		begin
				if(div_ready_i == `DivResultNotReady) begin
					div_opdata1_o <= reg1_i;
					div_opdata2_o <= reg2_i;
					div_start_o <= `DivStart;
					signed_div_o <= 1'b1;
					stallreq_for_div <= `Stop;
				end else if(div_ready_i == `DivResultReady) begin
					div_opdata1_o <= reg1_i;
					div_opdata2_o <= reg2_i;
					div_start_o <= `DivStop;
					signed_div_o <= 1'b1;
					stallreq_for_div <= `NoStop;
				end else begin
					div_opdata1_o <= `ZeroWord;
					div_opdata2_o <= `ZeroWord;
					div_start_o <= `DivStop;
					signed_div_o <= 1'b0;
					stallreq_for_div <= `NoStop;
				end
			end
			`EXE_DIVU:		begin
				if(div_ready_i == `DivResultNotReady) begin
					div_opdata1_o <= reg1_i;
					div_opdata2_o <= reg2_i;
					div_start_o <= `DivStart;
					signed_div_o <= 1'b0;
					stallreq_for_div <= `Stop;
				end else if(div_ready_i == `DivResultReady) begin
					div_opdata1_o <= reg1_i;
					div_opdata2_o <= reg2_i;
					div_start_o <= `DivStop;
					signed_div_o <= 1'b0;
					stallreq_for_div <= `NoStop;
				end else begin
					div_opdata1_o <= `ZeroWord;
					div_opdata2_o <= `ZeroWord;
					div_start_o <= `DivStop;
					signed_div_o <= 1'b0;
					stallreq_for_div <= `NoStop;
				end
			end
			default: begin
			end
		endcase
	end
end


endmodule // candy_alu