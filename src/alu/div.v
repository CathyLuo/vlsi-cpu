`include "defines.v"

module div(
	input wire clk,
	input wire rst,

	input wire signed_div_i,
	input wire[23:0] opdata1_i,
	input wire[23:0] opdata2_i,
	input wire 	start_i,
	input wire	annul_i,
	
	output reg[47:0] result_o,
	output reg ready_o
);

	wire[23:0] div_temp;
	reg[5:0] cnt;
	reg[48:0] dividend;
	reg[1:0] state;
	reg[23:0] divisor;
	reg[23:0] temp_op1;
	reg[23:0] temp_op2;

	assign div_temp = {1'b0,dividend[47:24]} - {1'b0,divisor};

	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			state <= `DivFree;
			ready_o <= `DivResultNotReady;
			result_o <= {`ZeroWord,`ZeroWord};
            dividend <= 49'b0;
		end else begin
			case (state)
				`DivFree: begin
					if(start_i == `DivStart && annul_i == 1'b0) begin
						if(opdata2_i == `ZeroWord) begin
							state <= `DivByZero;
						end else begin
							state <= `DivOn;
							cnt <= 6'b000000;
							if(signed_div_i == 1'b1 && opdata1_i[23] == 1'b1 ) begin
								temp_op1 = ~opdata1_i + 1;
							end else begin
								temp_op1 = opdata1_i;
							end
							if(signed_div_i == 1'b1 && opdata2_i[23] == 1'b1 ) begin
								temp_op2 = ~opdata2_i + 1;
							end else begin
								temp_op2 = opdata2_i;
							end
							dividend <= {`ZeroWord,`ZeroWord};
							dividend[24:1] <= temp_op1;
							divisor <= temp_op2;
						end
					end else begin
						ready_o <= `DivResultNotReady;
						result_o <= {`ZeroWord,`ZeroWord};
					end
				end

				`DivByZero:		begin
					dividend <= {`ZeroWord,`ZeroWord};
					state <= `DivEnd;
				end
				
				`DivOn: begin
					if(annul_i == 1'b0) begin
						if(cnt != 6'b100000) begin
							if(div_temp[24] == 1'b1) begin
								dividend <= {dividend[47:0] , 1'b0};
							end else begin
								dividend <= {div_temp[23:0] , dividend[23:0] , 1'b1};
							end
							cnt <= cnt + 1'b1;
						end else begin
							if((signed_div_i == 1'b1) && ((opdata1_i[23] ^ opdata2_i[23]) == 1'b1)) begin
								dividend[23:0] <= (~dividend[23:0] + 1);
							end
							if((signed_div_i == 1'b1) && ((opdata1_i[23] ^ dividend[23]) == 1'b1)) begin
								dividend[48:25] <= (~dividend[48:25] + 1);
							end
							state <= `DivEnd;
							cnt <= 6'b000000;
						end
					end else begin
						state <= `DivFree;
					end	
				end

				`DivEnd: begin
					result_o <= {dividend[48:25], dividend[23:0]};
					ready_o <= `DivResultReady;
					if(start_i == `DivStop) begin
						state <= `DivFree;
						ready_o <= `DivResultNotReady;
						result_o <= {`ZeroWord,`ZeroWord};
					end
				end
			endcase
		end
	end
endmodule