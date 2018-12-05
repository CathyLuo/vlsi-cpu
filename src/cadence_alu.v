`define RstEnable 1'b1
`define RstDisable 1'b0 

`define WriteEnable 1'b1
`define WriteDisable 1'b0
`define ReadEnable 1'b1
`define ReadDisable 1'b0

`define ZeroWord 24'b0

//candy: intruction format
`define R_typecode 00
`define I_typecode 01
`define S_typecode 10
`define SB_typecode 10
`define U_typecode 11
`define UJ_typecode 11

`define R_opcode 5:0
`define I_opcode 3:0
`define S_opcode 3:0
`define SB_opcode 3:0
`define U_opcode 1:0
`define UJ_opcode 1:0

`define EXE_ADD 6'b000000
`define EXE_ADDI 4'b0000
`define EXE_SUB 6'b000001

`define EXE_MUL 6'b000010
`define EXE_DIV 6'b000011
`define EXE_DIVU 6'b000100
`define EXE_REM 6'b000101
`define EXE_REMU 6'b000110

`define EXE_AND 6'b001000
`define EXE_ANDI 4'b0001
`define EXE_OR 6'b001001
`define EXE_ORI 4'b0010
`define EXE_XOR 6'b001010
`define EXE_XORI 4'b0011

`define EXE_SLL 6'b010000
`define EXE_SLLI 4'b0100
`define EXE_SRA 6'b010001
`define EXE_SRAI 4'b0101
`define EXE_SRL 6'b010010
`define EXE_SRLI 4'b0110

//NEG
`define EXE_NEG 6'b100000
`define EXE_NOT 6'b110000

//candy: register file
`define RegAddrBus 3:0
`define RegBus 23:0
`define DoubleRegBus 47:0
`define RegWidth 24
`define RegNum 16

//candy: ALU

`define AluOpBus 5:0


//candy: error code
`define Overflow 00
`define Dividebyzero 01

//div
`define ResultWidth 47:0
//`define Dividebyzero 01
`define singed_div 1'b1
`define unsigned_div 1'b0

//div
`define DivFree 			2'b00
`define DivByZero 			2'b01
`define DivOn 				2'b10
`define DivEnd 				2'b11
`define DivResultReady 		1'b1
`define DivResultNotReady 	1'b0
`define DivStart 			1'b1
`define DivStop 			1'b0

module candy_alu(
    input clk,
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


module div(

	input	wire			clk,
	input wire				rst,

	input wire				signed_div_i,
	input wire[23:0]		opdata1_i,
	input wire[23:0]		opdata2_i,
	input wire 				start_i,
	input wire				annul_i,
	
	output reg[23:0]		quotient_o,
	output reg[23:0]		remainder_o,
	output reg				ready_o
);

	wire[24:0] div_temp;
	reg[4:0] cnt;
	reg[48:0] dividend;
	reg[1:0] state;
	reg[23:0] divisor;
	reg[23:0] temp_op1;
	reg[23:0] temp_op2;
	//reg[47:0] result_o;

	assign div_temp = {1'b0,dividend[47:24]} - {1'b0,divisor};

	always @ (posedge clk) begin
		if (rst == 1'b1) begin
			state <= `DivFree;
			ready_o <= `DivResultNotReady;
			remainder_o <= 24'b0;
			quotient_o <= 24'b0;
			//result_o <= {24'b0, 24'b0};
		end else begin
			case (state)
				`DivFree: begin
					if(start_i == `DivStart && annul_i == 1'b0) begin
						if(opdata2_i == 24'b0) begin
							state <= `DivByZero;
						end else begin
							state <= `DivOn;
							cnt <= 5'b00000;
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
						remainder_o <= 24'b0;
						quotient_o <= 24'b0;
						//result_o <= {`ZeroWord,`ZeroWord};

					end
				end

				`DivByZero:		begin
					dividend <= {`ZeroWord,`ZeroWord};
					state <= `DivEnd;
				end
				
				`DivOn: begin
					if(annul_i == 1'b0) begin
						if(cnt != 5'b11000) begin
							if(div_temp[23] == 1'b1) begin
								dividend <= {dividend[47:0] , 1'b0};
							end else begin
								dividend <= {div_temp[23:0] , dividend[23:0] , 1'b1};
							end
							cnt <= cnt + 1'b1;
						end else begin
							if((signed_div_i == 1'b1) && ((opdata1_i[23] ^ opdata2_i[23]) == 1'b1)) begin
								dividend[23:0] <= (~dividend[23:0] + 1);
							end
							if((signed_div_i == 1'b1) && ((opdata1_i[23] ^ dividend[48]) == 1'b1)) begin
								dividend[48:25] <= (~dividend[48:25] + 1);
							end
							state <= `DivEnd;
							cnt <= 5'b00000;
						end
					end else begin
						state <= `DivFree;
					end	
				end

				`DivEnd: begin
					remainder_o <= dividend[48:25];
					quotient_o <= dividend[23:0];
					//result_o <= {dividend[48:25], dividend[23:0]};
					ready_o <= `DivResultReady;
					if(start_i == `DivStop) begin
						state <= `DivFree;
						ready_o <= `DivResultNotReady;
						remainder_o <= 24'b0;
						quotient_o <= 24'b0;
						//result_o <= {`ZeroWord,`ZeroWord};
					end
				end
			endcase
		end
	end
endmodule

module 	csa24(
    input wire [23:0] op1,
    input wire [23:0] op2,
    output wire [24:0] result
);


wire [31:0] a;
wire [31:0] b;
wire [31:0] sum;
wire cout;

assign a = {{8{op1[23]}}, op1[23:0]};
assign b = {{8{op2[23]}}, op2[23:0]};

wire	[2 : 0]		p1, g1, c1_s0, c1_s1, c1;
wire 	[3 : 0]		p2, g2, c2_s0, c2_s1, c2;
wire 	[4 : 0]		p3, g3, c3_s0, c3_s1, c3;
wire 	[5 : 0]		p4, g4, c4_s0, c4_s1, c4;
wire 	[6 : 0]		p5, g5, c5_s0, c5_s1, c5;
wire 	[6 : 0]		p6, g6, c6_s0, c6_s1, c6;

assign	g1 = a[2:0] & b[2:0];
assign	p1 = a[2:0]	| b[2:0];
assign	c1_s0[0] = g1[0];
assign 	c1_s0[1] = g1[1] | (p1[1] & c1_s0[0]);
assign 	c1_s0[2] = g1[2] | (p1[2] & c1_s0[1]);
assign	c1_s1[0] = g1[0] | p1[0];
assign	c1_s1[1] = g1[1] | (p1[1] & c1_s1[0]);
assign	c1_s1[2] = g1[2] | (p1[2] & c1_s1[1]);
assign	c1 = 1'b0 ? c1_s1 : c1_s0;
assign	sum[2 : 0] = a[2:0] ^ b[2:0] ^ {c1[1:0], 1'b0};

assign	g2 = a[6 : 3] & b[6 : 3];
assign	p2 = a[6 : 3] | b[6 : 3];
assign	c2_s0[0] = g2[0];
assign 	c2_s0[1] = g2[1] | (p2[1] & c2_s0[0]);
assign 	c2_s0[2] = g2[2] | (p2[2] & c2_s0[1]);
assign	c2_s0[3] = g2[3] | (p2[3] & c2_s0[2]);
assign	c2_s1[0] = g2[0] | p2[0];
assign	c2_s1[1] = g2[1] | (p2[1] & c2_s1[0]);
assign	c2_s1[2] = g2[2] | (p2[2] & c2_s1[1]);
assign	c2_s1[3] = g2[3] | (p2[3] & c2_s1[2]);
assign	c2 = c1[2] ? c2_s1 : c2_s0;
assign	sum[6 : 3] = a[6 : 3] ^ b[6 : 3] ^ {c2[2:0], c1[2]};


assign	g3 = a[11 : 7] & b[11 : 7];
assign	p3 = a[11 : 7] | b[11 : 7];
assign	c3_s0[0] = g3[0];
assign 	c3_s0[1] = g3[1] | (p3[1] & c3_s0[0]);
assign 	c3_s0[2] = g3[2] | (p3[2] & c3_s0[1]);
assign	c3_s0[3] = g3[3] | (p3[3] & c3_s0[2]);
assign	c3_s0[4] = g3[4] | (p3[4] & c3_s0[3]);
assign	c3_s1[0] = g3[0] | p3[0];
assign	c3_s1[1] = g3[1] | (p3[1] & c3_s1[0]);
assign	c3_s1[2] = g3[2] | (p3[2] & c3_s1[1]);
assign	c3_s1[3] = g3[3] | (p3[3] & c3_s1[2]);
assign	c3_s1[4] = g3[4] | (p3[4] & c3_s1[3]);
assign	c3 = c2[3] ? c3_s1 : c3_s0;
assign	sum[11 : 7] = a[11 : 7] ^ b[11 : 7] ^ {c3[3:0], c2[3]};

assign	g4 = a[17 : 12] & b[17 : 12];
assign	p4 = a[17 : 12] | b[17 : 12];
assign	c4_s0[0] = g4[0];
assign 	c4_s0[1] = g4[1] | (p4[1] & c4_s0[0]);
assign 	c4_s0[2] = g4[2] | (p4[2] & c4_s0[1]);
assign	c4_s0[3] = g4[3] | (p4[3] & c4_s0[2]);
assign	c4_s0[4] = g4[4] | (p4[4] & c4_s0[3]);
assign	c4_s0[5] = g4[5] | (p4[5] & c4_s0[4]);
assign	c4_s1[0] = g4[0] | p4[0];
assign	c4_s1[1] = g4[1] | (p4[1] & c4_s1[0]);
assign	c4_s1[2] = g4[2] | (p4[2] & c4_s1[1]);
assign	c4_s1[3] = g4[3] | (p4[3] & c4_s1[2]);
assign	c4_s1[4] = g4[4] | (p4[4] & c4_s1[3]);
assign	c4_s1[5] = g4[5] | (p4[5] & c4_s1[4]);
assign	c4 = c3[4] ? c4_s1 : c4_s0;
assign	sum[17 : 12] = a[17 : 12] ^ b[17 : 12] ^ {c4[4:0], c3[4]};

assign	g5 = a[24 : 18] & b[24 : 18];
assign	p5 = a[24 : 18] | b[24 : 18];
assign	c5_s0[0] = g5[0];
assign 	c5_s0[1] = g5[1] | (p5[1] & c5_s0[0]);
assign 	c5_s0[2] = g5[2] | (p5[2] & c5_s0[1]);
assign	c5_s0[3] = g5[3] | (p5[3] & c5_s0[2]);
assign	c5_s0[4] = g5[4] | (p5[4] & c5_s0[3]);
assign	c5_s0[5] = g5[5] | (p5[5] & c5_s0[4]);
assign	c5_s0[6] = g5[6] | (p5[6] & c5_s0[5]);
assign	c5_s1[0] = g5[0] | p5[0];
assign	c5_s1[1] = g5[1] | (p5[1] & c5_s1[0]);
assign	c5_s1[2] = g5[2] | (p5[2] & c5_s1[1]);
assign	c5_s1[3] = g5[3] | (p5[3] & c5_s1[2]);
assign	c5_s1[4] = g5[4] | (p5[4] & c5_s1[3]);
assign	c5_s1[5] = g5[5] | (p5[5] & c5_s1[4]);
assign	c5_s1[6] = g5[6] | (p5[6] & c5_s1[5]);
assign	c5 = c4[5] ? c5_s1 : c5_s0;
assign	sum[24 : 18] = a[24 : 18] ^ b[24 : 18] ^ {c5[5:0], c4[5]};

assign	g6 = a[31 : 25] & b[31 : 25];
assign	p6 = a[31 : 25] | b[31 : 25];
assign	c6_s0[0] = g6[0];
assign 	c6_s0[1] = g6[1] | (p6[1] & c6_s0[0]);
assign 	c6_s0[2] = g6[2] | (p6[2] & c6_s0[1]);
assign	c6_s0[3] = g6[3] | (p6[3] & c6_s0[2]);
assign	c6_s0[4] = g6[4] | (p6[4] & c6_s0[3]);
assign	c6_s0[5] = g6[5] | (p6[5] & c6_s0[4]);
assign	c6_s0[6] = g6[6] | (p6[6] & c6_s0[5]);
assign	c6_s1[0] = g6[0] | p6[0];
assign	c6_s1[1] = g6[1] | (p6[1] & c6_s1[0]);
assign	c6_s1[2] = g6[2] | (p6[2] & c6_s1[1]);
assign	c6_s1[3] = g6[3] | (p6[3] & c6_s1[2]);
assign	c6_s1[4] = g6[4] | (p6[4] & c6_s1[3]);
assign	c6_s1[5] = g6[5] | (p6[5] & c6_s1[4]);
assign	c6_s1[6] = g6[6] | (p6[6] & c6_s1[5]);
assign	c6 = c5[6] ? c6_s1 : c6_s0;
assign	sum[31 : 25] = a[31 : 25] ^ b[31 : 25] ^ {c6[5:0], c5[6]};

assign	cout = c6[6];

assign result = sum[24:0];

endmodule

module walltree_mul(
	input wire [23:0] op1,
	input wire [23:0] op2,
	output wire [48:0] result
);

// signals for the partial products
wire [23:0] pp0;
wire [23:0] pp1;
wire [23:0] pp2;
wire [23:0] pp3;
wire [23:0] pp4;
wire [23:0] pp5;
wire [23:0] pp6;
wire [23:0] pp7;
wire [23:0] pp8;
wire [23:0] pp9;
wire [23:0] pp10;
wire [23:0] pp11;
wire [23:0] pp12;
wire [23:0] pp13;
wire [23:0] pp14;
wire [23:0] pp15;
wire [23:0] pp16;
wire [23:0] pp17;
wire [23:0] pp18;
wire [23:0] pp19;
wire [23:0] pp20;
wire [23:0] pp21;
wire [23:0] pp22;
wire [23:0] pp23;  // internal signals

wire [25:0] sigCSA_sum_0;
wire [25:0] sigCSA_cry_0;

wire [25:0] sigCSA_sum_1;
wire [25:0] sigCSA_cry_1;  

wire [25:0] sigCSA_sum_2;
wire [25:0] sigCSA_cry_2;  

wire [25:0] sigCSA_sum_3;
wire [25:0] sigCSA_cry_3;  

wire [25:0] sigCSA_sum_4;
wire [25:0] sigCSA_cry_4;  

wire [25:0] sigCSA_sum_5;
wire [25:0] sigCSA_cry_5; 

wire [25:0] sigCSA_sum_6;
wire [25:0] sigCSA_cry_6; 

wire [25:0] sigCSA_sum_7;
wire [25:0] sigCSA_cry_7; 

wire [28:0] sigCSA_sum_8;
wire [28:0] sigCSA_cry_8; 

wire [28:0] sigCSA_sum_9;
wire [28:0] sigCSA_cry_9;  

wire [28:0] sigCSA_sum_10;
wire [28:0] sigCSA_cry_10; 

wire [28:0] sigCSA_sum_11;
wire [28:0] sigCSA_cry_11; 

wire [28:0] sigCSA_sum_12;
wire [28:0] sigCSA_cry_12; 

wire [32:0] sigCSA_sum_13;
wire [32:0] sigCSA_cry_13;  

wire [33:0] sigCSA_sum_14;
wire [33:0] sigCSA_cry_14;  

wire [33:0] sigCSA_sum_15;
wire [33:0] sigCSA_cry_15;  

wire [38:0] sigCSA_sum_16;
wire [38:0] sigCSA_cry_16;

wire [41:0] sigCSA_sum_17;
wire [41:0] sigCSA_cry_17; 

wire [47:0] sigCSA_sum_18;
wire [47:0] sigCSA_cry_18;

wire [47:0] sigCSA_sum_19;
wire [47:0] sigCSA_cry_19; 

wire [54:0] sigCSA_sum_20;
wire [54:0] sigCSA_cry_20; 

wire [55:0] sigCSA_sum_21;
wire [55:0] sigCSA_cry_21; 


wire [54:0] carry_rca;

  assign pp0[0] = op1[0] & op2[0];
  assign pp0[1] = op1[0] & op2[1];
  assign pp0[2] = op1[0] & op2[2];
  assign pp0[3] = op1[0] & op2[3];
  assign pp0[4] = op1[0] & op2[4];
  assign pp0[5] = op1[0] & op2[5];
  assign pp0[6] = op1[0] & op2[6];
  assign pp0[7] = op1[0] & op2[7];
  assign pp0[8] = op1[0] & op2[8];
  assign pp0[9] = op1[0] & op2[9];
  assign pp0[10] = op1[0] & op2[10];
  assign pp0[11] = op1[0] & op2[11];
  assign pp0[12] = op1[0] & op2[12];
  assign pp0[13] = op1[0] & op2[13];
  assign pp0[14] = op1[0] & op2[14];
  assign pp0[15] = op1[0] & op2[15];
  assign pp0[16] = op1[0] & op2[16];
  assign pp0[17] = op1[0] & op2[17];
  assign pp0[18] = op1[0] & op2[18];
  assign pp0[19] = op1[0] & op2[19];
  assign pp0[20] = op1[0] & op2[20];
  assign pp0[21] = op1[0] & op2[21];
  assign pp0[22] = op1[0] & op2[22];
  assign pp0[23] = op1[0] & op2[23];
  assign pp1[0] = op1[1] & op2[0];
  assign pp1[1] = op1[1] & op2[1];
  assign pp1[2] = op1[1] & op2[2];
  assign pp1[3] = op1[1] & op2[3];
  assign pp1[4] = op1[1] & op2[4];
  assign pp1[5] = op1[1] & op2[5];
  assign pp1[6] = op1[1] & op2[6];
  assign pp1[7] = op1[1] & op2[7];
  assign pp1[8] = op1[1] & op2[8];
  assign pp1[9] = op1[1] & op2[9];
  assign pp1[10] = op1[1] & op2[10];
  assign pp1[11] = op1[1] & op2[11];
  assign pp1[12] = op1[1] & op2[12];
  assign pp1[13] = op1[1] & op2[13];
  assign pp1[14] = op1[1] & op2[14];
  assign pp1[15] = op1[1] & op2[15];
  assign pp1[16] = op1[1] & op2[16];
  assign pp1[17] = op1[1] & op2[17];
  assign pp1[18] = op1[1] & op2[18];
  assign pp1[19] = op1[1] & op2[19];
  assign pp1[20] = op1[1] & op2[20];
  assign pp1[21] = op1[1] & op2[21];
  assign pp1[22] = op1[1] & op2[22];
  assign pp1[23] = op1[1] & op2[23];
  assign pp2[0] = op1[2] & op2[0];
  assign pp2[1] = op1[2] & op2[1];
  assign pp2[2] = op1[2] & op2[2];
  assign pp2[3] = op1[2] & op2[3];
  assign pp2[4] = op1[2] & op2[4];
  assign pp2[5] = op1[2] & op2[5];
  assign pp2[6] = op1[2] & op2[6];
  assign pp2[7] = op1[2] & op2[7];
  assign pp2[8] = op1[2] & op2[8];
  assign pp2[9] = op1[2] & op2[9];
  assign pp2[10] = op1[2] & op2[10];
  assign pp2[11] = op1[2] & op2[11];
  assign pp2[12] = op1[2] & op2[12];
  assign pp2[13] = op1[2] & op2[13];
  assign pp2[14] = op1[2] & op2[14];
  assign pp2[15] = op1[2] & op2[15];
  assign pp2[16] = op1[2] & op2[16];
  assign pp2[17] = op1[2] & op2[17];
  assign pp2[18] = op1[2] & op2[18];
  assign pp2[19] = op1[2] & op2[19];
  assign pp2[20] = op1[2] & op2[20];
  assign pp2[21] = op1[2] & op2[21];
  assign pp2[22] = op1[2] & op2[22];
  assign pp2[23] = op1[2] & op2[23];
  assign pp3[0] = op1[3] & op2[0];
  assign pp3[1] = op1[3] & op2[1];
  assign pp3[2] = op1[3] & op2[2];
  assign pp3[3] = op1[3] & op2[3];
  assign pp3[4] = op1[3] & op2[4];
  assign pp3[5] = op1[3] & op2[5];
  assign pp3[6] = op1[3] & op2[6];
  assign pp3[7] = op1[3] & op2[7];
  assign pp3[8] = op1[3] & op2[8];
  assign pp3[9] = op1[3] & op2[9];
  assign pp3[10] = op1[3] & op2[10];
  assign pp3[11] = op1[3] & op2[11];
  assign pp3[12] = op1[3] & op2[12];
  assign pp3[13] = op1[3] & op2[13];
  assign pp3[14] = op1[3] & op2[14];
  assign pp3[15] = op1[3] & op2[15];
  assign pp3[16] = op1[3] & op2[16];
  assign pp3[17] = op1[3] & op2[17];
  assign pp3[18] = op1[3] & op2[18];
  assign pp3[19] = op1[3] & op2[19];
  assign pp3[20] = op1[3] & op2[20];
  assign pp3[21] = op1[3] & op2[21];
  assign pp3[22] = op1[3] & op2[22];
  assign pp3[23] = op1[3] & op2[23];
  assign pp4[0] = op1[4] & op2[0];
  assign pp4[1] = op1[4] & op2[1];
  assign pp4[2] = op1[4] & op2[2];
  assign pp4[3] = op1[4] & op2[3];
  assign pp4[4] = op1[4] & op2[4];
  assign pp4[5] = op1[4] & op2[5];
  assign pp4[6] = op1[4] & op2[6];
  assign pp4[7] = op1[4] & op2[7];
  assign pp4[8] = op1[4] & op2[8];
  assign pp4[9] = op1[4] & op2[9];
  assign pp4[10] = op1[4] & op2[10];
  assign pp4[11] = op1[4] & op2[11];
  assign pp4[12] = op1[4] & op2[12];
  assign pp4[13] = op1[4] & op2[13];
  assign pp4[14] = op1[4] & op2[14];
  assign pp4[15] = op1[4] & op2[15];
  assign pp4[16] = op1[4] & op2[16];
  assign pp4[17] = op1[4] & op2[17];
  assign pp4[18] = op1[4] & op2[18];
  assign pp4[19] = op1[4] & op2[19];
  assign pp4[20] = op1[4] & op2[20];
  assign pp4[21] = op1[4] & op2[21];
  assign pp4[22] = op1[4] & op2[22];
  assign pp4[23] = op1[4] & op2[23];
  assign pp5[0] = op1[5] & op2[0];
  assign pp5[1] = op1[5] & op2[1];
  assign pp5[2] = op1[5] & op2[2];
  assign pp5[3] = op1[5] & op2[3];
  assign pp5[4] = op1[5] & op2[4];
  assign pp5[5] = op1[5] & op2[5];
  assign pp5[6] = op1[5] & op2[6];
  assign pp5[7] = op1[5] & op2[7];
  assign pp5[8] = op1[5] & op2[8];
  assign pp5[9] = op1[5] & op2[9];
  assign pp5[10] = op1[5] & op2[10];
  assign pp5[11] = op1[5] & op2[11];
  assign pp5[12] = op1[5] & op2[12];
  assign pp5[13] = op1[5] & op2[13];
  assign pp5[14] = op1[5] & op2[14];
  assign pp5[15] = op1[5] & op2[15];
  assign pp5[16] = op1[5] & op2[16];
  assign pp5[17] = op1[5] & op2[17];
  assign pp5[18] = op1[5] & op2[18];
  assign pp5[19] = op1[5] & op2[19];
  assign pp5[20] = op1[5] & op2[20];
  assign pp5[21] = op1[5] & op2[21];
  assign pp5[22] = op1[5] & op2[22];
  assign pp5[23] = op1[5] & op2[23];
  assign pp6[0] = op1[6] & op2[0];
  assign pp6[1] = op1[6] & op2[1];
  assign pp6[2] = op1[6] & op2[2];
  assign pp6[3] = op1[6] & op2[3];
  assign pp6[4] = op1[6] & op2[4];
  assign pp6[5] = op1[6] & op2[5];
  assign pp6[6] = op1[6] & op2[6];
  assign pp6[7] = op1[6] & op2[7];
  assign pp6[8] = op1[6] & op2[8];
  assign pp6[9] = op1[6] & op2[9];
  assign pp6[10] = op1[6] & op2[10];
  assign pp6[11] = op1[6] & op2[11];
  assign pp6[12] = op1[6] & op2[12];
  assign pp6[13] = op1[6] & op2[13];
  assign pp6[14] = op1[6] & op2[14];
  assign pp6[15] = op1[6] & op2[15];
  assign pp6[16] = op1[6] & op2[16];
  assign pp6[17] = op1[6] & op2[17];
  assign pp6[18] = op1[6] & op2[18];
  assign pp6[19] = op1[6] & op2[19];
  assign pp6[20] = op1[6] & op2[20];
  assign pp6[21] = op1[6] & op2[21];
  assign pp6[22] = op1[6] & op2[22];
  assign pp6[23] = op1[6] & op2[23];
  assign pp7[0] = op1[7] & op2[0];
  assign pp7[1] = op1[7] & op2[1];
  assign pp7[2] = op1[7] & op2[2];
  assign pp7[3] = op1[7] & op2[3];
  assign pp7[4] = op1[7] & op2[4];
  assign pp7[5] = op1[7] & op2[5];
  assign pp7[6] = op1[7] & op2[6];
  assign pp7[7] = op1[7] & op2[7];
  assign pp7[8] = op1[7] & op2[8];
  assign pp7[9] = op1[7] & op2[9];
  assign pp7[10] = op1[7] & op2[10];
  assign pp7[11] = op1[7] & op2[11];
  assign pp7[12] = op1[7] & op2[12];
  assign pp7[13] = op1[7] & op2[13];
  assign pp7[14] = op1[7] & op2[14];
  assign pp7[15] = op1[7] & op2[15];
  assign pp7[16] = op1[7] & op2[16];
  assign pp7[17] = op1[7] & op2[17];
  assign pp7[18] = op1[7] & op2[18];
  assign pp7[19] = op1[7] & op2[19];
  assign pp7[20] = op1[7] & op2[20];
  assign pp7[21] = op1[7] & op2[21];
  assign pp7[22] = op1[7] & op2[22];
  assign pp7[23] = op1[7] & op2[23];
  assign pp8[0] = op1[8] & op2[0];
  assign pp8[1] = op1[8] & op2[1];
  assign pp8[2] = op1[8] & op2[2];
  assign pp8[3] = op1[8] & op2[3];
  assign pp8[4] = op1[8] & op2[4];
  assign pp8[5] = op1[8] & op2[5];
  assign pp8[6] = op1[8] & op2[6];
  assign pp8[7] = op1[8] & op2[7];
  assign pp8[8] = op1[8] & op2[8];
  assign pp8[9] = op1[8] & op2[9];
  assign pp8[10] = op1[8] & op2[10];
  assign pp8[11] = op1[8] & op2[11];
  assign pp8[12] = op1[8] & op2[12];
  assign pp8[13] = op1[8] & op2[13];
  assign pp8[14] = op1[8] & op2[14];
  assign pp8[15] = op1[8] & op2[15];
  assign pp8[16] = op1[8] & op2[16];
  assign pp8[17] = op1[8] & op2[17];
  assign pp8[18] = op1[8] & op2[18];
  assign pp8[19] = op1[8] & op2[19];
  assign pp8[20] = op1[8] & op2[20];
  assign pp8[21] = op1[8] & op2[21];
  assign pp8[22] = op1[8] & op2[22];
  assign pp8[23] = op1[8] & op2[23];
  assign pp9[0] = op1[9] & op2[0];
  assign pp9[1] = op1[9] & op2[1];
  assign pp9[2] = op1[9] & op2[2];
  assign pp9[3] = op1[9] & op2[3];
  assign pp9[4] = op1[9] & op2[4];
  assign pp9[5] = op1[9] & op2[5];
  assign pp9[6] = op1[9] & op2[6];
  assign pp9[7] = op1[9] & op2[7];
  assign pp9[8] = op1[9] & op2[8];
  assign pp9[9] = op1[9] & op2[9];
  assign pp9[10] = op1[9] & op2[10];
  assign pp9[11] = op1[9] & op2[11];
  assign pp9[12] = op1[9] & op2[12];
  assign pp9[13] = op1[9] & op2[13];
  assign pp9[14] = op1[9] & op2[14];
  assign pp9[15] = op1[9] & op2[15];
  assign pp9[16] = op1[9] & op2[16];
  assign pp9[17] = op1[9] & op2[17];
  assign pp9[18] = op1[9] & op2[18];
  assign pp9[19] = op1[9] & op2[19];
  assign pp9[20] = op1[9] & op2[20];
  assign pp9[21] = op1[9] & op2[21];
  assign pp9[22] = op1[9] & op2[22];
  assign pp9[23] = op1[9] & op2[23];
  assign pp10[0] = op1[10] & op2[0];
  assign pp10[1] = op1[10] & op2[1];
  assign pp10[2] = op1[10] & op2[2];
  assign pp10[3] = op1[10] & op2[3];
  assign pp10[4] = op1[10] & op2[4];
  assign pp10[5] = op1[10] & op2[5];
  assign pp10[6] = op1[10] & op2[6];
  assign pp10[7] = op1[10] & op2[7];
  assign pp10[8] = op1[10] & op2[8];
  assign pp10[9] = op1[10] & op2[9];
  assign pp10[10] = op1[10] & op2[10];
  assign pp10[11] = op1[10] & op2[11];
  assign pp10[12] = op1[10] & op2[12];
  assign pp10[13] = op1[10] & op2[13];
  assign pp10[14] = op1[10] & op2[14];
  assign pp10[15] = op1[10] & op2[15];
  assign pp10[16] = op1[10] & op2[16];
  assign pp10[17] = op1[10] & op2[17];
  assign pp10[18] = op1[10] & op2[18];
  assign pp10[19] = op1[10] & op2[19];
  assign pp10[20] = op1[10] & op2[20];
  assign pp10[21] = op1[10] & op2[21];
  assign pp10[22] = op1[10] & op2[22];
  assign pp10[23] = op1[10] & op2[23];
  assign pp11[0] = op1[11] & op2[0];
  assign pp11[1] = op1[11] & op2[1];
  assign pp11[2] = op1[11] & op2[2];
  assign pp11[3] = op1[11] & op2[3];
  assign pp11[4] = op1[11] & op2[4];
  assign pp11[5] = op1[11] & op2[5];
  assign pp11[6] = op1[11] & op2[6];
  assign pp11[7] = op1[11] & op2[7];
  assign pp11[8] = op1[11] & op2[8];
  assign pp11[9] = op1[11] & op2[9];
  assign pp11[10] = op1[11] & op2[10];
  assign pp11[11] = op1[11] & op2[11];
  assign pp11[12] = op1[11] & op2[12];
  assign pp11[13] = op1[11] & op2[13];
  assign pp11[14] = op1[11] & op2[14];
  assign pp11[15] = op1[11] & op2[15];
  assign pp11[16] = op1[11] & op2[16];
  assign pp11[17] = op1[11] & op2[17];
  assign pp11[18] = op1[11] & op2[18];
  assign pp11[19] = op1[11] & op2[19];
  assign pp11[20] = op1[11] & op2[20];
  assign pp11[21] = op1[11] & op2[21];
  assign pp11[22] = op1[11] & op2[22];
  assign pp11[23] = op1[11] & op2[23];
  assign pp12[0] = op1[12] & op2[0];
  assign pp12[1] = op1[12] & op2[1];
  assign pp12[2] = op1[12] & op2[2];
  assign pp12[3] = op1[12] & op2[3];
  assign pp12[4] = op1[12] & op2[4];
  assign pp12[5] = op1[12] & op2[5];
  assign pp12[6] = op1[12] & op2[6];
  assign pp12[7] = op1[12] & op2[7];
  assign pp12[8] = op1[12] & op2[8];
  assign pp12[9] = op1[12] & op2[9];
  assign pp12[10] = op1[12] & op2[10];
  assign pp12[11] = op1[12] & op2[11];
  assign pp12[12] = op1[12] & op2[12];
  assign pp12[13] = op1[12] & op2[13];
  assign pp12[14] = op1[12] & op2[14];
  assign pp12[15] = op1[12] & op2[15];
  assign pp12[16] = op1[12] & op2[16];
  assign pp12[17] = op1[12] & op2[17];
  assign pp12[18] = op1[12] & op2[18];
  assign pp12[19] = op1[12] & op2[19];
  assign pp12[20] = op1[12] & op2[20];
  assign pp12[21] = op1[12] & op2[21];
  assign pp12[22] = op1[12] & op2[22];
  assign pp12[23] = op1[12] & op2[23];
  assign pp13[0] = op1[13] & op2[0];
  assign pp13[1] = op1[13] & op2[1];
  assign pp13[2] = op1[13] & op2[2];
  assign pp13[3] = op1[13] & op2[3];
  assign pp13[4] = op1[13] & op2[4];
  assign pp13[5] = op1[13] & op2[5];
  assign pp13[6] = op1[13] & op2[6];
  assign pp13[7] = op1[13] & op2[7];
  assign pp13[8] = op1[13] & op2[8];
  assign pp13[9] = op1[13] & op2[9];
  assign pp13[10] = op1[13] & op2[10];
  assign pp13[11] = op1[13] & op2[11];
  assign pp13[12] = op1[13] & op2[12];
  assign pp13[13] = op1[13] & op2[13];
  assign pp13[14] = op1[13] & op2[14];
  assign pp13[15] = op1[13] & op2[15];
  assign pp13[16] = op1[13] & op2[16];
  assign pp13[17] = op1[13] & op2[17];
  assign pp13[18] = op1[13] & op2[18];
  assign pp13[19] = op1[13] & op2[19];
  assign pp13[20] = op1[13] & op2[20];
  assign pp13[21] = op1[13] & op2[21];
  assign pp13[22] = op1[13] & op2[22];
  assign pp13[23] = op1[13] & op2[23];
  assign pp14[0] = op1[14] & op2[0];
  assign pp14[1] = op1[14] & op2[1];
  assign pp14[2] = op1[14] & op2[2];
  assign pp14[3] = op1[14] & op2[3];
  assign pp14[4] = op1[14] & op2[4];
  assign pp14[5] = op1[14] & op2[5];
  assign pp14[6] = op1[14] & op2[6];
  assign pp14[7] = op1[14] & op2[7];
  assign pp14[8] = op1[14] & op2[8];
  assign pp14[9] = op1[14] & op2[9];
  assign pp14[10] = op1[14] & op2[10];
  assign pp14[11] = op1[14] & op2[11];
  assign pp14[12] = op1[14] & op2[12];
  assign pp14[13] = op1[14] & op2[13];
  assign pp14[14] = op1[14] & op2[14];
  assign pp14[15] = op1[14] & op2[15];
  assign pp14[16] = op1[14] & op2[16];
  assign pp14[17] = op1[14] & op2[17];
  assign pp14[18] = op1[14] & op2[18];
  assign pp14[19] = op1[14] & op2[19];
  assign pp14[20] = op1[14] & op2[20];
  assign pp14[21] = op1[14] & op2[21];
  assign pp14[22] = op1[14] & op2[22];
  assign pp14[23] = op1[14] & op2[23];
  assign pp15[0] = op1[15] & op2[0];
  assign pp15[1] = op1[15] & op2[1];
  assign pp15[2] = op1[15] & op2[2];
  assign pp15[3] = op1[15] & op2[3];
  assign pp15[4] = op1[15] & op2[4];
  assign pp15[5] = op1[15] & op2[5];
  assign pp15[6] = op1[15] & op2[6];
  assign pp15[7] = op1[15] & op2[7];
  assign pp15[8] = op1[15] & op2[8];
  assign pp15[9] = op1[15] & op2[9];
  assign pp15[10] = op1[15] & op2[10];
  assign pp15[11] = op1[15] & op2[11];
  assign pp15[12] = op1[15] & op2[12];
  assign pp15[13] = op1[15] & op2[13];
  assign pp15[14] = op1[15] & op2[14];
  assign pp15[15] = op1[15] & op2[15];
  assign pp15[16] = op1[15] & op2[16];
  assign pp15[17] = op1[15] & op2[17];
  assign pp15[18] = op1[15] & op2[18];
  assign pp15[19] = op1[15] & op2[19];
  assign pp15[20] = op1[15] & op2[20];
  assign pp15[21] = op1[15] & op2[21];
  assign pp15[22] = op1[15] & op2[22];
  assign pp15[23] = op1[15] & op2[23];
  assign pp16[0] = op1[16] & op2[0];
  assign pp16[1] = op1[16] & op2[1];
  assign pp16[2] = op1[16] & op2[2];
  assign pp16[3] = op1[16] & op2[3];
  assign pp16[4] = op1[16] & op2[4];
  assign pp16[5] = op1[16] & op2[5];
  assign pp16[6] = op1[16] & op2[6];
  assign pp16[7] = op1[16] & op2[7];
  assign pp16[8] = op1[16] & op2[8];
  assign pp16[9] = op1[16] & op2[9];
  assign pp16[10] = op1[16] & op2[10];
  assign pp16[11] = op1[16] & op2[11];
  assign pp16[12] = op1[16] & op2[12];
  assign pp16[13] = op1[16] & op2[13];
  assign pp16[14] = op1[16] & op2[14];
  assign pp16[15] = op1[16] & op2[15];
  assign pp16[16] = op1[16] & op2[16];
  assign pp16[17] = op1[16] & op2[17];
  assign pp16[18] = op1[16] & op2[18];
  assign pp16[19] = op1[16] & op2[19];
  assign pp16[20] = op1[16] & op2[20];
  assign pp16[21] = op1[16] & op2[21];
  assign pp16[22] = op1[16] & op2[22];
  assign pp16[23] = op1[16] & op2[23];
  assign pp17[0] = op1[17] & op2[0];
  assign pp17[1] = op1[17] & op2[1];
  assign pp17[2] = op1[17] & op2[2];
  assign pp17[3] = op1[17] & op2[3];
  assign pp17[4] = op1[17] & op2[4];
  assign pp17[5] = op1[17] & op2[5];
  assign pp17[6] = op1[17] & op2[6];
  assign pp17[7] = op1[17] & op2[7];
  assign pp17[8] = op1[17] & op2[8];
  assign pp17[9] = op1[17] & op2[9];
  assign pp17[10] = op1[17] & op2[10];
  assign pp17[11] = op1[17] & op2[11];
  assign pp17[12] = op1[17] & op2[12];
  assign pp17[13] = op1[17] & op2[13];
  assign pp17[14] = op1[17] & op2[14];
  assign pp17[15] = op1[17] & op2[15];
  assign pp17[16] = op1[17] & op2[16];
  assign pp17[17] = op1[17] & op2[17];
  assign pp17[18] = op1[17] & op2[18];
  assign pp17[19] = op1[17] & op2[19];
  assign pp17[20] = op1[17] & op2[20];
  assign pp17[21] = op1[17] & op2[21];
  assign pp17[22] = op1[17] & op2[22];
  assign pp17[23] = op1[17] & op2[23];
  assign pp18[0] = op1[18] & op2[0];
  assign pp18[1] = op1[18] & op2[1];
  assign pp18[2] = op1[18] & op2[2];
  assign pp18[3] = op1[18] & op2[3];
  assign pp18[4] = op1[18] & op2[4];
  assign pp18[5] = op1[18] & op2[5];
  assign pp18[6] = op1[18] & op2[6];
  assign pp18[7] = op1[18] & op2[7];
  assign pp18[8] = op1[18] & op2[8];
  assign pp18[9] = op1[18] & op2[9];
  assign pp18[10] = op1[18] & op2[10];
  assign pp18[11] = op1[18] & op2[11];
  assign pp18[12] = op1[18] & op2[12];
  assign pp18[13] = op1[18] & op2[13];
  assign pp18[14] = op1[18] & op2[14];
  assign pp18[15] = op1[18] & op2[15];
  assign pp18[16] = op1[18] & op2[16];
  assign pp18[17] = op1[18] & op2[17];
  assign pp18[18] = op1[18] & op2[18];
  assign pp18[19] = op1[18] & op2[19];
  assign pp18[20] = op1[18] & op2[20];
  assign pp18[21] = op1[18] & op2[21];
  assign pp18[22] = op1[18] & op2[22];
  assign pp18[23] = op1[18] & op2[23];
  assign pp19[0] = op1[19] & op2[0];
  assign pp19[1] = op1[19] & op2[1];
  assign pp19[2] = op1[19] & op2[2];
  assign pp19[3] = op1[19] & op2[3];
  assign pp19[4] = op1[19] & op2[4];
  assign pp19[5] = op1[19] & op2[5];
  assign pp19[6] = op1[19] & op2[6];
  assign pp19[7] = op1[19] & op2[7];
  assign pp19[8] = op1[19] & op2[8];
  assign pp19[9] = op1[19] & op2[9];
  assign pp19[10] = op1[19] & op2[10];
  assign pp19[11] = op1[19] & op2[11];
  assign pp19[12] = op1[19] & op2[12];
  assign pp19[13] = op1[19] & op2[13];
  assign pp19[14] = op1[19] & op2[14];
  assign pp19[15] = op1[19] & op2[15];
  assign pp19[16] = op1[19] & op2[16];
  assign pp19[17] = op1[19] & op2[17];
  assign pp19[18] = op1[19] & op2[18];
  assign pp19[19] = op1[19] & op2[19];
  assign pp19[20] = op1[19] & op2[20];
  assign pp19[21] = op1[19] & op2[21];
  assign pp19[22] = op1[19] & op2[22];
  assign pp19[23] = op1[19] & op2[23];
  assign pp20[0] = op1[20] & op2[0];
  assign pp20[1] = op1[20] & op2[1];
  assign pp20[2] = op1[20] & op2[2];
  assign pp20[3] = op1[20] & op2[3];
  assign pp20[4] = op1[20] & op2[4];
  assign pp20[5] = op1[20] & op2[5];
  assign pp20[6] = op1[20] & op2[6];
  assign pp20[7] = op1[20] & op2[7];
  assign pp20[8] = op1[20] & op2[8];
  assign pp20[9] = op1[20] & op2[9];
  assign pp20[10] = op1[20] & op2[10];
  assign pp20[11] = op1[20] & op2[11];
  assign pp20[12] = op1[20] & op2[12];
  assign pp20[13] = op1[20] & op2[13];
  assign pp20[14] = op1[20] & op2[14];
  assign pp20[15] = op1[20] & op2[15];
  assign pp20[16] = op1[20] & op2[16];
  assign pp20[17] = op1[20] & op2[17];
  assign pp20[18] = op1[20] & op2[18];
  assign pp20[19] = op1[20] & op2[19];
  assign pp20[20] = op1[20] & op2[20];
  assign pp20[21] = op1[20] & op2[21];
  assign pp20[22] = op1[20] & op2[22];
  assign pp20[23] = op1[20] & op2[23];
  assign pp21[0] = op1[21] & op2[0];
  assign pp21[1] = op1[21] & op2[1];
  assign pp21[2] = op1[21] & op2[2];
  assign pp21[3] = op1[21] & op2[3];
  assign pp21[4] = op1[21] & op2[4];
  assign pp21[5] = op1[21] & op2[5];
  assign pp21[6] = op1[21] & op2[6];
  assign pp21[7] = op1[21] & op2[7];
  assign pp21[8] = op1[21] & op2[8];
  assign pp21[9] = op1[21] & op2[9];
  assign pp21[10] = op1[21] & op2[10];
  assign pp21[11] = op1[21] & op2[11];
  assign pp21[12] = op1[21] & op2[12];
  assign pp21[13] = op1[21] & op2[13];
  assign pp21[14] = op1[21] & op2[14];
  assign pp21[15] = op1[21] & op2[15];
  assign pp21[16] = op1[21] & op2[16];
  assign pp21[17] = op1[21] & op2[17];
  assign pp21[18] = op1[21] & op2[18];
  assign pp21[19] = op1[21] & op2[19];
  assign pp21[20] = op1[21] & op2[20];
  assign pp21[21] = op1[21] & op2[21];
  assign pp21[22] = op1[21] & op2[22];
  assign pp21[23] = op1[21] & op2[23];
  assign pp22[0] = op1[22] & op2[0];
  assign pp22[1] = op1[22] & op2[1];
  assign pp22[2] = op1[22] & op2[2];
  assign pp22[3] = op1[22] & op2[3];
  assign pp22[4] = op1[22] & op2[4];
  assign pp22[5] = op1[22] & op2[5];
  assign pp22[6] = op1[22] & op2[6];
  assign pp22[7] = op1[22] & op2[7];
  assign pp22[8] = op1[22] & op2[8];
  assign pp22[9] = op1[22] & op2[9];
  assign pp22[10] = op1[22] & op2[10];
  assign pp22[11] = op1[22] & op2[11];
  assign pp22[12] = op1[22] & op2[12];
  assign pp22[13] = op1[22] & op2[13];
  assign pp22[14] = op1[22] & op2[14];
  assign pp22[15] = op1[22] & op2[15];
  assign pp22[16] = op1[22] & op2[16];
  assign pp22[17] = op1[22] & op2[17];
  assign pp22[18] = op1[22] & op2[18];
  assign pp22[19] = op1[22] & op2[19];
  assign pp22[20] = op1[22] & op2[20];
  assign pp22[21] = op1[22] & op2[21];
  assign pp22[22] = op1[22] & op2[22];
  assign pp22[23] = op1[22] & op2[23];
  assign pp23[0] = op1[23] & op2[0];
  assign pp23[1] = op1[23] & op2[1];
  assign pp23[2] = op1[23] & op2[2];
  assign pp23[3] = op1[23] & op2[3];
  assign pp23[4] = op1[23] & op2[4];
  assign pp23[5] = op1[23] & op2[5];
  assign pp23[6] = op1[23] & op2[6];
  assign pp23[7] = op1[23] & op2[7];
  assign pp23[8] = op1[23] & op2[8];
  assign pp23[9] = op1[23] & op2[9];
  assign pp23[10] = op1[23] & op2[10];
  assign pp23[11] = op1[23] & op2[11];
  assign pp23[12] = op1[23] & op2[12];
  assign pp23[13] = op1[23] & op2[13];
  assign pp23[14] = op1[23] & op2[14];
  assign pp23[15] = op1[23] & op2[15];
  assign pp23[16] = op1[23] & op2[16];
  assign pp23[17] = op1[23] & op2[17];
  assign pp23[18] = op1[23] & op2[18];
  assign pp23[19] = op1[23] & op2[19];
  assign pp23[20] = op1[23] & op2[20];
  assign pp23[21] = op1[23] & op2[21];
  assign pp23[22] = op1[23] & op2[22];
  assign pp23[23] = op1[23] & op2[23];
  // ******************
  // csa : 0
  // generating sigCSA_sum_0 and sigCSA_cry_0
  assign sigCSA_sum_0[0] = pp0[0] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_0[0] = ((pp0[0] & 1'b 0)) | ((1'b 0 & ((pp0[0] ^ 1'b 0))));
  assign sigCSA_sum_0[1] = pp0[1] ^ pp1[0] ^ 1'b 0;
  assign sigCSA_cry_0[1] = ((pp0[1] & pp1[0])) | ((1'b 0 & ((pp0[1] ^ pp1[0]))));
  assign sigCSA_sum_0[2] = pp0[2] ^ pp1[1] ^ pp2[0];
  assign sigCSA_cry_0[2] = ((pp0[2] & pp1[1])) | ((pp2[0] & ((pp0[2] ^ pp1[1]))));
  assign sigCSA_sum_0[3] = pp0[3] ^ pp1[2] ^ pp2[1];
  assign sigCSA_cry_0[3] = ((pp0[3] & pp1[2])) | ((pp2[1] & ((pp0[3] ^ pp1[2]))));
  assign sigCSA_sum_0[4] = pp0[4] ^ pp1[3] ^ pp2[2];
  assign sigCSA_cry_0[4] = ((pp0[4] & pp1[3])) | ((pp2[2] & ((pp0[4] ^ pp1[3]))));
  assign sigCSA_sum_0[5] = pp0[5] ^ pp1[4] ^ pp2[3];
  assign sigCSA_cry_0[5] = ((pp0[5] & pp1[4])) | ((pp2[3] & ((pp0[5] ^ pp1[4]))));
  assign sigCSA_sum_0[6] = pp0[6] ^ pp1[5] ^ pp2[4];
  assign sigCSA_cry_0[6] = ((pp0[6] & pp1[5])) | ((pp2[4] & ((pp0[6] ^ pp1[5]))));
  assign sigCSA_sum_0[7] = pp0[7] ^ pp1[6] ^ pp2[5];
  assign sigCSA_cry_0[7] = ((pp0[7] & pp1[6])) | ((pp2[5] & ((pp0[7] ^ pp1[6]))));
  assign sigCSA_sum_0[8] = pp0[8] ^ pp1[7] ^ pp2[6];
  assign sigCSA_cry_0[8] = ((pp0[8] & pp1[7])) | ((pp2[6] & ((pp0[8] ^ pp1[7]))));
  assign sigCSA_sum_0[9] = pp0[9] ^ pp1[8] ^ pp2[7];
  assign sigCSA_cry_0[9] = ((pp0[9] & pp1[8])) | ((pp2[7] & ((pp0[9] ^ pp1[8]))));
  assign sigCSA_sum_0[10] = pp0[10] ^ pp1[9] ^ pp2[8];
  assign sigCSA_cry_0[10] = ((pp0[10] & pp1[9])) | ((pp2[8] & ((pp0[10] ^ pp1[9]))));
  assign sigCSA_sum_0[11] = pp0[11] ^ pp1[10] ^ pp2[9];
  assign sigCSA_cry_0[11] = ((pp0[11] & pp1[10])) | ((pp2[9] & ((pp0[11] ^ pp1[10]))));
  assign sigCSA_sum_0[12] = pp0[12] ^ pp1[11] ^ pp2[10];
  assign sigCSA_cry_0[12] = ((pp0[12] & pp1[11])) | ((pp2[10] & ((pp0[12] ^ pp1[11]))));
  assign sigCSA_sum_0[13] = pp0[13] ^ pp1[12] ^ pp2[11];
  assign sigCSA_cry_0[13] = ((pp0[13] & pp1[12])) | ((pp2[11] & ((pp0[13] ^ pp1[12]))));
  assign sigCSA_sum_0[14] = pp0[14] ^ pp1[13] ^ pp2[12];
  assign sigCSA_cry_0[14] = ((pp0[14] & pp1[13])) | ((pp2[12] & ((pp0[14] ^ pp1[13]))));
  assign sigCSA_sum_0[15] = pp0[15] ^ pp1[14] ^ pp2[13];
  assign sigCSA_cry_0[15] = ((pp0[15] & pp1[14])) | ((pp2[13] & ((pp0[15] ^ pp1[14]))));
  assign sigCSA_sum_0[16] = pp0[16] ^ pp1[15] ^ pp2[14];
  assign sigCSA_cry_0[16] = ((pp0[16] & pp1[15])) | ((pp2[14] & ((pp0[16] ^ pp1[15]))));
  assign sigCSA_sum_0[17] = pp0[17] ^ pp1[16] ^ pp2[15];
  assign sigCSA_cry_0[17] = ((pp0[17] & pp1[16])) | ((pp2[15] & ((pp0[17] ^ pp1[16]))));
  assign sigCSA_sum_0[18] = pp0[18] ^ pp1[17] ^ pp2[16];
  assign sigCSA_cry_0[18] = ((pp0[18] & pp1[17])) | ((pp2[16] & ((pp0[18] ^ pp1[17]))));
  assign sigCSA_sum_0[19] = pp0[19] ^ pp1[18] ^ pp2[17];
  assign sigCSA_cry_0[19] = ((pp0[19] & pp1[18])) | ((pp2[17] & ((pp0[19] ^ pp1[18]))));
  assign sigCSA_sum_0[20] = pp0[20] ^ pp1[19] ^ pp2[18];
  assign sigCSA_cry_0[20] = ((pp0[20] & pp1[19])) | ((pp2[18] & ((pp0[20] ^ pp1[19]))));
  assign sigCSA_sum_0[21] = pp0[21] ^ pp1[20] ^ pp2[19];
  assign sigCSA_cry_0[21] = ((pp0[21] & pp1[20])) | ((pp2[19] & ((pp0[21] ^ pp1[20]))));
  assign sigCSA_sum_0[22] = pp0[22] ^ pp1[21] ^ pp2[20];
  assign sigCSA_cry_0[22] = ((pp0[22] & pp1[21])) | ((pp2[20] & ((pp0[22] ^ pp1[21]))));
  assign sigCSA_sum_0[23] = pp0[23] ^ pp1[22] ^ pp2[21];
  assign sigCSA_cry_0[23] = ((pp0[23] & pp1[22])) | ((pp2[21] & ((pp0[23] ^ pp1[22]))));
  assign sigCSA_sum_0[24] = 1'b 0 ^ pp1[23] ^ pp2[22];
  assign sigCSA_cry_0[24] = ((1'b 0 & pp1[23])) | ((pp2[22] & ((1'b 0 ^ pp1[23]))));
  assign sigCSA_sum_0[25] = 1'b 0 ^ 1'b 0 ^ pp2[23];
  assign sigCSA_cry_0[25] = ((1'b 0 & 1'b 0)) | ((pp2[23] & ((1'b 0 ^ 1'b 0))));
  // csa : 1
  // generating sigCSA_sum_1 and sigCSA_cry_1
  assign sigCSA_sum_1[0] = pp3[0] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_1[0] = ((pp3[0] & 1'b 0)) | ((1'b 0 & ((pp3[0] ^ 1'b 0))));
  assign sigCSA_sum_1[1] = pp3[1] ^ pp4[0] ^ 1'b 0;
  assign sigCSA_cry_1[1] = ((pp3[1] & pp4[0])) | ((1'b 0 & ((pp3[1] ^ pp4[0]))));
  assign sigCSA_sum_1[2] = pp3[2] ^ pp4[1] ^ pp5[0];
  assign sigCSA_cry_1[2] = ((pp3[2] & pp4[1])) | ((pp5[0] & ((pp3[2] ^ pp4[1]))));
  assign sigCSA_sum_1[3] = pp3[3] ^ pp4[2] ^ pp5[1];
  assign sigCSA_cry_1[3] = ((pp3[3] & pp4[2])) | ((pp5[1] & ((pp3[3] ^ pp4[2]))));
  assign sigCSA_sum_1[4] = pp3[4] ^ pp4[3] ^ pp5[2];
  assign sigCSA_cry_1[4] = ((pp3[4] & pp4[3])) | ((pp5[2] & ((pp3[4] ^ pp4[3]))));
  assign sigCSA_sum_1[5] = pp3[5] ^ pp4[4] ^ pp5[3];
  assign sigCSA_cry_1[5] = ((pp3[5] & pp4[4])) | ((pp5[3] & ((pp3[5] ^ pp4[4]))));
  assign sigCSA_sum_1[6] = pp3[6] ^ pp4[5] ^ pp5[4];
  assign sigCSA_cry_1[6] = ((pp3[6] & pp4[5])) | ((pp5[4] & ((pp3[6] ^ pp4[5]))));
  assign sigCSA_sum_1[7] = pp3[7] ^ pp4[6] ^ pp5[5];
  assign sigCSA_cry_1[7] = ((pp3[7] & pp4[6])) | ((pp5[5] & ((pp3[7] ^ pp4[6]))));
  assign sigCSA_sum_1[8] = pp3[8] ^ pp4[7] ^ pp5[6];
  assign sigCSA_cry_1[8] = ((pp3[8] & pp4[7])) | ((pp5[6] & ((pp3[8] ^ pp4[7]))));
  assign sigCSA_sum_1[9] = pp3[9] ^ pp4[8] ^ pp5[7];
  assign sigCSA_cry_1[9] = ((pp3[9] & pp4[8])) | ((pp5[7] & ((pp3[9] ^ pp4[8]))));
  assign sigCSA_sum_1[10] = pp3[10] ^ pp4[9] ^ pp5[8];
  assign sigCSA_cry_1[10] = ((pp3[10] & pp4[9])) | ((pp5[8] & ((pp3[10] ^ pp4[9]))));
  assign sigCSA_sum_1[11] = pp3[11] ^ pp4[10] ^ pp5[9];
  assign sigCSA_cry_1[11] = ((pp3[11] & pp4[10])) | ((pp5[9] & ((pp3[11] ^ pp4[10]))));
  assign sigCSA_sum_1[12] = pp3[12] ^ pp4[11] ^ pp5[10];
  assign sigCSA_cry_1[12] = ((pp3[12] & pp4[11])) | ((pp5[10] & ((pp3[12] ^ pp4[11]))));
  assign sigCSA_sum_1[13] = pp3[13] ^ pp4[12] ^ pp5[11];
  assign sigCSA_cry_1[13] = ((pp3[13] & pp4[12])) | ((pp5[11] & ((pp3[13] ^ pp4[12]))));
  assign sigCSA_sum_1[14] = pp3[14] ^ pp4[13] ^ pp5[12];
  assign sigCSA_cry_1[14] = ((pp3[14] & pp4[13])) | ((pp5[12] & ((pp3[14] ^ pp4[13]))));
  assign sigCSA_sum_1[15] = pp3[15] ^ pp4[14] ^ pp5[13];
  assign sigCSA_cry_1[15] = ((pp3[15] & pp4[14])) | ((pp5[13] & ((pp3[15] ^ pp4[14]))));
  assign sigCSA_sum_1[16] = pp3[16] ^ pp4[15] ^ pp5[14];
  assign sigCSA_cry_1[16] = ((pp3[16] & pp4[15])) | ((pp5[14] & ((pp3[16] ^ pp4[15]))));
  assign sigCSA_sum_1[17] = pp3[17] ^ pp4[16] ^ pp5[15];
  assign sigCSA_cry_1[17] = ((pp3[17] & pp4[16])) | ((pp5[15] & ((pp3[17] ^ pp4[16]))));
  assign sigCSA_sum_1[18] = pp3[18] ^ pp4[17] ^ pp5[16];
  assign sigCSA_cry_1[18] = ((pp3[18] & pp4[17])) | ((pp5[16] & ((pp3[18] ^ pp4[17]))));
  assign sigCSA_sum_1[19] = pp3[19] ^ pp4[18] ^ pp5[17];
  assign sigCSA_cry_1[19] = ((pp3[19] & pp4[18])) | ((pp5[17] & ((pp3[19] ^ pp4[18]))));
  assign sigCSA_sum_1[20] = pp3[20] ^ pp4[19] ^ pp5[18];
  assign sigCSA_cry_1[20] = ((pp3[20] & pp4[19])) | ((pp5[18] & ((pp3[20] ^ pp4[19]))));
  assign sigCSA_sum_1[21] = pp3[21] ^ pp4[20] ^ pp5[19];
  assign sigCSA_cry_1[21] = ((pp3[21] & pp4[20])) | ((pp5[19] & ((pp3[21] ^ pp4[20]))));
  assign sigCSA_sum_1[22] = pp3[22] ^ pp4[21] ^ pp5[20];
  assign sigCSA_cry_1[22] = ((pp3[22] & pp4[21])) | ((pp5[20] & ((pp3[22] ^ pp4[21]))));
  assign sigCSA_sum_1[23] = pp3[23] ^ pp4[22] ^ pp5[21];
  assign sigCSA_cry_1[23] = ((pp3[23] & pp4[22])) | ((pp5[21] & ((pp3[23] ^ pp4[22]))));
  assign sigCSA_sum_1[24] = 1'b 0 ^ pp4[23] ^ pp5[22];
  assign sigCSA_cry_1[24] = ((1'b 0 & pp4[23])) | ((pp5[22] & ((1'b 0 ^ pp4[23]))));
  assign sigCSA_sum_1[25] = 1'b 0 ^ 1'b 0 ^ pp5[23];
  assign sigCSA_cry_1[25] = ((1'b 0 & 1'b 0)) | ((pp5[23] & ((1'b 0 ^ 1'b 0))));
  // csa : 2
  // generating sigCSA_sum_2 and sigCSA_cry_2
  assign sigCSA_sum_2[0] = pp6[0] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_2[0] = ((pp6[0] & 1'b 0)) | ((1'b 0 & ((pp6[0] ^ 1'b 0))));
  assign sigCSA_sum_2[1] = pp6[1] ^ pp7[0] ^ 1'b 0;
  assign sigCSA_cry_2[1] = ((pp6[1] & pp7[0])) | ((1'b 0 & ((pp6[1] ^ pp7[0]))));
  assign sigCSA_sum_2[2] = pp6[2] ^ pp7[1] ^ pp8[0];
  assign sigCSA_cry_2[2] = ((pp6[2] & pp7[1])) | ((pp8[0] & ((pp6[2] ^ pp7[1]))));
  assign sigCSA_sum_2[3] = pp6[3] ^ pp7[2] ^ pp8[1];
  assign sigCSA_cry_2[3] = ((pp6[3] & pp7[2])) | ((pp8[1] & ((pp6[3] ^ pp7[2]))));
  assign sigCSA_sum_2[4] = pp6[4] ^ pp7[3] ^ pp8[2];
  assign sigCSA_cry_2[4] = ((pp6[4] & pp7[3])) | ((pp8[2] & ((pp6[4] ^ pp7[3]))));
  assign sigCSA_sum_2[5] = pp6[5] ^ pp7[4] ^ pp8[3];
  assign sigCSA_cry_2[5] = ((pp6[5] & pp7[4])) | ((pp8[3] & ((pp6[5] ^ pp7[4]))));
  assign sigCSA_sum_2[6] = pp6[6] ^ pp7[5] ^ pp8[4];
  assign sigCSA_cry_2[6] = ((pp6[6] & pp7[5])) | ((pp8[4] & ((pp6[6] ^ pp7[5]))));
  assign sigCSA_sum_2[7] = pp6[7] ^ pp7[6] ^ pp8[5];
  assign sigCSA_cry_2[7] = ((pp6[7] & pp7[6])) | ((pp8[5] & ((pp6[7] ^ pp7[6]))));
  assign sigCSA_sum_2[8] = pp6[8] ^ pp7[7] ^ pp8[6];
  assign sigCSA_cry_2[8] = ((pp6[8] & pp7[7])) | ((pp8[6] & ((pp6[8] ^ pp7[7]))));
  assign sigCSA_sum_2[9] = pp6[9] ^ pp7[8] ^ pp8[7];
  assign sigCSA_cry_2[9] = ((pp6[9] & pp7[8])) | ((pp8[7] & ((pp6[9] ^ pp7[8]))));
  assign sigCSA_sum_2[10] = pp6[10] ^ pp7[9] ^ pp8[8];
  assign sigCSA_cry_2[10] = ((pp6[10] & pp7[9])) | ((pp8[8] & ((pp6[10] ^ pp7[9]))));
  assign sigCSA_sum_2[11] = pp6[11] ^ pp7[10] ^ pp8[9];
  assign sigCSA_cry_2[11] = ((pp6[11] & pp7[10])) | ((pp8[9] & ((pp6[11] ^ pp7[10]))));
  assign sigCSA_sum_2[12] = pp6[12] ^ pp7[11] ^ pp8[10];
  assign sigCSA_cry_2[12] = ((pp6[12] & pp7[11])) | ((pp8[10] & ((pp6[12] ^ pp7[11]))));
  assign sigCSA_sum_2[13] = pp6[13] ^ pp7[12] ^ pp8[11];
  assign sigCSA_cry_2[13] = ((pp6[13] & pp7[12])) | ((pp8[11] & ((pp6[13] ^ pp7[12]))));
  assign sigCSA_sum_2[14] = pp6[14] ^ pp7[13] ^ pp8[12];
  assign sigCSA_cry_2[14] = ((pp6[14] & pp7[13])) | ((pp8[12] & ((pp6[14] ^ pp7[13]))));
  assign sigCSA_sum_2[15] = pp6[15] ^ pp7[14] ^ pp8[13];
  assign sigCSA_cry_2[15] = ((pp6[15] & pp7[14])) | ((pp8[13] & ((pp6[15] ^ pp7[14]))));
  assign sigCSA_sum_2[16] = pp6[16] ^ pp7[15] ^ pp8[14];
  assign sigCSA_cry_2[16] = ((pp6[16] & pp7[15])) | ((pp8[14] & ((pp6[16] ^ pp7[15]))));
  assign sigCSA_sum_2[17] = pp6[17] ^ pp7[16] ^ pp8[15];
  assign sigCSA_cry_2[17] = ((pp6[17] & pp7[16])) | ((pp8[15] & ((pp6[17] ^ pp7[16]))));
  assign sigCSA_sum_2[18] = pp6[18] ^ pp7[17] ^ pp8[16];
  assign sigCSA_cry_2[18] = ((pp6[18] & pp7[17])) | ((pp8[16] & ((pp6[18] ^ pp7[17]))));
  assign sigCSA_sum_2[19] = pp6[19] ^ pp7[18] ^ pp8[17];
  assign sigCSA_cry_2[19] = ((pp6[19] & pp7[18])) | ((pp8[17] & ((pp6[19] ^ pp7[18]))));
  assign sigCSA_sum_2[20] = pp6[20] ^ pp7[19] ^ pp8[18];
  assign sigCSA_cry_2[20] = ((pp6[20] & pp7[19])) | ((pp8[18] & ((pp6[20] ^ pp7[19]))));
  assign sigCSA_sum_2[21] = pp6[21] ^ pp7[20] ^ pp8[19];
  assign sigCSA_cry_2[21] = ((pp6[21] & pp7[20])) | ((pp8[19] & ((pp6[21] ^ pp7[20]))));
  assign sigCSA_sum_2[22] = pp6[22] ^ pp7[21] ^ pp8[20];
  assign sigCSA_cry_2[22] = ((pp6[22] & pp7[21])) | ((pp8[20] & ((pp6[22] ^ pp7[21]))));
  assign sigCSA_sum_2[23] = pp6[23] ^ pp7[22] ^ pp8[21];
  assign sigCSA_cry_2[23] = ((pp6[23] & pp7[22])) | ((pp8[21] & ((pp6[23] ^ pp7[22]))));
  assign sigCSA_sum_2[24] = 1'b 0 ^ pp7[23] ^ pp8[22];
  assign sigCSA_cry_2[24] = ((1'b 0 & pp7[23])) | ((pp8[22] & ((1'b 0 ^ pp7[23]))));
  assign sigCSA_sum_2[25] = 1'b 0 ^ 1'b 0 ^ pp8[23];
  assign sigCSA_cry_2[25] = ((1'b 0 & 1'b 0)) | ((pp8[23] & ((1'b 0 ^ 1'b 0))));
  // csa : 3
  // generating sigCSA_sum_3 and sigCSA_cry_3
  assign sigCSA_sum_3[0] = pp9[0] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_3[0] = ((pp9[0] & 1'b 0)) | ((1'b 0 & ((pp9[0] ^ 1'b 0))));
  assign sigCSA_sum_3[1] = pp9[1] ^ pp10[0] ^ 1'b 0;
  assign sigCSA_cry_3[1] = ((pp9[1] & pp10[0])) | ((1'b 0 & ((pp9[1] ^ pp10[0]))));
  assign sigCSA_sum_3[2] = pp9[2] ^ pp10[1] ^ pp11[0];
  assign sigCSA_cry_3[2] = ((pp9[2] & pp10[1])) | ((pp11[0] & ((pp9[2] ^ pp10[1]))));
  assign sigCSA_sum_3[3] = pp9[3] ^ pp10[2] ^ pp11[1];
  assign sigCSA_cry_3[3] = ((pp9[3] & pp10[2])) | ((pp11[1] & ((pp9[3] ^ pp10[2]))));
  assign sigCSA_sum_3[4] = pp9[4] ^ pp10[3] ^ pp11[2];
  assign sigCSA_cry_3[4] = ((pp9[4] & pp10[3])) | ((pp11[2] & ((pp9[4] ^ pp10[3]))));
  assign sigCSA_sum_3[5] = pp9[5] ^ pp10[4] ^ pp11[3];
  assign sigCSA_cry_3[5] = ((pp9[5] & pp10[4])) | ((pp11[3] & ((pp9[5] ^ pp10[4]))));
  assign sigCSA_sum_3[6] = pp9[6] ^ pp10[5] ^ pp11[4];
  assign sigCSA_cry_3[6] = ((pp9[6] & pp10[5])) | ((pp11[4] & ((pp9[6] ^ pp10[5]))));
  assign sigCSA_sum_3[7] = pp9[7] ^ pp10[6] ^ pp11[5];
  assign sigCSA_cry_3[7] = ((pp9[7] & pp10[6])) | ((pp11[5] & ((pp9[7] ^ pp10[6]))));
  assign sigCSA_sum_3[8] = pp9[8] ^ pp10[7] ^ pp11[6];
  assign sigCSA_cry_3[8] = ((pp9[8] & pp10[7])) | ((pp11[6] & ((pp9[8] ^ pp10[7]))));
  assign sigCSA_sum_3[9] = pp9[9] ^ pp10[8] ^ pp11[7];
  assign sigCSA_cry_3[9] = ((pp9[9] & pp10[8])) | ((pp11[7] & ((pp9[9] ^ pp10[8]))));
  assign sigCSA_sum_3[10] = pp9[10] ^ pp10[9] ^ pp11[8];
  assign sigCSA_cry_3[10] = ((pp9[10] & pp10[9])) | ((pp11[8] & ((pp9[10] ^ pp10[9]))));
  assign sigCSA_sum_3[11] = pp9[11] ^ pp10[10] ^ pp11[9];
  assign sigCSA_cry_3[11] = ((pp9[11] & pp10[10])) | ((pp11[9] & ((pp9[11] ^ pp10[10]))));
  assign sigCSA_sum_3[12] = pp9[12] ^ pp10[11] ^ pp11[10];
  assign sigCSA_cry_3[12] = ((pp9[12] & pp10[11])) | ((pp11[10] & ((pp9[12] ^ pp10[11]))));
  assign sigCSA_sum_3[13] = pp9[13] ^ pp10[12] ^ pp11[11];
  assign sigCSA_cry_3[13] = ((pp9[13] & pp10[12])) | ((pp11[11] & ((pp9[13] ^ pp10[12]))));
  assign sigCSA_sum_3[14] = pp9[14] ^ pp10[13] ^ pp11[12];
  assign sigCSA_cry_3[14] = ((pp9[14] & pp10[13])) | ((pp11[12] & ((pp9[14] ^ pp10[13]))));
  assign sigCSA_sum_3[15] = pp9[15] ^ pp10[14] ^ pp11[13];
  assign sigCSA_cry_3[15] = ((pp9[15] & pp10[14])) | ((pp11[13] & ((pp9[15] ^ pp10[14]))));
  assign sigCSA_sum_3[16] = pp9[16] ^ pp10[15] ^ pp11[14];
  assign sigCSA_cry_3[16] = ((pp9[16] & pp10[15])) | ((pp11[14] & ((pp9[16] ^ pp10[15]))));
  assign sigCSA_sum_3[17] = pp9[17] ^ pp10[16] ^ pp11[15];
  assign sigCSA_cry_3[17] = ((pp9[17] & pp10[16])) | ((pp11[15] & ((pp9[17] ^ pp10[16]))));
  assign sigCSA_sum_3[18] = pp9[18] ^ pp10[17] ^ pp11[16];
  assign sigCSA_cry_3[18] = ((pp9[18] & pp10[17])) | ((pp11[16] & ((pp9[18] ^ pp10[17]))));
  assign sigCSA_sum_3[19] = pp9[19] ^ pp10[18] ^ pp11[17];
  assign sigCSA_cry_3[19] = ((pp9[19] & pp10[18])) | ((pp11[17] & ((pp9[19] ^ pp10[18]))));
  assign sigCSA_sum_3[20] = pp9[20] ^ pp10[19] ^ pp11[18];
  assign sigCSA_cry_3[20] = ((pp9[20] & pp10[19])) | ((pp11[18] & ((pp9[20] ^ pp10[19]))));
  assign sigCSA_sum_3[21] = pp9[21] ^ pp10[20] ^ pp11[19];
  assign sigCSA_cry_3[21] = ((pp9[21] & pp10[20])) | ((pp11[19] & ((pp9[21] ^ pp10[20]))));
  assign sigCSA_sum_3[22] = pp9[22] ^ pp10[21] ^ pp11[20];
  assign sigCSA_cry_3[22] = ((pp9[22] & pp10[21])) | ((pp11[20] & ((pp9[22] ^ pp10[21]))));
  assign sigCSA_sum_3[23] = pp9[23] ^ pp10[22] ^ pp11[21];
  assign sigCSA_cry_3[23] = ((pp9[23] & pp10[22])) | ((pp11[21] & ((pp9[23] ^ pp10[22]))));
  assign sigCSA_sum_3[24] = 1'b 0 ^ pp10[23] ^ pp11[22];
  assign sigCSA_cry_3[24] = ((1'b 0 & pp10[23])) | ((pp11[22] & ((1'b 0 ^ pp10[23]))));
  assign sigCSA_sum_3[25] = 1'b 0 ^ 1'b 0 ^ pp11[23];
  assign sigCSA_cry_3[25] = ((1'b 0 & 1'b 0)) | ((pp11[23] & ((1'b 0 ^ 1'b 0))));
  // csa : 4
  // generating sigCSA_sum_4 and sigCSA_cry_4
  assign sigCSA_sum_4[0] = pp12[0] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_4[0] = ((pp12[0] & 1'b 0)) | ((1'b 0 & ((pp12[0] ^ 1'b 0))));
  assign sigCSA_sum_4[1] = pp12[1] ^ pp13[0] ^ 1'b 0;
  assign sigCSA_cry_4[1] = ((pp12[1] & pp13[0])) | ((1'b 0 & ((pp12[1] ^ pp13[0]))));
  assign sigCSA_sum_4[2] = pp12[2] ^ pp13[1] ^ pp14[0];
  assign sigCSA_cry_4[2] = ((pp12[2] & pp13[1])) | ((pp14[0] & ((pp12[2] ^ pp13[1]))));
  assign sigCSA_sum_4[3] = pp12[3] ^ pp13[2] ^ pp14[1];
  assign sigCSA_cry_4[3] = ((pp12[3] & pp13[2])) | ((pp14[1] & ((pp12[3] ^ pp13[2]))));
  assign sigCSA_sum_4[4] = pp12[4] ^ pp13[3] ^ pp14[2];
  assign sigCSA_cry_4[4] = ((pp12[4] & pp13[3])) | ((pp14[2] & ((pp12[4] ^ pp13[3]))));
  assign sigCSA_sum_4[5] = pp12[5] ^ pp13[4] ^ pp14[3];
  assign sigCSA_cry_4[5] = ((pp12[5] & pp13[4])) | ((pp14[3] & ((pp12[5] ^ pp13[4]))));
  assign sigCSA_sum_4[6] = pp12[6] ^ pp13[5] ^ pp14[4];
  assign sigCSA_cry_4[6] = ((pp12[6] & pp13[5])) | ((pp14[4] & ((pp12[6] ^ pp13[5]))));
  assign sigCSA_sum_4[7] = pp12[7] ^ pp13[6] ^ pp14[5];
  assign sigCSA_cry_4[7] = ((pp12[7] & pp13[6])) | ((pp14[5] & ((pp12[7] ^ pp13[6]))));
  assign sigCSA_sum_4[8] = pp12[8] ^ pp13[7] ^ pp14[6];
  assign sigCSA_cry_4[8] = ((pp12[8] & pp13[7])) | ((pp14[6] & ((pp12[8] ^ pp13[7]))));
  assign sigCSA_sum_4[9] = pp12[9] ^ pp13[8] ^ pp14[7];
  assign sigCSA_cry_4[9] = ((pp12[9] & pp13[8])) | ((pp14[7] & ((pp12[9] ^ pp13[8]))));
  assign sigCSA_sum_4[10] = pp12[10] ^ pp13[9] ^ pp14[8];
  assign sigCSA_cry_4[10] = ((pp12[10] & pp13[9])) | ((pp14[8] & ((pp12[10] ^ pp13[9]))));
  assign sigCSA_sum_4[11] = pp12[11] ^ pp13[10] ^ pp14[9];
  assign sigCSA_cry_4[11] = ((pp12[11] & pp13[10])) | ((pp14[9] & ((pp12[11] ^ pp13[10]))));
  assign sigCSA_sum_4[12] = pp12[12] ^ pp13[11] ^ pp14[10];
  assign sigCSA_cry_4[12] = ((pp12[12] & pp13[11])) | ((pp14[10] & ((pp12[12] ^ pp13[11]))));
  assign sigCSA_sum_4[13] = pp12[13] ^ pp13[12] ^ pp14[11];
  assign sigCSA_cry_4[13] = ((pp12[13] & pp13[12])) | ((pp14[11] & ((pp12[13] ^ pp13[12]))));
  assign sigCSA_sum_4[14] = pp12[14] ^ pp13[13] ^ pp14[12];
  assign sigCSA_cry_4[14] = ((pp12[14] & pp13[13])) | ((pp14[12] & ((pp12[14] ^ pp13[13]))));
  assign sigCSA_sum_4[15] = pp12[15] ^ pp13[14] ^ pp14[13];
  assign sigCSA_cry_4[15] = ((pp12[15] & pp13[14])) | ((pp14[13] & ((pp12[15] ^ pp13[14]))));
  assign sigCSA_sum_4[16] = pp12[16] ^ pp13[15] ^ pp14[14];
  assign sigCSA_cry_4[16] = ((pp12[16] & pp13[15])) | ((pp14[14] & ((pp12[16] ^ pp13[15]))));
  assign sigCSA_sum_4[17] = pp12[17] ^ pp13[16] ^ pp14[15];
  assign sigCSA_cry_4[17] = ((pp12[17] & pp13[16])) | ((pp14[15] & ((pp12[17] ^ pp13[16]))));
  assign sigCSA_sum_4[18] = pp12[18] ^ pp13[17] ^ pp14[16];
  assign sigCSA_cry_4[18] = ((pp12[18] & pp13[17])) | ((pp14[16] & ((pp12[18] ^ pp13[17]))));
  assign sigCSA_sum_4[19] = pp12[19] ^ pp13[18] ^ pp14[17];
  assign sigCSA_cry_4[19] = ((pp12[19] & pp13[18])) | ((pp14[17] & ((pp12[19] ^ pp13[18]))));
  assign sigCSA_sum_4[20] = pp12[20] ^ pp13[19] ^ pp14[18];
  assign sigCSA_cry_4[20] = ((pp12[20] & pp13[19])) | ((pp14[18] & ((pp12[20] ^ pp13[19]))));
  assign sigCSA_sum_4[21] = pp12[21] ^ pp13[20] ^ pp14[19];
  assign sigCSA_cry_4[21] = ((pp12[21] & pp13[20])) | ((pp14[19] & ((pp12[21] ^ pp13[20]))));
  assign sigCSA_sum_4[22] = pp12[22] ^ pp13[21] ^ pp14[20];
  assign sigCSA_cry_4[22] = ((pp12[22] & pp13[21])) | ((pp14[20] & ((pp12[22] ^ pp13[21]))));
  assign sigCSA_sum_4[23] = pp12[23] ^ pp13[22] ^ pp14[21];
  assign sigCSA_cry_4[23] = ((pp12[23] & pp13[22])) | ((pp14[21] & ((pp12[23] ^ pp13[22]))));
  assign sigCSA_sum_4[24] = 1'b 0 ^ pp13[23] ^ pp14[22];
  assign sigCSA_cry_4[24] = ((1'b 0 & pp13[23])) | ((pp14[22] & ((1'b 0 ^ pp13[23]))));
  assign sigCSA_sum_4[25] = 1'b 0 ^ 1'b 0 ^ pp14[23];
  assign sigCSA_cry_4[25] = ((1'b 0 & 1'b 0)) | ((pp14[23] & ((1'b 0 ^ 1'b 0))));
  // csa : 5
  // generating sigCSA_sum_5 and sigCSA_cry_5
  assign sigCSA_sum_5[0] = pp15[0] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_5[0] = ((pp15[0] & 1'b 0)) | ((1'b 0 & ((pp15[0] ^ 1'b 0))));
  assign sigCSA_sum_5[1] = pp15[1] ^ pp16[0] ^ 1'b 0;
  assign sigCSA_cry_5[1] = ((pp15[1] & pp16[0])) | ((1'b 0 & ((pp15[1] ^ pp16[0]))));
  assign sigCSA_sum_5[2] = pp15[2] ^ pp16[1] ^ pp17[0];
  assign sigCSA_cry_5[2] = ((pp15[2] & pp16[1])) | ((pp17[0] & ((pp15[2] ^ pp16[1]))));
  assign sigCSA_sum_5[3] = pp15[3] ^ pp16[2] ^ pp17[1];
  assign sigCSA_cry_5[3] = ((pp15[3] & pp16[2])) | ((pp17[1] & ((pp15[3] ^ pp16[2]))));
  assign sigCSA_sum_5[4] = pp15[4] ^ pp16[3] ^ pp17[2];
  assign sigCSA_cry_5[4] = ((pp15[4] & pp16[3])) | ((pp17[2] & ((pp15[4] ^ pp16[3]))));
  assign sigCSA_sum_5[5] = pp15[5] ^ pp16[4] ^ pp17[3];
  assign sigCSA_cry_5[5] = ((pp15[5] & pp16[4])) | ((pp17[3] & ((pp15[5] ^ pp16[4]))));
  assign sigCSA_sum_5[6] = pp15[6] ^ pp16[5] ^ pp17[4];
  assign sigCSA_cry_5[6] = ((pp15[6] & pp16[5])) | ((pp17[4] & ((pp15[6] ^ pp16[5]))));
  assign sigCSA_sum_5[7] = pp15[7] ^ pp16[6] ^ pp17[5];
  assign sigCSA_cry_5[7] = ((pp15[7] & pp16[6])) | ((pp17[5] & ((pp15[7] ^ pp16[6]))));
  assign sigCSA_sum_5[8] = pp15[8] ^ pp16[7] ^ pp17[6];
  assign sigCSA_cry_5[8] = ((pp15[8] & pp16[7])) | ((pp17[6] & ((pp15[8] ^ pp16[7]))));
  assign sigCSA_sum_5[9] = pp15[9] ^ pp16[8] ^ pp17[7];
  assign sigCSA_cry_5[9] = ((pp15[9] & pp16[8])) | ((pp17[7] & ((pp15[9] ^ pp16[8]))));
  assign sigCSA_sum_5[10] = pp15[10] ^ pp16[9] ^ pp17[8];
  assign sigCSA_cry_5[10] = ((pp15[10] & pp16[9])) | ((pp17[8] & ((pp15[10] ^ pp16[9]))));
  assign sigCSA_sum_5[11] = pp15[11] ^ pp16[10] ^ pp17[9];
  assign sigCSA_cry_5[11] = ((pp15[11] & pp16[10])) | ((pp17[9] & ((pp15[11] ^ pp16[10]))));
  assign sigCSA_sum_5[12] = pp15[12] ^ pp16[11] ^ pp17[10];
  assign sigCSA_cry_5[12] = ((pp15[12] & pp16[11])) | ((pp17[10] & ((pp15[12] ^ pp16[11]))));
  assign sigCSA_sum_5[13] = pp15[13] ^ pp16[12] ^ pp17[11];
  assign sigCSA_cry_5[13] = ((pp15[13] & pp16[12])) | ((pp17[11] & ((pp15[13] ^ pp16[12]))));
  assign sigCSA_sum_5[14] = pp15[14] ^ pp16[13] ^ pp17[12];
  assign sigCSA_cry_5[14] = ((pp15[14] & pp16[13])) | ((pp17[12] & ((pp15[14] ^ pp16[13]))));
  assign sigCSA_sum_5[15] = pp15[15] ^ pp16[14] ^ pp17[13];
  assign sigCSA_cry_5[15] = ((pp15[15] & pp16[14])) | ((pp17[13] & ((pp15[15] ^ pp16[14]))));
  assign sigCSA_sum_5[16] = pp15[16] ^ pp16[15] ^ pp17[14];
  assign sigCSA_cry_5[16] = ((pp15[16] & pp16[15])) | ((pp17[14] & ((pp15[16] ^ pp16[15]))));
  assign sigCSA_sum_5[17] = pp15[17] ^ pp16[16] ^ pp17[15];
  assign sigCSA_cry_5[17] = ((pp15[17] & pp16[16])) | ((pp17[15] & ((pp15[17] ^ pp16[16]))));
  assign sigCSA_sum_5[18] = pp15[18] ^ pp16[17] ^ pp17[16];
  assign sigCSA_cry_5[18] = ((pp15[18] & pp16[17])) | ((pp17[16] & ((pp15[18] ^ pp16[17]))));
  assign sigCSA_sum_5[19] = pp15[19] ^ pp16[18] ^ pp17[17];
  assign sigCSA_cry_5[19] = ((pp15[19] & pp16[18])) | ((pp17[17] & ((pp15[19] ^ pp16[18]))));
  assign sigCSA_sum_5[20] = pp15[20] ^ pp16[19] ^ pp17[18];
  assign sigCSA_cry_5[20] = ((pp15[20] & pp16[19])) | ((pp17[18] & ((pp15[20] ^ pp16[19]))));
  assign sigCSA_sum_5[21] = pp15[21] ^ pp16[20] ^ pp17[19];
  assign sigCSA_cry_5[21] = ((pp15[21] & pp16[20])) | ((pp17[19] & ((pp15[21] ^ pp16[20]))));
  assign sigCSA_sum_5[22] = pp15[22] ^ pp16[21] ^ pp17[20];
  assign sigCSA_cry_5[22] = ((pp15[22] & pp16[21])) | ((pp17[20] & ((pp15[22] ^ pp16[21]))));
  assign sigCSA_sum_5[23] = pp15[23] ^ pp16[22] ^ pp17[21];
  assign sigCSA_cry_5[23] = ((pp15[23] & pp16[22])) | ((pp17[21] & ((pp15[23] ^ pp16[22]))));
  assign sigCSA_sum_5[24] = 1'b 0 ^ pp16[23] ^ pp17[22];
  assign sigCSA_cry_5[24] = ((1'b 0 & pp16[23])) | ((pp17[22] & ((1'b 0 ^ pp16[23]))));
  assign sigCSA_sum_5[25] = 1'b 0 ^ 1'b 0 ^ pp17[23];
  assign sigCSA_cry_5[25] = ((1'b 0 & 1'b 0)) | ((pp17[23] & ((1'b 0 ^ 1'b 0))));
  // csa : 6
  // generating sigCSA_sum_6 and sigCSA_cry_6
  assign sigCSA_sum_6[0] = pp18[0] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_6[0] = ((pp18[0] & 1'b 0)) | ((1'b 0 & ((pp18[0] ^ 1'b 0))));
  assign sigCSA_sum_6[1] = pp18[1] ^ pp19[0] ^ 1'b 0;
  assign sigCSA_cry_6[1] = ((pp18[1] & pp19[0])) | ((1'b 0 & ((pp18[1] ^ pp19[0]))));
  assign sigCSA_sum_6[2] = pp18[2] ^ pp19[1] ^ pp20[0];
  assign sigCSA_cry_6[2] = ((pp18[2] & pp19[1])) | ((pp20[0] & ((pp18[2] ^ pp19[1]))));
  assign sigCSA_sum_6[3] = pp18[3] ^ pp19[2] ^ pp20[1];
  assign sigCSA_cry_6[3] = ((pp18[3] & pp19[2])) | ((pp20[1] & ((pp18[3] ^ pp19[2]))));
  assign sigCSA_sum_6[4] = pp18[4] ^ pp19[3] ^ pp20[2];
  assign sigCSA_cry_6[4] = ((pp18[4] & pp19[3])) | ((pp20[2] & ((pp18[4] ^ pp19[3]))));
  assign sigCSA_sum_6[5] = pp18[5] ^ pp19[4] ^ pp20[3];
  assign sigCSA_cry_6[5] = ((pp18[5] & pp19[4])) | ((pp20[3] & ((pp18[5] ^ pp19[4]))));
  assign sigCSA_sum_6[6] = pp18[6] ^ pp19[5] ^ pp20[4];
  assign sigCSA_cry_6[6] = ((pp18[6] & pp19[5])) | ((pp20[4] & ((pp18[6] ^ pp19[5]))));
  assign sigCSA_sum_6[7] = pp18[7] ^ pp19[6] ^ pp20[5];
  assign sigCSA_cry_6[7] = ((pp18[7] & pp19[6])) | ((pp20[5] & ((pp18[7] ^ pp19[6]))));
  assign sigCSA_sum_6[8] = pp18[8] ^ pp19[7] ^ pp20[6];
  assign sigCSA_cry_6[8] = ((pp18[8] & pp19[7])) | ((pp20[6] & ((pp18[8] ^ pp19[7]))));
  assign sigCSA_sum_6[9] = pp18[9] ^ pp19[8] ^ pp20[7];
  assign sigCSA_cry_6[9] = ((pp18[9] & pp19[8])) | ((pp20[7] & ((pp18[9] ^ pp19[8]))));
  assign sigCSA_sum_6[10] = pp18[10] ^ pp19[9] ^ pp20[8];
  assign sigCSA_cry_6[10] = ((pp18[10] & pp19[9])) | ((pp20[8] & ((pp18[10] ^ pp19[9]))));
  assign sigCSA_sum_6[11] = pp18[11] ^ pp19[10] ^ pp20[9];
  assign sigCSA_cry_6[11] = ((pp18[11] & pp19[10])) | ((pp20[9] & ((pp18[11] ^ pp19[10]))));
  assign sigCSA_sum_6[12] = pp18[12] ^ pp19[11] ^ pp20[10];
  assign sigCSA_cry_6[12] = ((pp18[12] & pp19[11])) | ((pp20[10] & ((pp18[12] ^ pp19[11]))));
  assign sigCSA_sum_6[13] = pp18[13] ^ pp19[12] ^ pp20[11];
  assign sigCSA_cry_6[13] = ((pp18[13] & pp19[12])) | ((pp20[11] & ((pp18[13] ^ pp19[12]))));
  assign sigCSA_sum_6[14] = pp18[14] ^ pp19[13] ^ pp20[12];
  assign sigCSA_cry_6[14] = ((pp18[14] & pp19[13])) | ((pp20[12] & ((pp18[14] ^ pp19[13]))));
  assign sigCSA_sum_6[15] = pp18[15] ^ pp19[14] ^ pp20[13];
  assign sigCSA_cry_6[15] = ((pp18[15] & pp19[14])) | ((pp20[13] & ((pp18[15] ^ pp19[14]))));
  assign sigCSA_sum_6[16] = pp18[16] ^ pp19[15] ^ pp20[14];
  assign sigCSA_cry_6[16] = ((pp18[16] & pp19[15])) | ((pp20[14] & ((pp18[16] ^ pp19[15]))));
  assign sigCSA_sum_6[17] = pp18[17] ^ pp19[16] ^ pp20[15];
  assign sigCSA_cry_6[17] = ((pp18[17] & pp19[16])) | ((pp20[15] & ((pp18[17] ^ pp19[16]))));
  assign sigCSA_sum_6[18] = pp18[18] ^ pp19[17] ^ pp20[16];
  assign sigCSA_cry_6[18] = ((pp18[18] & pp19[17])) | ((pp20[16] & ((pp18[18] ^ pp19[17]))));
  assign sigCSA_sum_6[19] = pp18[19] ^ pp19[18] ^ pp20[17];
  assign sigCSA_cry_6[19] = ((pp18[19] & pp19[18])) | ((pp20[17] & ((pp18[19] ^ pp19[18]))));
  assign sigCSA_sum_6[20] = pp18[20] ^ pp19[19] ^ pp20[18];
  assign sigCSA_cry_6[20] = ((pp18[20] & pp19[19])) | ((pp20[18] & ((pp18[20] ^ pp19[19]))));
  assign sigCSA_sum_6[21] = pp18[21] ^ pp19[20] ^ pp20[19];
  assign sigCSA_cry_6[21] = ((pp18[21] & pp19[20])) | ((pp20[19] & ((pp18[21] ^ pp19[20]))));
  assign sigCSA_sum_6[22] = pp18[22] ^ pp19[21] ^ pp20[20];
  assign sigCSA_cry_6[22] = ((pp18[22] & pp19[21])) | ((pp20[20] & ((pp18[22] ^ pp19[21]))));
  assign sigCSA_sum_6[23] = pp18[23] ^ pp19[22] ^ pp20[21];
  assign sigCSA_cry_6[23] = ((pp18[23] & pp19[22])) | ((pp20[21] & ((pp18[23] ^ pp19[22]))));
  assign sigCSA_sum_6[24] = 1'b 0 ^ pp19[23] ^ pp20[22];
  assign sigCSA_cry_6[24] = ((1'b 0 & pp19[23])) | ((pp20[22] & ((1'b 0 ^ pp19[23]))));
  assign sigCSA_sum_6[25] = 1'b 0 ^ 1'b 0 ^ pp20[23];
  assign sigCSA_cry_6[25] = ((1'b 0 & 1'b 0)) | ((pp20[23] & ((1'b 0 ^ 1'b 0))));
  // csa : 7
  // generating sigCSA_sum_7 and sigCSA_cry_7
  assign sigCSA_sum_7[0] = pp21[0] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_7[0] = ((pp21[0] & 1'b 0)) | ((1'b 0 & ((pp21[0] ^ 1'b 0))));
  assign sigCSA_sum_7[1] = pp21[1] ^ pp22[0] ^ 1'b 0;
  assign sigCSA_cry_7[1] = ((pp21[1] & pp22[0])) | ((1'b 0 & ((pp21[1] ^ pp22[0]))));
  assign sigCSA_sum_7[2] = pp21[2] ^ pp22[1] ^ pp23[0];
  assign sigCSA_cry_7[2] = ((pp21[2] & pp22[1])) | ((pp23[0] & ((pp21[2] ^ pp22[1]))));
  assign sigCSA_sum_7[3] = pp21[3] ^ pp22[2] ^ pp23[1];
  assign sigCSA_cry_7[3] = ((pp21[3] & pp22[2])) | ((pp23[1] & ((pp21[3] ^ pp22[2]))));
  assign sigCSA_sum_7[4] = pp21[4] ^ pp22[3] ^ pp23[2];
  assign sigCSA_cry_7[4] = ((pp21[4] & pp22[3])) | ((pp23[2] & ((pp21[4] ^ pp22[3]))));
  assign sigCSA_sum_7[5] = pp21[5] ^ pp22[4] ^ pp23[3];
  assign sigCSA_cry_7[5] = ((pp21[5] & pp22[4])) | ((pp23[3] & ((pp21[5] ^ pp22[4]))));
  assign sigCSA_sum_7[6] = pp21[6] ^ pp22[5] ^ pp23[4];
  assign sigCSA_cry_7[6] = ((pp21[6] & pp22[5])) | ((pp23[4] & ((pp21[6] ^ pp22[5]))));
  assign sigCSA_sum_7[7] = pp21[7] ^ pp22[6] ^ pp23[5];
  assign sigCSA_cry_7[7] = ((pp21[7] & pp22[6])) | ((pp23[5] & ((pp21[7] ^ pp22[6]))));
  assign sigCSA_sum_7[8] = pp21[8] ^ pp22[7] ^ pp23[6];
  assign sigCSA_cry_7[8] = ((pp21[8] & pp22[7])) | ((pp23[6] & ((pp21[8] ^ pp22[7]))));
  assign sigCSA_sum_7[9] = pp21[9] ^ pp22[8] ^ pp23[7];
  assign sigCSA_cry_7[9] = ((pp21[9] & pp22[8])) | ((pp23[7] & ((pp21[9] ^ pp22[8]))));
  assign sigCSA_sum_7[10] = pp21[10] ^ pp22[9] ^ pp23[8];
  assign sigCSA_cry_7[10] = ((pp21[10] & pp22[9])) | ((pp23[8] & ((pp21[10] ^ pp22[9]))));
  assign sigCSA_sum_7[11] = pp21[11] ^ pp22[10] ^ pp23[9];
  assign sigCSA_cry_7[11] = ((pp21[11] & pp22[10])) | ((pp23[9] & ((pp21[11] ^ pp22[10]))));
  assign sigCSA_sum_7[12] = pp21[12] ^ pp22[11] ^ pp23[10];
  assign sigCSA_cry_7[12] = ((pp21[12] & pp22[11])) | ((pp23[10] & ((pp21[12] ^ pp22[11]))));
  assign sigCSA_sum_7[13] = pp21[13] ^ pp22[12] ^ pp23[11];
  assign sigCSA_cry_7[13] = ((pp21[13] & pp22[12])) | ((pp23[11] & ((pp21[13] ^ pp22[12]))));
  assign sigCSA_sum_7[14] = pp21[14] ^ pp22[13] ^ pp23[12];
  assign sigCSA_cry_7[14] = ((pp21[14] & pp22[13])) | ((pp23[12] & ((pp21[14] ^ pp22[13]))));
  assign sigCSA_sum_7[15] = pp21[15] ^ pp22[14] ^ pp23[13];
  assign sigCSA_cry_7[15] = ((pp21[15] & pp22[14])) | ((pp23[13] & ((pp21[15] ^ pp22[14]))));
  assign sigCSA_sum_7[16] = pp21[16] ^ pp22[15] ^ pp23[14];
  assign sigCSA_cry_7[16] = ((pp21[16] & pp22[15])) | ((pp23[14] & ((pp21[16] ^ pp22[15]))));
  assign sigCSA_sum_7[17] = pp21[17] ^ pp22[16] ^ pp23[15];
  assign sigCSA_cry_7[17] = ((pp21[17] & pp22[16])) | ((pp23[15] & ((pp21[17] ^ pp22[16]))));
  assign sigCSA_sum_7[18] = pp21[18] ^ pp22[17] ^ pp23[16];
  assign sigCSA_cry_7[18] = ((pp21[18] & pp22[17])) | ((pp23[16] & ((pp21[18] ^ pp22[17]))));
  assign sigCSA_sum_7[19] = pp21[19] ^ pp22[18] ^ pp23[17];
  assign sigCSA_cry_7[19] = ((pp21[19] & pp22[18])) | ((pp23[17] & ((pp21[19] ^ pp22[18]))));
  assign sigCSA_sum_7[20] = pp21[20] ^ pp22[19] ^ pp23[18];
  assign sigCSA_cry_7[20] = ((pp21[20] & pp22[19])) | ((pp23[18] & ((pp21[20] ^ pp22[19]))));
  assign sigCSA_sum_7[21] = pp21[21] ^ pp22[20] ^ pp23[19];
  assign sigCSA_cry_7[21] = ((pp21[21] & pp22[20])) | ((pp23[19] & ((pp21[21] ^ pp22[20]))));
  assign sigCSA_sum_7[22] = pp21[22] ^ pp22[21] ^ pp23[20];
  assign sigCSA_cry_7[22] = ((pp21[22] & pp22[21])) | ((pp23[20] & ((pp21[22] ^ pp22[21]))));
  assign sigCSA_sum_7[23] = pp21[23] ^ pp22[22] ^ pp23[21];
  assign sigCSA_cry_7[23] = ((pp21[23] & pp22[22])) | ((pp23[21] & ((pp21[23] ^ pp22[22]))));
  assign sigCSA_sum_7[24] = 1'b 0 ^ pp22[23] ^ pp23[22];
  assign sigCSA_cry_7[24] = ((1'b 0 & pp22[23])) | ((pp23[22] & ((1'b 0 ^ pp22[23]))));
  assign sigCSA_sum_7[25] = 1'b 0 ^ 1'b 0 ^ pp23[23];
  assign sigCSA_cry_7[25] = ((1'b 0 & 1'b 0)) | ((pp23[23] & ((1'b 0 ^ 1'b 0))));
  // csa : 8
  // generating sigCSA_sum_8 and sigCSA_cry_8
  assign sigCSA_sum_8[0] = sigCSA_sum_0[0] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_8[0] = ((sigCSA_sum_0[0] & 1'b 0)) | ((1'b 0 & ((sigCSA_sum_0[0] ^ 1'b 0))));
  assign sigCSA_sum_8[1] = sigCSA_sum_0[1] ^ sigCSA_cry_0[0] ^ 1'b 0;
  assign sigCSA_cry_8[1] = ((sigCSA_sum_0[1] & sigCSA_cry_0[0])) | ((1'b 0 & ((sigCSA_sum_0[1] ^ sigCSA_cry_0[0]))));
  assign sigCSA_sum_8[2] = sigCSA_sum_0[2] ^ sigCSA_cry_0[1] ^ 1'b 0;
  assign sigCSA_cry_8[2] = ((sigCSA_sum_0[2] & sigCSA_cry_0[1])) | ((1'b 0 & ((sigCSA_sum_0[2] ^ sigCSA_cry_0[1]))));
  assign sigCSA_sum_8[3] = sigCSA_sum_0[3] ^ sigCSA_cry_0[2] ^ sigCSA_sum_1[0];
  assign sigCSA_cry_8[3] = ((sigCSA_sum_0[3] & sigCSA_cry_0[2])) | ((sigCSA_sum_1[0] & ((sigCSA_sum_0[3] ^ sigCSA_cry_0[2]))));
  assign sigCSA_sum_8[4] = sigCSA_sum_0[4] ^ sigCSA_cry_0[3] ^ sigCSA_sum_1[1];
  assign sigCSA_cry_8[4] = ((sigCSA_sum_0[4] & sigCSA_cry_0[3])) | ((sigCSA_sum_1[1] & ((sigCSA_sum_0[4] ^ sigCSA_cry_0[3]))));
  assign sigCSA_sum_8[5] = sigCSA_sum_0[5] ^ sigCSA_cry_0[4] ^ sigCSA_sum_1[2];
  assign sigCSA_cry_8[5] = ((sigCSA_sum_0[5] & sigCSA_cry_0[4])) | ((sigCSA_sum_1[2] & ((sigCSA_sum_0[5] ^ sigCSA_cry_0[4]))));
  assign sigCSA_sum_8[6] = sigCSA_sum_0[6] ^ sigCSA_cry_0[5] ^ sigCSA_sum_1[3];
  assign sigCSA_cry_8[6] = ((sigCSA_sum_0[6] & sigCSA_cry_0[5])) | ((sigCSA_sum_1[3] & ((sigCSA_sum_0[6] ^ sigCSA_cry_0[5]))));
  assign sigCSA_sum_8[7] = sigCSA_sum_0[7] ^ sigCSA_cry_0[6] ^ sigCSA_sum_1[4];
  assign sigCSA_cry_8[7] = ((sigCSA_sum_0[7] & sigCSA_cry_0[6])) | ((sigCSA_sum_1[4] & ((sigCSA_sum_0[7] ^ sigCSA_cry_0[6]))));
  assign sigCSA_sum_8[8] = sigCSA_sum_0[8] ^ sigCSA_cry_0[7] ^ sigCSA_sum_1[5];
  assign sigCSA_cry_8[8] = ((sigCSA_sum_0[8] & sigCSA_cry_0[7])) | ((sigCSA_sum_1[5] & ((sigCSA_sum_0[8] ^ sigCSA_cry_0[7]))));
  assign sigCSA_sum_8[9] = sigCSA_sum_0[9] ^ sigCSA_cry_0[8] ^ sigCSA_sum_1[6];
  assign sigCSA_cry_8[9] = ((sigCSA_sum_0[9] & sigCSA_cry_0[8])) | ((sigCSA_sum_1[6] & ((sigCSA_sum_0[9] ^ sigCSA_cry_0[8]))));
  assign sigCSA_sum_8[10] = sigCSA_sum_0[10] ^ sigCSA_cry_0[9] ^ sigCSA_sum_1[7];
  assign sigCSA_cry_8[10] = ((sigCSA_sum_0[10] & sigCSA_cry_0[9])) | ((sigCSA_sum_1[7] & ((sigCSA_sum_0[10] ^ sigCSA_cry_0[9]))));
  assign sigCSA_sum_8[11] = sigCSA_sum_0[11] ^ sigCSA_cry_0[10] ^ sigCSA_sum_1[8];
  assign sigCSA_cry_8[11] = ((sigCSA_sum_0[11] & sigCSA_cry_0[10])) | ((sigCSA_sum_1[8] & ((sigCSA_sum_0[11] ^ sigCSA_cry_0[10]))));
  assign sigCSA_sum_8[12] = sigCSA_sum_0[12] ^ sigCSA_cry_0[11] ^ sigCSA_sum_1[9];
  assign sigCSA_cry_8[12] = ((sigCSA_sum_0[12] & sigCSA_cry_0[11])) | ((sigCSA_sum_1[9] & ((sigCSA_sum_0[12] ^ sigCSA_cry_0[11]))));
  assign sigCSA_sum_8[13] = sigCSA_sum_0[13] ^ sigCSA_cry_0[12] ^ sigCSA_sum_1[10];
  assign sigCSA_cry_8[13] = ((sigCSA_sum_0[13] & sigCSA_cry_0[12])) | ((sigCSA_sum_1[10] & ((sigCSA_sum_0[13] ^ sigCSA_cry_0[12]))));
  assign sigCSA_sum_8[14] = sigCSA_sum_0[14] ^ sigCSA_cry_0[13] ^ sigCSA_sum_1[11];
  assign sigCSA_cry_8[14] = ((sigCSA_sum_0[14] & sigCSA_cry_0[13])) | ((sigCSA_sum_1[11] & ((sigCSA_sum_0[14] ^ sigCSA_cry_0[13]))));
  assign sigCSA_sum_8[15] = sigCSA_sum_0[15] ^ sigCSA_cry_0[14] ^ sigCSA_sum_1[12];
  assign sigCSA_cry_8[15] = ((sigCSA_sum_0[15] & sigCSA_cry_0[14])) | ((sigCSA_sum_1[12] & ((sigCSA_sum_0[15] ^ sigCSA_cry_0[14]))));
  assign sigCSA_sum_8[16] = sigCSA_sum_0[16] ^ sigCSA_cry_0[15] ^ sigCSA_sum_1[13];
  assign sigCSA_cry_8[16] = ((sigCSA_sum_0[16] & sigCSA_cry_0[15])) | ((sigCSA_sum_1[13] & ((sigCSA_sum_0[16] ^ sigCSA_cry_0[15]))));
  assign sigCSA_sum_8[17] = sigCSA_sum_0[17] ^ sigCSA_cry_0[16] ^ sigCSA_sum_1[14];
  assign sigCSA_cry_8[17] = ((sigCSA_sum_0[17] & sigCSA_cry_0[16])) | ((sigCSA_sum_1[14] & ((sigCSA_sum_0[17] ^ sigCSA_cry_0[16]))));
  assign sigCSA_sum_8[18] = sigCSA_sum_0[18] ^ sigCSA_cry_0[17] ^ sigCSA_sum_1[15];
  assign sigCSA_cry_8[18] = ((sigCSA_sum_0[18] & sigCSA_cry_0[17])) | ((sigCSA_sum_1[15] & ((sigCSA_sum_0[18] ^ sigCSA_cry_0[17]))));
  assign sigCSA_sum_8[19] = sigCSA_sum_0[19] ^ sigCSA_cry_0[18] ^ sigCSA_sum_1[16];
  assign sigCSA_cry_8[19] = ((sigCSA_sum_0[19] & sigCSA_cry_0[18])) | ((sigCSA_sum_1[16] & ((sigCSA_sum_0[19] ^ sigCSA_cry_0[18]))));
  assign sigCSA_sum_8[20] = sigCSA_sum_0[20] ^ sigCSA_cry_0[19] ^ sigCSA_sum_1[17];
  assign sigCSA_cry_8[20] = ((sigCSA_sum_0[20] & sigCSA_cry_0[19])) | ((sigCSA_sum_1[17] & ((sigCSA_sum_0[20] ^ sigCSA_cry_0[19]))));
  assign sigCSA_sum_8[21] = sigCSA_sum_0[21] ^ sigCSA_cry_0[20] ^ sigCSA_sum_1[18];
  assign sigCSA_cry_8[21] = ((sigCSA_sum_0[21] & sigCSA_cry_0[20])) | ((sigCSA_sum_1[18] & ((sigCSA_sum_0[21] ^ sigCSA_cry_0[20]))));
  assign sigCSA_sum_8[22] = sigCSA_sum_0[22] ^ sigCSA_cry_0[21] ^ sigCSA_sum_1[19];
  assign sigCSA_cry_8[22] = ((sigCSA_sum_0[22] & sigCSA_cry_0[21])) | ((sigCSA_sum_1[19] & ((sigCSA_sum_0[22] ^ sigCSA_cry_0[21]))));
  assign sigCSA_sum_8[23] = sigCSA_sum_0[23] ^ sigCSA_cry_0[22] ^ sigCSA_sum_1[20];
  assign sigCSA_cry_8[23] = ((sigCSA_sum_0[23] & sigCSA_cry_0[22])) | ((sigCSA_sum_1[20] & ((sigCSA_sum_0[23] ^ sigCSA_cry_0[22]))));
  assign sigCSA_sum_8[24] = sigCSA_sum_0[24] ^ sigCSA_cry_0[23] ^ sigCSA_sum_1[21];
  assign sigCSA_cry_8[24] = ((sigCSA_sum_0[24] & sigCSA_cry_0[23])) | ((sigCSA_sum_1[21] & ((sigCSA_sum_0[24] ^ sigCSA_cry_0[23]))));
  assign sigCSA_sum_8[25] = sigCSA_sum_0[25] ^ sigCSA_cry_0[24] ^ sigCSA_sum_1[22];
  assign sigCSA_cry_8[25] = ((sigCSA_sum_0[25] & sigCSA_cry_0[24])) | ((sigCSA_sum_1[22] & ((sigCSA_sum_0[25] ^ sigCSA_cry_0[24]))));
  assign sigCSA_sum_8[26] = 1'b 0 ^ sigCSA_cry_0[25] ^ sigCSA_sum_1[23];
  assign sigCSA_cry_8[26] = ((1'b 0 & sigCSA_cry_0[25])) | ((sigCSA_sum_1[23] & ((1'b 0 ^ sigCSA_cry_0[25]))));
  assign sigCSA_sum_8[27] = 1'b 0 ^ 1'b 0 ^ sigCSA_sum_1[24];
  assign sigCSA_cry_8[27] = ((1'b 0 & 1'b 0)) | ((sigCSA_sum_1[24] & ((1'b 0 ^ 1'b 0))));
  assign sigCSA_sum_8[28] = 1'b 0 ^ 1'b 0 ^ sigCSA_sum_1[25];
  assign sigCSA_cry_8[28] = ((1'b 0 & 1'b 0)) | ((sigCSA_sum_1[25] & ((1'b 0 ^ 1'b 0))));
  // csa : 9
  // generating sigCSA_sum_9 and sigCSA_cry_9
  assign sigCSA_sum_9[0] = sigCSA_cry_1[0] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_9[0] = ((sigCSA_cry_1[0] & 1'b 0)) | ((1'b 0 & ((sigCSA_cry_1[0] ^ 1'b 0))));
  assign sigCSA_sum_9[1] = sigCSA_cry_1[1] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_9[1] = ((sigCSA_cry_1[1] & 1'b 0)) | ((1'b 0 & ((sigCSA_cry_1[1] ^ 1'b 0))));
  assign sigCSA_sum_9[2] = sigCSA_cry_1[2] ^ sigCSA_sum_2[0] ^ 1'b 0;
  assign sigCSA_cry_9[2] = ((sigCSA_cry_1[2] & sigCSA_sum_2[0])) | ((1'b 0 & ((sigCSA_cry_1[2] ^ sigCSA_sum_2[0]))));
  assign sigCSA_sum_9[3] = sigCSA_cry_1[3] ^ sigCSA_sum_2[1] ^ sigCSA_cry_2[0];
  assign sigCSA_cry_9[3] = ((sigCSA_cry_1[3] & sigCSA_sum_2[1])) | ((sigCSA_cry_2[0] & ((sigCSA_cry_1[3] ^ sigCSA_sum_2[1]))));
  assign sigCSA_sum_9[4] = sigCSA_cry_1[4] ^ sigCSA_sum_2[2] ^ sigCSA_cry_2[1];
  assign sigCSA_cry_9[4] = ((sigCSA_cry_1[4] & sigCSA_sum_2[2])) | ((sigCSA_cry_2[1] & ((sigCSA_cry_1[4] ^ sigCSA_sum_2[2]))));
  assign sigCSA_sum_9[5] = sigCSA_cry_1[5] ^ sigCSA_sum_2[3] ^ sigCSA_cry_2[2];
  assign sigCSA_cry_9[5] = ((sigCSA_cry_1[5] & sigCSA_sum_2[3])) | ((sigCSA_cry_2[2] & ((sigCSA_cry_1[5] ^ sigCSA_sum_2[3]))));
  assign sigCSA_sum_9[6] = sigCSA_cry_1[6] ^ sigCSA_sum_2[4] ^ sigCSA_cry_2[3];
  assign sigCSA_cry_9[6] = ((sigCSA_cry_1[6] & sigCSA_sum_2[4])) | ((sigCSA_cry_2[3] & ((sigCSA_cry_1[6] ^ sigCSA_sum_2[4]))));
  assign sigCSA_sum_9[7] = sigCSA_cry_1[7] ^ sigCSA_sum_2[5] ^ sigCSA_cry_2[4];
  assign sigCSA_cry_9[7] = ((sigCSA_cry_1[7] & sigCSA_sum_2[5])) | ((sigCSA_cry_2[4] & ((sigCSA_cry_1[7] ^ sigCSA_sum_2[5]))));
  assign sigCSA_sum_9[8] = sigCSA_cry_1[8] ^ sigCSA_sum_2[6] ^ sigCSA_cry_2[5];
  assign sigCSA_cry_9[8] = ((sigCSA_cry_1[8] & sigCSA_sum_2[6])) | ((sigCSA_cry_2[5] & ((sigCSA_cry_1[8] ^ sigCSA_sum_2[6]))));
  assign sigCSA_sum_9[9] = sigCSA_cry_1[9] ^ sigCSA_sum_2[7] ^ sigCSA_cry_2[6];
  assign sigCSA_cry_9[9] = ((sigCSA_cry_1[9] & sigCSA_sum_2[7])) | ((sigCSA_cry_2[6] & ((sigCSA_cry_1[9] ^ sigCSA_sum_2[7]))));
  assign sigCSA_sum_9[10] = sigCSA_cry_1[10] ^ sigCSA_sum_2[8] ^ sigCSA_cry_2[7];
  assign sigCSA_cry_9[10] = ((sigCSA_cry_1[10] & sigCSA_sum_2[8])) | ((sigCSA_cry_2[7] & ((sigCSA_cry_1[10] ^ sigCSA_sum_2[8]))));
  assign sigCSA_sum_9[11] = sigCSA_cry_1[11] ^ sigCSA_sum_2[9] ^ sigCSA_cry_2[8];
  assign sigCSA_cry_9[11] = ((sigCSA_cry_1[11] & sigCSA_sum_2[9])) | ((sigCSA_cry_2[8] & ((sigCSA_cry_1[11] ^ sigCSA_sum_2[9]))));
  assign sigCSA_sum_9[12] = sigCSA_cry_1[12] ^ sigCSA_sum_2[10] ^ sigCSA_cry_2[9];
  assign sigCSA_cry_9[12] = ((sigCSA_cry_1[12] & sigCSA_sum_2[10])) | ((sigCSA_cry_2[9] & ((sigCSA_cry_1[12] ^ sigCSA_sum_2[10]))));
  assign sigCSA_sum_9[13] = sigCSA_cry_1[13] ^ sigCSA_sum_2[11] ^ sigCSA_cry_2[10];
  assign sigCSA_cry_9[13] = ((sigCSA_cry_1[13] & sigCSA_sum_2[11])) | ((sigCSA_cry_2[10] & ((sigCSA_cry_1[13] ^ sigCSA_sum_2[11]))));
  assign sigCSA_sum_9[14] = sigCSA_cry_1[14] ^ sigCSA_sum_2[12] ^ sigCSA_cry_2[11];
  assign sigCSA_cry_9[14] = ((sigCSA_cry_1[14] & sigCSA_sum_2[12])) | ((sigCSA_cry_2[11] & ((sigCSA_cry_1[14] ^ sigCSA_sum_2[12]))));
  assign sigCSA_sum_9[15] = sigCSA_cry_1[15] ^ sigCSA_sum_2[13] ^ sigCSA_cry_2[12];
  assign sigCSA_cry_9[15] = ((sigCSA_cry_1[15] & sigCSA_sum_2[13])) | ((sigCSA_cry_2[12] & ((sigCSA_cry_1[15] ^ sigCSA_sum_2[13]))));
  assign sigCSA_sum_9[16] = sigCSA_cry_1[16] ^ sigCSA_sum_2[14] ^ sigCSA_cry_2[13];
  assign sigCSA_cry_9[16] = ((sigCSA_cry_1[16] & sigCSA_sum_2[14])) | ((sigCSA_cry_2[13] & ((sigCSA_cry_1[16] ^ sigCSA_sum_2[14]))));
  assign sigCSA_sum_9[17] = sigCSA_cry_1[17] ^ sigCSA_sum_2[15] ^ sigCSA_cry_2[14];
  assign sigCSA_cry_9[17] = ((sigCSA_cry_1[17] & sigCSA_sum_2[15])) | ((sigCSA_cry_2[14] & ((sigCSA_cry_1[17] ^ sigCSA_sum_2[15]))));
  assign sigCSA_sum_9[18] = sigCSA_cry_1[18] ^ sigCSA_sum_2[16] ^ sigCSA_cry_2[15];
  assign sigCSA_cry_9[18] = ((sigCSA_cry_1[18] & sigCSA_sum_2[16])) | ((sigCSA_cry_2[15] & ((sigCSA_cry_1[18] ^ sigCSA_sum_2[16]))));
  assign sigCSA_sum_9[19] = sigCSA_cry_1[19] ^ sigCSA_sum_2[17] ^ sigCSA_cry_2[16];
  assign sigCSA_cry_9[19] = ((sigCSA_cry_1[19] & sigCSA_sum_2[17])) | ((sigCSA_cry_2[16] & ((sigCSA_cry_1[19] ^ sigCSA_sum_2[17]))));
  assign sigCSA_sum_9[20] = sigCSA_cry_1[20] ^ sigCSA_sum_2[18] ^ sigCSA_cry_2[17];
  assign sigCSA_cry_9[20] = ((sigCSA_cry_1[20] & sigCSA_sum_2[18])) | ((sigCSA_cry_2[17] & ((sigCSA_cry_1[20] ^ sigCSA_sum_2[18]))));
  assign sigCSA_sum_9[21] = sigCSA_cry_1[21] ^ sigCSA_sum_2[19] ^ sigCSA_cry_2[18];
  assign sigCSA_cry_9[21] = ((sigCSA_cry_1[21] & sigCSA_sum_2[19])) | ((sigCSA_cry_2[18] & ((sigCSA_cry_1[21] ^ sigCSA_sum_2[19]))));
  assign sigCSA_sum_9[22] = sigCSA_cry_1[22] ^ sigCSA_sum_2[20] ^ sigCSA_cry_2[19];
  assign sigCSA_cry_9[22] = ((sigCSA_cry_1[22] & sigCSA_sum_2[20])) | ((sigCSA_cry_2[19] & ((sigCSA_cry_1[22] ^ sigCSA_sum_2[20]))));
  assign sigCSA_sum_9[23] = sigCSA_cry_1[23] ^ sigCSA_sum_2[21] ^ sigCSA_cry_2[20];
  assign sigCSA_cry_9[23] = ((sigCSA_cry_1[23] & sigCSA_sum_2[21])) | ((sigCSA_cry_2[20] & ((sigCSA_cry_1[23] ^ sigCSA_sum_2[21]))));
  assign sigCSA_sum_9[24] = sigCSA_cry_1[24] ^ sigCSA_sum_2[22] ^ sigCSA_cry_2[21];
  assign sigCSA_cry_9[24] = ((sigCSA_cry_1[24] & sigCSA_sum_2[22])) | ((sigCSA_cry_2[21] & ((sigCSA_cry_1[24] ^ sigCSA_sum_2[22]))));
  assign sigCSA_sum_9[25] = sigCSA_cry_1[25] ^ sigCSA_sum_2[23] ^ sigCSA_cry_2[22];
  assign sigCSA_cry_9[25] = ((sigCSA_cry_1[25] & sigCSA_sum_2[23])) | ((sigCSA_cry_2[22] & ((sigCSA_cry_1[25] ^ sigCSA_sum_2[23]))));
  assign sigCSA_sum_9[26] = 1'b 0 ^ sigCSA_sum_2[24] ^ sigCSA_cry_2[23];
  assign sigCSA_cry_9[26] = ((1'b 0 & sigCSA_sum_2[24])) | ((sigCSA_cry_2[23] & ((1'b 0 ^ sigCSA_sum_2[24]))));
  assign sigCSA_sum_9[27] = 1'b 0 ^ sigCSA_sum_2[25] ^ sigCSA_cry_2[24];
  assign sigCSA_cry_9[27] = ((1'b 0 & sigCSA_sum_2[25])) | ((sigCSA_cry_2[24] & ((1'b 0 ^ sigCSA_sum_2[25]))));
  assign sigCSA_sum_9[28] = 1'b 0 ^ 1'b 0 ^ sigCSA_cry_2[25];
  assign sigCSA_cry_9[28] = ((1'b 0 & 1'b 0)) | ((sigCSA_cry_2[25] & ((1'b 0 ^ 1'b 0))));
  // csa : 10
  // generating sigCSA_sum_10 and sigCSA_cry_10
  assign sigCSA_sum_10[0] = sigCSA_sum_3[0] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_10[0] = ((sigCSA_sum_3[0] & 1'b 0)) | ((1'b 0 & ((sigCSA_sum_3[0] ^ 1'b 0))));
  assign sigCSA_sum_10[1] = sigCSA_sum_3[1] ^ sigCSA_cry_3[0] ^ 1'b 0;
  assign sigCSA_cry_10[1] = ((sigCSA_sum_3[1] & sigCSA_cry_3[0])) | ((1'b 0 & ((sigCSA_sum_3[1] ^ sigCSA_cry_3[0]))));
  assign sigCSA_sum_10[2] = sigCSA_sum_3[2] ^ sigCSA_cry_3[1] ^ 1'b 0;
  assign sigCSA_cry_10[2] = ((sigCSA_sum_3[2] & sigCSA_cry_3[1])) | ((1'b 0 & ((sigCSA_sum_3[2] ^ sigCSA_cry_3[1]))));
  assign sigCSA_sum_10[3] = sigCSA_sum_3[3] ^ sigCSA_cry_3[2] ^ sigCSA_sum_4[0];
  assign sigCSA_cry_10[3] = ((sigCSA_sum_3[3] & sigCSA_cry_3[2])) | ((sigCSA_sum_4[0] & ((sigCSA_sum_3[3] ^ sigCSA_cry_3[2]))));
  assign sigCSA_sum_10[4] = sigCSA_sum_3[4] ^ sigCSA_cry_3[3] ^ sigCSA_sum_4[1];
  assign sigCSA_cry_10[4] = ((sigCSA_sum_3[4] & sigCSA_cry_3[3])) | ((sigCSA_sum_4[1] & ((sigCSA_sum_3[4] ^ sigCSA_cry_3[3]))));
  assign sigCSA_sum_10[5] = sigCSA_sum_3[5] ^ sigCSA_cry_3[4] ^ sigCSA_sum_4[2];
  assign sigCSA_cry_10[5] = ((sigCSA_sum_3[5] & sigCSA_cry_3[4])) | ((sigCSA_sum_4[2] & ((sigCSA_sum_3[5] ^ sigCSA_cry_3[4]))));
  assign sigCSA_sum_10[6] = sigCSA_sum_3[6] ^ sigCSA_cry_3[5] ^ sigCSA_sum_4[3];
  assign sigCSA_cry_10[6] = ((sigCSA_sum_3[6] & sigCSA_cry_3[5])) | ((sigCSA_sum_4[3] & ((sigCSA_sum_3[6] ^ sigCSA_cry_3[5]))));
  assign sigCSA_sum_10[7] = sigCSA_sum_3[7] ^ sigCSA_cry_3[6] ^ sigCSA_sum_4[4];
  assign sigCSA_cry_10[7] = ((sigCSA_sum_3[7] & sigCSA_cry_3[6])) | ((sigCSA_sum_4[4] & ((sigCSA_sum_3[7] ^ sigCSA_cry_3[6]))));
  assign sigCSA_sum_10[8] = sigCSA_sum_3[8] ^ sigCSA_cry_3[7] ^ sigCSA_sum_4[5];
  assign sigCSA_cry_10[8] = ((sigCSA_sum_3[8] & sigCSA_cry_3[7])) | ((sigCSA_sum_4[5] & ((sigCSA_sum_3[8] ^ sigCSA_cry_3[7]))));
  assign sigCSA_sum_10[9] = sigCSA_sum_3[9] ^ sigCSA_cry_3[8] ^ sigCSA_sum_4[6];
  assign sigCSA_cry_10[9] = ((sigCSA_sum_3[9] & sigCSA_cry_3[8])) | ((sigCSA_sum_4[6] & ((sigCSA_sum_3[9] ^ sigCSA_cry_3[8]))));
  assign sigCSA_sum_10[10] = sigCSA_sum_3[10] ^ sigCSA_cry_3[9] ^ sigCSA_sum_4[7];
  assign sigCSA_cry_10[10] = ((sigCSA_sum_3[10] & sigCSA_cry_3[9])) | ((sigCSA_sum_4[7] & ((sigCSA_sum_3[10] ^ sigCSA_cry_3[9]))));
  assign sigCSA_sum_10[11] = sigCSA_sum_3[11] ^ sigCSA_cry_3[10] ^ sigCSA_sum_4[8];
  assign sigCSA_cry_10[11] = ((sigCSA_sum_3[11] & sigCSA_cry_3[10])) | ((sigCSA_sum_4[8] & ((sigCSA_sum_3[11] ^ sigCSA_cry_3[10]))));
  assign sigCSA_sum_10[12] = sigCSA_sum_3[12] ^ sigCSA_cry_3[11] ^ sigCSA_sum_4[9];
  assign sigCSA_cry_10[12] = ((sigCSA_sum_3[12] & sigCSA_cry_3[11])) | ((sigCSA_sum_4[9] & ((sigCSA_sum_3[12] ^ sigCSA_cry_3[11]))));
  assign sigCSA_sum_10[13] = sigCSA_sum_3[13] ^ sigCSA_cry_3[12] ^ sigCSA_sum_4[10];
  assign sigCSA_cry_10[13] = ((sigCSA_sum_3[13] & sigCSA_cry_3[12])) | ((sigCSA_sum_4[10] & ((sigCSA_sum_3[13] ^ sigCSA_cry_3[12]))));
  assign sigCSA_sum_10[14] = sigCSA_sum_3[14] ^ sigCSA_cry_3[13] ^ sigCSA_sum_4[11];
  assign sigCSA_cry_10[14] = ((sigCSA_sum_3[14] & sigCSA_cry_3[13])) | ((sigCSA_sum_4[11] & ((sigCSA_sum_3[14] ^ sigCSA_cry_3[13]))));
  assign sigCSA_sum_10[15] = sigCSA_sum_3[15] ^ sigCSA_cry_3[14] ^ sigCSA_sum_4[12];
  assign sigCSA_cry_10[15] = ((sigCSA_sum_3[15] & sigCSA_cry_3[14])) | ((sigCSA_sum_4[12] & ((sigCSA_sum_3[15] ^ sigCSA_cry_3[14]))));
  assign sigCSA_sum_10[16] = sigCSA_sum_3[16] ^ sigCSA_cry_3[15] ^ sigCSA_sum_4[13];
  assign sigCSA_cry_10[16] = ((sigCSA_sum_3[16] & sigCSA_cry_3[15])) | ((sigCSA_sum_4[13] & ((sigCSA_sum_3[16] ^ sigCSA_cry_3[15]))));
  assign sigCSA_sum_10[17] = sigCSA_sum_3[17] ^ sigCSA_cry_3[16] ^ sigCSA_sum_4[14];
  assign sigCSA_cry_10[17] = ((sigCSA_sum_3[17] & sigCSA_cry_3[16])) | ((sigCSA_sum_4[14] & ((sigCSA_sum_3[17] ^ sigCSA_cry_3[16]))));
  assign sigCSA_sum_10[18] = sigCSA_sum_3[18] ^ sigCSA_cry_3[17] ^ sigCSA_sum_4[15];
  assign sigCSA_cry_10[18] = ((sigCSA_sum_3[18] & sigCSA_cry_3[17])) | ((sigCSA_sum_4[15] & ((sigCSA_sum_3[18] ^ sigCSA_cry_3[17]))));
  assign sigCSA_sum_10[19] = sigCSA_sum_3[19] ^ sigCSA_cry_3[18] ^ sigCSA_sum_4[16];
  assign sigCSA_cry_10[19] = ((sigCSA_sum_3[19] & sigCSA_cry_3[18])) | ((sigCSA_sum_4[16] & ((sigCSA_sum_3[19] ^ sigCSA_cry_3[18]))));
  assign sigCSA_sum_10[20] = sigCSA_sum_3[20] ^ sigCSA_cry_3[19] ^ sigCSA_sum_4[17];
  assign sigCSA_cry_10[20] = ((sigCSA_sum_3[20] & sigCSA_cry_3[19])) | ((sigCSA_sum_4[17] & ((sigCSA_sum_3[20] ^ sigCSA_cry_3[19]))));
  assign sigCSA_sum_10[21] = sigCSA_sum_3[21] ^ sigCSA_cry_3[20] ^ sigCSA_sum_4[18];
  assign sigCSA_cry_10[21] = ((sigCSA_sum_3[21] & sigCSA_cry_3[20])) | ((sigCSA_sum_4[18] & ((sigCSA_sum_3[21] ^ sigCSA_cry_3[20]))));
  assign sigCSA_sum_10[22] = sigCSA_sum_3[22] ^ sigCSA_cry_3[21] ^ sigCSA_sum_4[19];
  assign sigCSA_cry_10[22] = ((sigCSA_sum_3[22] & sigCSA_cry_3[21])) | ((sigCSA_sum_4[19] & ((sigCSA_sum_3[22] ^ sigCSA_cry_3[21]))));
  assign sigCSA_sum_10[23] = sigCSA_sum_3[23] ^ sigCSA_cry_3[22] ^ sigCSA_sum_4[20];
  assign sigCSA_cry_10[23] = ((sigCSA_sum_3[23] & sigCSA_cry_3[22])) | ((sigCSA_sum_4[20] & ((sigCSA_sum_3[23] ^ sigCSA_cry_3[22]))));
  assign sigCSA_sum_10[24] = sigCSA_sum_3[24] ^ sigCSA_cry_3[23] ^ sigCSA_sum_4[21];
  assign sigCSA_cry_10[24] = ((sigCSA_sum_3[24] & sigCSA_cry_3[23])) | ((sigCSA_sum_4[21] & ((sigCSA_sum_3[24] ^ sigCSA_cry_3[23]))));
  assign sigCSA_sum_10[25] = sigCSA_sum_3[25] ^ sigCSA_cry_3[24] ^ sigCSA_sum_4[22];
  assign sigCSA_cry_10[25] = ((sigCSA_sum_3[25] & sigCSA_cry_3[24])) | ((sigCSA_sum_4[22] & ((sigCSA_sum_3[25] ^ sigCSA_cry_3[24]))));
  assign sigCSA_sum_10[26] = 1'b 0 ^ sigCSA_cry_3[25] ^ sigCSA_sum_4[23];
  assign sigCSA_cry_10[26] = ((1'b 0 & sigCSA_cry_3[25])) | ((sigCSA_sum_4[23] & ((1'b 0 ^ sigCSA_cry_3[25]))));
  assign sigCSA_sum_10[27] = 1'b 0 ^ 1'b 0 ^ sigCSA_sum_4[24];
  assign sigCSA_cry_10[27] = ((1'b 0 & 1'b 0)) | ((sigCSA_sum_4[24] & ((1'b 0 ^ 1'b 0))));
  assign sigCSA_sum_10[28] = 1'b 0 ^ 1'b 0 ^ sigCSA_sum_4[25];
  assign sigCSA_cry_10[28] = ((1'b 0 & 1'b 0)) | ((sigCSA_sum_4[25] & ((1'b 0 ^ 1'b 0))));

// csa : 11
  // generating sigCSA_sum_11 and sigCSA_cry_11
  assign sigCSA_sum_11[0] = sigCSA_cry_4[0] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_11[0] = ((sigCSA_cry_4[0] & 1'b 0)) | ((1'b 0 & ((sigCSA_cry_4[0] ^ 1'b 0))));
  assign sigCSA_sum_11[1] = sigCSA_cry_4[1] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_11[1] = ((sigCSA_cry_4[1] & 1'b 0)) | ((1'b 0 & ((sigCSA_cry_4[1] ^ 1'b 0))));
  assign sigCSA_sum_11[2] = sigCSA_cry_4[2] ^ sigCSA_sum_5[0] ^ 1'b 0;
  assign sigCSA_cry_11[2] = ((sigCSA_cry_4[2] & sigCSA_sum_5[0])) | ((1'b 0 & ((sigCSA_cry_4[2] ^ sigCSA_sum_5[0]))));
  assign sigCSA_sum_11[3] = sigCSA_cry_4[3] ^ sigCSA_sum_5[1] ^ sigCSA_cry_5[0];
  assign sigCSA_cry_11[3] = ((sigCSA_cry_4[3] & sigCSA_sum_5[1])) | ((sigCSA_cry_5[0] & ((sigCSA_cry_4[3] ^ sigCSA_sum_5[1]))));
  assign sigCSA_sum_11[4] = sigCSA_cry_4[4] ^ sigCSA_sum_5[2] ^ sigCSA_cry_5[1];
  assign sigCSA_cry_11[4] = ((sigCSA_cry_4[4] & sigCSA_sum_5[2])) | ((sigCSA_cry_5[1] & ((sigCSA_cry_4[4] ^ sigCSA_sum_5[2]))));
  assign sigCSA_sum_11[5] = sigCSA_cry_4[5] ^ sigCSA_sum_5[3] ^ sigCSA_cry_5[2];
  assign sigCSA_cry_11[5] = ((sigCSA_cry_4[5] & sigCSA_sum_5[3])) | ((sigCSA_cry_5[2] & ((sigCSA_cry_4[5] ^ sigCSA_sum_5[3]))));
  assign sigCSA_sum_11[6] = sigCSA_cry_4[6] ^ sigCSA_sum_5[4] ^ sigCSA_cry_5[3];
  assign sigCSA_cry_11[6] = ((sigCSA_cry_4[6] & sigCSA_sum_5[4])) | ((sigCSA_cry_5[3] & ((sigCSA_cry_4[6] ^ sigCSA_sum_5[4]))));
  assign sigCSA_sum_11[7] = sigCSA_cry_4[7] ^ sigCSA_sum_5[5] ^ sigCSA_cry_5[4];
  assign sigCSA_cry_11[7] = ((sigCSA_cry_4[7] & sigCSA_sum_5[5])) | ((sigCSA_cry_5[4] & ((sigCSA_cry_4[7] ^ sigCSA_sum_5[5]))));
  assign sigCSA_sum_11[8] = sigCSA_cry_4[8] ^ sigCSA_sum_5[6] ^ sigCSA_cry_5[5];
  assign sigCSA_cry_11[8] = ((sigCSA_cry_4[8] & sigCSA_sum_5[6])) | ((sigCSA_cry_5[5] & ((sigCSA_cry_4[8] ^ sigCSA_sum_5[6]))));
  assign sigCSA_sum_11[9] = sigCSA_cry_4[9] ^ sigCSA_sum_5[7] ^ sigCSA_cry_5[6];
  assign sigCSA_cry_11[9] = ((sigCSA_cry_4[9] & sigCSA_sum_5[7])) | ((sigCSA_cry_5[6] & ((sigCSA_cry_4[9] ^ sigCSA_sum_5[7]))));
  assign sigCSA_sum_11[10] = sigCSA_cry_4[10] ^ sigCSA_sum_5[8] ^ sigCSA_cry_5[7];
  assign sigCSA_cry_11[10] = ((sigCSA_cry_4[10] & sigCSA_sum_5[8])) | ((sigCSA_cry_5[7] & ((sigCSA_cry_4[10] ^ sigCSA_sum_5[8]))));
  assign sigCSA_sum_11[11] = sigCSA_cry_4[11] ^ sigCSA_sum_5[9] ^ sigCSA_cry_5[8];
  assign sigCSA_cry_11[11] = ((sigCSA_cry_4[11] & sigCSA_sum_5[9])) | ((sigCSA_cry_5[8] & ((sigCSA_cry_4[11] ^ sigCSA_sum_5[9]))));
  assign sigCSA_sum_11[12] = sigCSA_cry_4[12] ^ sigCSA_sum_5[10] ^ sigCSA_cry_5[9];
  assign sigCSA_cry_11[12] = ((sigCSA_cry_4[12] & sigCSA_sum_5[10])) | ((sigCSA_cry_5[9] & ((sigCSA_cry_4[12] ^ sigCSA_sum_5[10]))));
  assign sigCSA_sum_11[13] = sigCSA_cry_4[13] ^ sigCSA_sum_5[11] ^ sigCSA_cry_5[10];
  assign sigCSA_cry_11[13] = ((sigCSA_cry_4[13] & sigCSA_sum_5[11])) | ((sigCSA_cry_5[10] & ((sigCSA_cry_4[13] ^ sigCSA_sum_5[11]))));
  assign sigCSA_sum_11[14] = sigCSA_cry_4[14] ^ sigCSA_sum_5[12] ^ sigCSA_cry_5[11];
  assign sigCSA_cry_11[14] = ((sigCSA_cry_4[14] & sigCSA_sum_5[12])) | ((sigCSA_cry_5[11] & ((sigCSA_cry_4[14] ^ sigCSA_sum_5[12]))));
  assign sigCSA_sum_11[15] = sigCSA_cry_4[15] ^ sigCSA_sum_5[13] ^ sigCSA_cry_5[12];
  assign sigCSA_cry_11[15] = ((sigCSA_cry_4[15] & sigCSA_sum_5[13])) | ((sigCSA_cry_5[12] & ((sigCSA_cry_4[15] ^ sigCSA_sum_5[13]))));
  assign sigCSA_sum_11[16] = sigCSA_cry_4[16] ^ sigCSA_sum_5[14] ^ sigCSA_cry_5[13];
  assign sigCSA_cry_11[16] = ((sigCSA_cry_4[16] & sigCSA_sum_5[14])) | ((sigCSA_cry_5[13] & ((sigCSA_cry_4[16] ^ sigCSA_sum_5[14]))));
  assign sigCSA_sum_11[17] = sigCSA_cry_4[17] ^ sigCSA_sum_5[15] ^ sigCSA_cry_5[14];
  assign sigCSA_cry_11[17] = ((sigCSA_cry_4[17] & sigCSA_sum_5[15])) | ((sigCSA_cry_5[14] & ((sigCSA_cry_4[17] ^ sigCSA_sum_5[15]))));
  assign sigCSA_sum_11[18] = sigCSA_cry_4[18] ^ sigCSA_sum_5[16] ^ sigCSA_cry_5[15];
  assign sigCSA_cry_11[18] = ((sigCSA_cry_4[18] & sigCSA_sum_5[16])) | ((sigCSA_cry_5[15] & ((sigCSA_cry_4[18] ^ sigCSA_sum_5[16]))));
  assign sigCSA_sum_11[19] = sigCSA_cry_4[19] ^ sigCSA_sum_5[17] ^ sigCSA_cry_5[16];
  assign sigCSA_cry_11[19] = ((sigCSA_cry_4[19] & sigCSA_sum_5[17])) | ((sigCSA_cry_5[16] & ((sigCSA_cry_4[19] ^ sigCSA_sum_5[17]))));
  assign sigCSA_sum_11[20] = sigCSA_cry_4[20] ^ sigCSA_sum_5[18] ^ sigCSA_cry_5[17];
  assign sigCSA_cry_11[20] = ((sigCSA_cry_4[20] & sigCSA_sum_5[18])) | ((sigCSA_cry_5[17] & ((sigCSA_cry_4[20] ^ sigCSA_sum_5[18]))));
  assign sigCSA_sum_11[21] = sigCSA_cry_4[21] ^ sigCSA_sum_5[19] ^ sigCSA_cry_5[18];
  assign sigCSA_cry_11[21] = ((sigCSA_cry_4[21] & sigCSA_sum_5[19])) | ((sigCSA_cry_5[18] & ((sigCSA_cry_4[21] ^ sigCSA_sum_5[19]))));
  assign sigCSA_sum_11[22] = sigCSA_cry_4[22] ^ sigCSA_sum_5[20] ^ sigCSA_cry_5[19];
  assign sigCSA_cry_11[22] = ((sigCSA_cry_4[22] & sigCSA_sum_5[20])) | ((sigCSA_cry_5[19] & ((sigCSA_cry_4[22] ^ sigCSA_sum_5[20]))));
  assign sigCSA_sum_11[23] = sigCSA_cry_4[23] ^ sigCSA_sum_5[21] ^ sigCSA_cry_5[20];
  assign sigCSA_cry_11[23] = ((sigCSA_cry_4[23] & sigCSA_sum_5[21])) | ((sigCSA_cry_5[20] & ((sigCSA_cry_4[23] ^ sigCSA_sum_5[21]))));
  assign sigCSA_sum_11[24] = sigCSA_cry_4[24] ^ sigCSA_sum_5[22] ^ sigCSA_cry_5[21];
  assign sigCSA_cry_11[24] = ((sigCSA_cry_4[24] & sigCSA_sum_5[22])) | ((sigCSA_cry_5[21] & ((sigCSA_cry_4[24] ^ sigCSA_sum_5[22]))));
  assign sigCSA_sum_11[25] = sigCSA_cry_4[25] ^ sigCSA_sum_5[23] ^ sigCSA_cry_5[22];
  assign sigCSA_cry_11[25] = ((sigCSA_cry_4[25] & sigCSA_sum_5[23])) | ((sigCSA_cry_5[22] & ((sigCSA_cry_4[25] ^ sigCSA_sum_5[23]))));
  assign sigCSA_sum_11[26] = 1'b 0 ^ sigCSA_sum_5[24] ^ sigCSA_cry_5[23];
  assign sigCSA_cry_11[26] = ((1'b 0 & sigCSA_sum_5[24])) | ((sigCSA_cry_5[23] & ((1'b 0 ^ sigCSA_sum_5[24]))));
  assign sigCSA_sum_11[27] = 1'b 0 ^ sigCSA_sum_5[25] ^ sigCSA_cry_5[24];
  assign sigCSA_cry_11[27] = ((1'b 0 & sigCSA_sum_5[25])) | ((sigCSA_cry_5[24] & ((1'b 0 ^ sigCSA_sum_5[25]))));
  assign sigCSA_sum_11[28] = 1'b 0 ^ 1'b 0 ^ sigCSA_cry_5[25];
  assign sigCSA_cry_11[28] = ((1'b 0 & 1'b 0)) | ((sigCSA_cry_5[25] & ((1'b 0 ^ 1'b 0))));
  // csa : 12
  // generating sigCSA_sum_12 and sigCSA_cry_12
  assign sigCSA_sum_12[0] = sigCSA_sum_6[0] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_12[0] = ((sigCSA_sum_6[0] & 1'b 0)) | ((1'b 0 & ((sigCSA_sum_6[0] ^ 1'b 0))));
  assign sigCSA_sum_12[1] = sigCSA_sum_6[1] ^ sigCSA_cry_6[0] ^ 1'b 0;
  assign sigCSA_cry_12[1] = ((sigCSA_sum_6[1] & sigCSA_cry_6[0])) | ((1'b 0 & ((sigCSA_sum_6[1] ^ sigCSA_cry_6[0]))));
  assign sigCSA_sum_12[2] = sigCSA_sum_6[2] ^ sigCSA_cry_6[1] ^ 1'b 0;
  assign sigCSA_cry_12[2] = ((sigCSA_sum_6[2] & sigCSA_cry_6[1])) | ((1'b 0 & ((sigCSA_sum_6[2] ^ sigCSA_cry_6[1]))));
  assign sigCSA_sum_12[3] = sigCSA_sum_6[3] ^ sigCSA_cry_6[2] ^ sigCSA_sum_7[0];
  assign sigCSA_cry_12[3] = ((sigCSA_sum_6[3] & sigCSA_cry_6[2])) | ((sigCSA_sum_7[0] & ((sigCSA_sum_6[3] ^ sigCSA_cry_6[2]))));
  assign sigCSA_sum_12[4] = sigCSA_sum_6[4] ^ sigCSA_cry_6[3] ^ sigCSA_sum_7[1];
  assign sigCSA_cry_12[4] = ((sigCSA_sum_6[4] & sigCSA_cry_6[3])) | ((sigCSA_sum_7[1] & ((sigCSA_sum_6[4] ^ sigCSA_cry_6[3]))));
  assign sigCSA_sum_12[5] = sigCSA_sum_6[5] ^ sigCSA_cry_6[4] ^ sigCSA_sum_7[2];
  assign sigCSA_cry_12[5] = ((sigCSA_sum_6[5] & sigCSA_cry_6[4])) | ((sigCSA_sum_7[2] & ((sigCSA_sum_6[5] ^ sigCSA_cry_6[4]))));
  assign sigCSA_sum_12[6] = sigCSA_sum_6[6] ^ sigCSA_cry_6[5] ^ sigCSA_sum_7[3];
  assign sigCSA_cry_12[6] = ((sigCSA_sum_6[6] & sigCSA_cry_6[5])) | ((sigCSA_sum_7[3] & ((sigCSA_sum_6[6] ^ sigCSA_cry_6[5]))));
  assign sigCSA_sum_12[7] = sigCSA_sum_6[7] ^ sigCSA_cry_6[6] ^ sigCSA_sum_7[4];
  assign sigCSA_cry_12[7] = ((sigCSA_sum_6[7] & sigCSA_cry_6[6])) | ((sigCSA_sum_7[4] & ((sigCSA_sum_6[7] ^ sigCSA_cry_6[6]))));
  assign sigCSA_sum_12[8] = sigCSA_sum_6[8] ^ sigCSA_cry_6[7] ^ sigCSA_sum_7[5];
  assign sigCSA_cry_12[8] = ((sigCSA_sum_6[8] & sigCSA_cry_6[7])) | ((sigCSA_sum_7[5] & ((sigCSA_sum_6[8] ^ sigCSA_cry_6[7]))));
  assign sigCSA_sum_12[9] = sigCSA_sum_6[9] ^ sigCSA_cry_6[8] ^ sigCSA_sum_7[6];
  assign sigCSA_cry_12[9] = ((sigCSA_sum_6[9] & sigCSA_cry_6[8])) | ((sigCSA_sum_7[6] & ((sigCSA_sum_6[9] ^ sigCSA_cry_6[8]))));
  assign sigCSA_sum_12[10] = sigCSA_sum_6[10] ^ sigCSA_cry_6[9] ^ sigCSA_sum_7[7];
  assign sigCSA_cry_12[10] = ((sigCSA_sum_6[10] & sigCSA_cry_6[9])) | ((sigCSA_sum_7[7] & ((sigCSA_sum_6[10] ^ sigCSA_cry_6[9]))));
  assign sigCSA_sum_12[11] = sigCSA_sum_6[11] ^ sigCSA_cry_6[10] ^ sigCSA_sum_7[8];
  assign sigCSA_cry_12[11] = ((sigCSA_sum_6[11] & sigCSA_cry_6[10])) | ((sigCSA_sum_7[8] & ((sigCSA_sum_6[11] ^ sigCSA_cry_6[10]))));
  assign sigCSA_sum_12[12] = sigCSA_sum_6[12] ^ sigCSA_cry_6[11] ^ sigCSA_sum_7[9];
  assign sigCSA_cry_12[12] = ((sigCSA_sum_6[12] & sigCSA_cry_6[11])) | ((sigCSA_sum_7[9] & ((sigCSA_sum_6[12] ^ sigCSA_cry_6[11]))));
  assign sigCSA_sum_12[13] = sigCSA_sum_6[13] ^ sigCSA_cry_6[12] ^ sigCSA_sum_7[10];
  assign sigCSA_cry_12[13] = ((sigCSA_sum_6[13] & sigCSA_cry_6[12])) | ((sigCSA_sum_7[10] & ((sigCSA_sum_6[13] ^ sigCSA_cry_6[12]))));
  assign sigCSA_sum_12[14] = sigCSA_sum_6[14] ^ sigCSA_cry_6[13] ^ sigCSA_sum_7[11];
  assign sigCSA_cry_12[14] = ((sigCSA_sum_6[14] & sigCSA_cry_6[13])) | ((sigCSA_sum_7[11] & ((sigCSA_sum_6[14] ^ sigCSA_cry_6[13]))));
  assign sigCSA_sum_12[15] = sigCSA_sum_6[15] ^ sigCSA_cry_6[14] ^ sigCSA_sum_7[12];
  assign sigCSA_cry_12[15] = ((sigCSA_sum_6[15] & sigCSA_cry_6[14])) | ((sigCSA_sum_7[12] & ((sigCSA_sum_6[15] ^ sigCSA_cry_6[14]))));
  assign sigCSA_sum_12[16] = sigCSA_sum_6[16] ^ sigCSA_cry_6[15] ^ sigCSA_sum_7[13];
  assign sigCSA_cry_12[16] = ((sigCSA_sum_6[16] & sigCSA_cry_6[15])) | ((sigCSA_sum_7[13] & ((sigCSA_sum_6[16] ^ sigCSA_cry_6[15]))));
  assign sigCSA_sum_12[17] = sigCSA_sum_6[17] ^ sigCSA_cry_6[16] ^ sigCSA_sum_7[14];
  assign sigCSA_cry_12[17] = ((sigCSA_sum_6[17] & sigCSA_cry_6[16])) | ((sigCSA_sum_7[14] & ((sigCSA_sum_6[17] ^ sigCSA_cry_6[16]))));
  assign sigCSA_sum_12[18] = sigCSA_sum_6[18] ^ sigCSA_cry_6[17] ^ sigCSA_sum_7[15];
  assign sigCSA_cry_12[18] = ((sigCSA_sum_6[18] & sigCSA_cry_6[17])) | ((sigCSA_sum_7[15] & ((sigCSA_sum_6[18] ^ sigCSA_cry_6[17]))));
  assign sigCSA_sum_12[19] = sigCSA_sum_6[19] ^ sigCSA_cry_6[18] ^ sigCSA_sum_7[16];
  assign sigCSA_cry_12[19] = ((sigCSA_sum_6[19] & sigCSA_cry_6[18])) | ((sigCSA_sum_7[16] & ((sigCSA_sum_6[19] ^ sigCSA_cry_6[18]))));
  assign sigCSA_sum_12[20] = sigCSA_sum_6[20] ^ sigCSA_cry_6[19] ^ sigCSA_sum_7[17];
  assign sigCSA_cry_12[20] = ((sigCSA_sum_6[20] & sigCSA_cry_6[19])) | ((sigCSA_sum_7[17] & ((sigCSA_sum_6[20] ^ sigCSA_cry_6[19]))));
  assign sigCSA_sum_12[21] = sigCSA_sum_6[21] ^ sigCSA_cry_6[20] ^ sigCSA_sum_7[18];
  assign sigCSA_cry_12[21] = ((sigCSA_sum_6[21] & sigCSA_cry_6[20])) | ((sigCSA_sum_7[18] & ((sigCSA_sum_6[21] ^ sigCSA_cry_6[20]))));
  assign sigCSA_sum_12[22] = sigCSA_sum_6[22] ^ sigCSA_cry_6[21] ^ sigCSA_sum_7[19];
  assign sigCSA_cry_12[22] = ((sigCSA_sum_6[22] & sigCSA_cry_6[21])) | ((sigCSA_sum_7[19] & ((sigCSA_sum_6[22] ^ sigCSA_cry_6[21]))));
  assign sigCSA_sum_12[23] = sigCSA_sum_6[23] ^ sigCSA_cry_6[22] ^ sigCSA_sum_7[20];
  assign sigCSA_cry_12[23] = ((sigCSA_sum_6[23] & sigCSA_cry_6[22])) | ((sigCSA_sum_7[20] & ((sigCSA_sum_6[23] ^ sigCSA_cry_6[22]))));
  assign sigCSA_sum_12[24] = sigCSA_sum_6[24] ^ sigCSA_cry_6[23] ^ sigCSA_sum_7[21];
  assign sigCSA_cry_12[24] = ((sigCSA_sum_6[24] & sigCSA_cry_6[23])) | ((sigCSA_sum_7[21] & ((sigCSA_sum_6[24] ^ sigCSA_cry_6[23]))));
  assign sigCSA_sum_12[25] = sigCSA_sum_6[25] ^ sigCSA_cry_6[24] ^ sigCSA_sum_7[22];
  assign sigCSA_cry_12[25] = ((sigCSA_sum_6[25] & sigCSA_cry_6[24])) | ((sigCSA_sum_7[22] & ((sigCSA_sum_6[25] ^ sigCSA_cry_6[24]))));
  assign sigCSA_sum_12[26] = 1'b 0 ^ sigCSA_cry_6[25] ^ sigCSA_sum_7[23];
  assign sigCSA_cry_12[26] = ((1'b 0 & sigCSA_cry_6[25])) | ((sigCSA_sum_7[23] & ((1'b 0 ^ sigCSA_cry_6[25]))));
  assign sigCSA_sum_12[27] = 1'b 0 ^ 1'b 0 ^ sigCSA_sum_7[24];
  assign sigCSA_cry_12[27] = ((1'b 0 & 1'b 0)) | ((sigCSA_sum_7[24] & ((1'b 0 ^ 1'b 0))));
  assign sigCSA_sum_12[28] = 1'b 0 ^ 1'b 0 ^ sigCSA_sum_7[25];
  assign sigCSA_cry_12[28] = ((1'b 0 & 1'b 0)) | ((sigCSA_sum_7[25] & ((1'b 0 ^ 1'b 0))));
  // csa : 13
  // generating sigCSA_sum_13 and sigCSA_cry_13
  assign sigCSA_sum_13[0] = sigCSA_sum_8[0] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_13[0] = ((sigCSA_sum_8[0] & 1'b 0)) | ((1'b 0 & ((sigCSA_sum_8[0] ^ 1'b 0))));
  assign sigCSA_sum_13[1] = sigCSA_sum_8[1] ^ sigCSA_cry_8[0] ^ 1'b 0;
  assign sigCSA_cry_13[1] = ((sigCSA_sum_8[1] & sigCSA_cry_8[0])) | ((1'b 0 & ((sigCSA_sum_8[1] ^ sigCSA_cry_8[0]))));
  assign sigCSA_sum_13[2] = sigCSA_sum_8[2] ^ sigCSA_cry_8[1] ^ 1'b 0;
  assign sigCSA_cry_13[2] = ((sigCSA_sum_8[2] & sigCSA_cry_8[1])) | ((1'b 0 & ((sigCSA_sum_8[2] ^ sigCSA_cry_8[1]))));
  assign sigCSA_sum_13[3] = sigCSA_sum_8[3] ^ sigCSA_cry_8[2] ^ 1'b 0;
  assign sigCSA_cry_13[3] = ((sigCSA_sum_8[3] & sigCSA_cry_8[2])) | ((1'b 0 & ((sigCSA_sum_8[3] ^ sigCSA_cry_8[2]))));
  assign sigCSA_sum_13[4] = sigCSA_sum_8[4] ^ sigCSA_cry_8[3] ^ sigCSA_sum_9[0];
  assign sigCSA_cry_13[4] = ((sigCSA_sum_8[4] & sigCSA_cry_8[3])) | ((sigCSA_sum_9[0] & ((sigCSA_sum_8[4] ^ sigCSA_cry_8[3]))));
  assign sigCSA_sum_13[5] = sigCSA_sum_8[5] ^ sigCSA_cry_8[4] ^ sigCSA_sum_9[1];
  assign sigCSA_cry_13[5] = ((sigCSA_sum_8[5] & sigCSA_cry_8[4])) | ((sigCSA_sum_9[1] & ((sigCSA_sum_8[5] ^ sigCSA_cry_8[4]))));
  assign sigCSA_sum_13[6] = sigCSA_sum_8[6] ^ sigCSA_cry_8[5] ^ sigCSA_sum_9[2];
  assign sigCSA_cry_13[6] = ((sigCSA_sum_8[6] & sigCSA_cry_8[5])) | ((sigCSA_sum_9[2] & ((sigCSA_sum_8[6] ^ sigCSA_cry_8[5]))));
  assign sigCSA_sum_13[7] = sigCSA_sum_8[7] ^ sigCSA_cry_8[6] ^ sigCSA_sum_9[3];
  assign sigCSA_cry_13[7] = ((sigCSA_sum_8[7] & sigCSA_cry_8[6])) | ((sigCSA_sum_9[3] & ((sigCSA_sum_8[7] ^ sigCSA_cry_8[6]))));
  assign sigCSA_sum_13[8] = sigCSA_sum_8[8] ^ sigCSA_cry_8[7] ^ sigCSA_sum_9[4];
  assign sigCSA_cry_13[8] = ((sigCSA_sum_8[8] & sigCSA_cry_8[7])) | ((sigCSA_sum_9[4] & ((sigCSA_sum_8[8] ^ sigCSA_cry_8[7]))));
  assign sigCSA_sum_13[9] = sigCSA_sum_8[9] ^ sigCSA_cry_8[8] ^ sigCSA_sum_9[5];
  assign sigCSA_cry_13[9] = ((sigCSA_sum_8[9] & sigCSA_cry_8[8])) | ((sigCSA_sum_9[5] & ((sigCSA_sum_8[9] ^ sigCSA_cry_8[8]))));
  assign sigCSA_sum_13[10] = sigCSA_sum_8[10] ^ sigCSA_cry_8[9] ^ sigCSA_sum_9[6];
  assign sigCSA_cry_13[10] = ((sigCSA_sum_8[10] & sigCSA_cry_8[9])) | ((sigCSA_sum_9[6] & ((sigCSA_sum_8[10] ^ sigCSA_cry_8[9]))));
  assign sigCSA_sum_13[11] = sigCSA_sum_8[11] ^ sigCSA_cry_8[10] ^ sigCSA_sum_9[7];
  assign sigCSA_cry_13[11] = ((sigCSA_sum_8[11] & sigCSA_cry_8[10])) | ((sigCSA_sum_9[7] & ((sigCSA_sum_8[11] ^ sigCSA_cry_8[10]))));
  assign sigCSA_sum_13[12] = sigCSA_sum_8[12] ^ sigCSA_cry_8[11] ^ sigCSA_sum_9[8];
  assign sigCSA_cry_13[12] = ((sigCSA_sum_8[12] & sigCSA_cry_8[11])) | ((sigCSA_sum_9[8] & ((sigCSA_sum_8[12] ^ sigCSA_cry_8[11]))));
  assign sigCSA_sum_13[13] = sigCSA_sum_8[13] ^ sigCSA_cry_8[12] ^ sigCSA_sum_9[9];
  assign sigCSA_cry_13[13] = ((sigCSA_sum_8[13] & sigCSA_cry_8[12])) | ((sigCSA_sum_9[9] & ((sigCSA_sum_8[13] ^ sigCSA_cry_8[12]))));
  assign sigCSA_sum_13[14] = sigCSA_sum_8[14] ^ sigCSA_cry_8[13] ^ sigCSA_sum_9[10];
  assign sigCSA_cry_13[14] = ((sigCSA_sum_8[14] & sigCSA_cry_8[13])) | ((sigCSA_sum_9[10] & ((sigCSA_sum_8[14] ^ sigCSA_cry_8[13]))));
  assign sigCSA_sum_13[15] = sigCSA_sum_8[15] ^ sigCSA_cry_8[14] ^ sigCSA_sum_9[11];
  assign sigCSA_cry_13[15] = ((sigCSA_sum_8[15] & sigCSA_cry_8[14])) | ((sigCSA_sum_9[11] & ((sigCSA_sum_8[15] ^ sigCSA_cry_8[14]))));
  assign sigCSA_sum_13[16] = sigCSA_sum_8[16] ^ sigCSA_cry_8[15] ^ sigCSA_sum_9[12];
  assign sigCSA_cry_13[16] = ((sigCSA_sum_8[16] & sigCSA_cry_8[15])) | ((sigCSA_sum_9[12] & ((sigCSA_sum_8[16] ^ sigCSA_cry_8[15]))));
  assign sigCSA_sum_13[17] = sigCSA_sum_8[17] ^ sigCSA_cry_8[16] ^ sigCSA_sum_9[13];
  assign sigCSA_cry_13[17] = ((sigCSA_sum_8[17] & sigCSA_cry_8[16])) | ((sigCSA_sum_9[13] & ((sigCSA_sum_8[17] ^ sigCSA_cry_8[16]))));
  assign sigCSA_sum_13[18] = sigCSA_sum_8[18] ^ sigCSA_cry_8[17] ^ sigCSA_sum_9[14];
  assign sigCSA_cry_13[18] = ((sigCSA_sum_8[18] & sigCSA_cry_8[17])) | ((sigCSA_sum_9[14] & ((sigCSA_sum_8[18] ^ sigCSA_cry_8[17]))));
  assign sigCSA_sum_13[19] = sigCSA_sum_8[19] ^ sigCSA_cry_8[18] ^ sigCSA_sum_9[15];
  assign sigCSA_cry_13[19] = ((sigCSA_sum_8[19] & sigCSA_cry_8[18])) | ((sigCSA_sum_9[15] & ((sigCSA_sum_8[19] ^ sigCSA_cry_8[18]))));
  assign sigCSA_sum_13[20] = sigCSA_sum_8[20] ^ sigCSA_cry_8[19] ^ sigCSA_sum_9[16];
  assign sigCSA_cry_13[20] = ((sigCSA_sum_8[20] & sigCSA_cry_8[19])) | ((sigCSA_sum_9[16] & ((sigCSA_sum_8[20] ^ sigCSA_cry_8[19]))));
  assign sigCSA_sum_13[21] = sigCSA_sum_8[21] ^ sigCSA_cry_8[20] ^ sigCSA_sum_9[17];
  assign sigCSA_cry_13[21] = ((sigCSA_sum_8[21] & sigCSA_cry_8[20])) | ((sigCSA_sum_9[17] & ((sigCSA_sum_8[21] ^ sigCSA_cry_8[20]))));
  assign sigCSA_sum_13[22] = sigCSA_sum_8[22] ^ sigCSA_cry_8[21] ^ sigCSA_sum_9[18];
  assign sigCSA_cry_13[22] = ((sigCSA_sum_8[22] & sigCSA_cry_8[21])) | ((sigCSA_sum_9[18] & ((sigCSA_sum_8[22] ^ sigCSA_cry_8[21]))));
  assign sigCSA_sum_13[23] = sigCSA_sum_8[23] ^ sigCSA_cry_8[22] ^ sigCSA_sum_9[19];
  assign sigCSA_cry_13[23] = ((sigCSA_sum_8[23] & sigCSA_cry_8[22])) | ((sigCSA_sum_9[19] & ((sigCSA_sum_8[23] ^ sigCSA_cry_8[22]))));
  assign sigCSA_sum_13[24] = sigCSA_sum_8[24] ^ sigCSA_cry_8[23] ^ sigCSA_sum_9[20];
  assign sigCSA_cry_13[24] = ((sigCSA_sum_8[24] & sigCSA_cry_8[23])) | ((sigCSA_sum_9[20] & ((sigCSA_sum_8[24] ^ sigCSA_cry_8[23]))));
  assign sigCSA_sum_13[25] = sigCSA_sum_8[25] ^ sigCSA_cry_8[24] ^ sigCSA_sum_9[21];
  assign sigCSA_cry_13[25] = ((sigCSA_sum_8[25] & sigCSA_cry_8[24])) | ((sigCSA_sum_9[21] & ((sigCSA_sum_8[25] ^ sigCSA_cry_8[24]))));
  assign sigCSA_sum_13[26] = sigCSA_sum_8[26] ^ sigCSA_cry_8[25] ^ sigCSA_sum_9[22];
  assign sigCSA_cry_13[26] = ((sigCSA_sum_8[26] & sigCSA_cry_8[25])) | ((sigCSA_sum_9[22] & ((sigCSA_sum_8[26] ^ sigCSA_cry_8[25]))));
  assign sigCSA_sum_13[27] = sigCSA_sum_8[27] ^ sigCSA_cry_8[26] ^ sigCSA_sum_9[23];
  assign sigCSA_cry_13[27] = ((sigCSA_sum_8[27] & sigCSA_cry_8[26])) | ((sigCSA_sum_9[23] & ((sigCSA_sum_8[27] ^ sigCSA_cry_8[26]))));
  assign sigCSA_sum_13[28] = sigCSA_sum_8[28] ^ sigCSA_cry_8[27] ^ sigCSA_sum_9[24];
  assign sigCSA_cry_13[28] = ((sigCSA_sum_8[28] & sigCSA_cry_8[27])) | ((sigCSA_sum_9[24] & ((sigCSA_sum_8[28] ^ sigCSA_cry_8[27]))));
  assign sigCSA_sum_13[29] = 1'b 0 ^ sigCSA_cry_8[28] ^ sigCSA_sum_9[25];
  assign sigCSA_cry_13[29] = ((1'b 0 & sigCSA_cry_8[28])) | ((sigCSA_sum_9[25] & ((1'b 0 ^ sigCSA_cry_8[28]))));
  assign sigCSA_sum_13[30] = 1'b 0 ^ 1'b 0 ^ sigCSA_sum_9[26];
  assign sigCSA_cry_13[30] = ((1'b 0 & 1'b 0)) | ((sigCSA_sum_9[26] & ((1'b 0 ^ 1'b 0))));
  assign sigCSA_sum_13[31] = 1'b 0 ^ 1'b 0 ^ sigCSA_sum_9[27];
  assign sigCSA_cry_13[31] = ((1'b 0 & 1'b 0)) | ((sigCSA_sum_9[27] & ((1'b 0 ^ 1'b 0))));
  assign sigCSA_sum_13[32] = 1'b 0 ^ 1'b 0 ^ sigCSA_sum_9[28];
  assign sigCSA_cry_13[32] = ((1'b 0 & 1'b 0)) | ((sigCSA_sum_9[28] & ((1'b 0 ^ 1'b 0))));
  // csa : 14
  // generating sigCSA_sum_14 and sigCSA_cry_14
  assign sigCSA_sum_14[0] = sigCSA_cry_9[0] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_14[0] = ((sigCSA_cry_9[0] & 1'b 0)) | ((1'b 0 & ((sigCSA_cry_9[0] ^ 1'b 0))));
  assign sigCSA_sum_14[1] = sigCSA_cry_9[1] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_14[1] = ((sigCSA_cry_9[1] & 1'b 0)) | ((1'b 0 & ((sigCSA_cry_9[1] ^ 1'b 0))));
  assign sigCSA_sum_14[2] = sigCSA_cry_9[2] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_14[2] = ((sigCSA_cry_9[2] & 1'b 0)) | ((1'b 0 & ((sigCSA_cry_9[2] ^ 1'b 0))));
  assign sigCSA_sum_14[3] = sigCSA_cry_9[3] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_14[3] = ((sigCSA_cry_9[3] & 1'b 0)) | ((1'b 0 & ((sigCSA_cry_9[3] ^ 1'b 0))));
  assign sigCSA_sum_14[4] = sigCSA_cry_9[4] ^ sigCSA_sum_10[0] ^ 1'b 0;
  assign sigCSA_cry_14[4] = ((sigCSA_cry_9[4] & sigCSA_sum_10[0])) | ((1'b 0 & ((sigCSA_cry_9[4] ^ sigCSA_sum_10[0]))));
  assign sigCSA_sum_14[5] = sigCSA_cry_9[5] ^ sigCSA_sum_10[1] ^ sigCSA_cry_10[0];
  assign sigCSA_cry_14[5] = ((sigCSA_cry_9[5] & sigCSA_sum_10[1])) | ((sigCSA_cry_10[0] & ((sigCSA_cry_9[5] ^ sigCSA_sum_10[1]))));
  assign sigCSA_sum_14[6] = sigCSA_cry_9[6] ^ sigCSA_sum_10[2] ^ sigCSA_cry_10[1];
  assign sigCSA_cry_14[6] = ((sigCSA_cry_9[6] & sigCSA_sum_10[2])) | ((sigCSA_cry_10[1] & ((sigCSA_cry_9[6] ^ sigCSA_sum_10[2]))));
  assign sigCSA_sum_14[7] = sigCSA_cry_9[7] ^ sigCSA_sum_10[3] ^ sigCSA_cry_10[2];
  assign sigCSA_cry_14[7] = ((sigCSA_cry_9[7] & sigCSA_sum_10[3])) | ((sigCSA_cry_10[2] & ((sigCSA_cry_9[7] ^ sigCSA_sum_10[3]))));
  assign sigCSA_sum_14[8] = sigCSA_cry_9[8] ^ sigCSA_sum_10[4] ^ sigCSA_cry_10[3];
  assign sigCSA_cry_14[8] = ((sigCSA_cry_9[8] & sigCSA_sum_10[4])) | ((sigCSA_cry_10[3] & ((sigCSA_cry_9[8] ^ sigCSA_sum_10[4]))));
  assign sigCSA_sum_14[9] = sigCSA_cry_9[9] ^ sigCSA_sum_10[5] ^ sigCSA_cry_10[4];
  assign sigCSA_cry_14[9] = ((sigCSA_cry_9[9] & sigCSA_sum_10[5])) | ((sigCSA_cry_10[4] & ((sigCSA_cry_9[9] ^ sigCSA_sum_10[5]))));
  assign sigCSA_sum_14[10] = sigCSA_cry_9[10] ^ sigCSA_sum_10[6] ^ sigCSA_cry_10[5];
  assign sigCSA_cry_14[10] = ((sigCSA_cry_9[10] & sigCSA_sum_10[6])) | ((sigCSA_cry_10[5] & ((sigCSA_cry_9[10] ^ sigCSA_sum_10[6]))));
  assign sigCSA_sum_14[11] = sigCSA_cry_9[11] ^ sigCSA_sum_10[7] ^ sigCSA_cry_10[6];
  assign sigCSA_cry_14[11] = ((sigCSA_cry_9[11] & sigCSA_sum_10[7])) | ((sigCSA_cry_10[6] & ((sigCSA_cry_9[11] ^ sigCSA_sum_10[7]))));
  assign sigCSA_sum_14[12] = sigCSA_cry_9[12] ^ sigCSA_sum_10[8] ^ sigCSA_cry_10[7];
  assign sigCSA_cry_14[12] = ((sigCSA_cry_9[12] & sigCSA_sum_10[8])) | ((sigCSA_cry_10[7] & ((sigCSA_cry_9[12] ^ sigCSA_sum_10[8]))));
  assign sigCSA_sum_14[13] = sigCSA_cry_9[13] ^ sigCSA_sum_10[9] ^ sigCSA_cry_10[8];
  assign sigCSA_cry_14[13] = ((sigCSA_cry_9[13] & sigCSA_sum_10[9])) | ((sigCSA_cry_10[8] & ((sigCSA_cry_9[13] ^ sigCSA_sum_10[9]))));
  assign sigCSA_sum_14[14] = sigCSA_cry_9[14] ^ sigCSA_sum_10[10] ^ sigCSA_cry_10[9];
  assign sigCSA_cry_14[14] = ((sigCSA_cry_9[14] & sigCSA_sum_10[10])) | ((sigCSA_cry_10[9] & ((sigCSA_cry_9[14] ^ sigCSA_sum_10[10]))));
  assign sigCSA_sum_14[15] = sigCSA_cry_9[15] ^ sigCSA_sum_10[11] ^ sigCSA_cry_10[10];
  assign sigCSA_cry_14[15] = ((sigCSA_cry_9[15] & sigCSA_sum_10[11])) | ((sigCSA_cry_10[10] & ((sigCSA_cry_9[15] ^ sigCSA_sum_10[11]))));
  assign sigCSA_sum_14[16] = sigCSA_cry_9[16] ^ sigCSA_sum_10[12] ^ sigCSA_cry_10[11];
  assign sigCSA_cry_14[16] = ((sigCSA_cry_9[16] & sigCSA_sum_10[12])) | ((sigCSA_cry_10[11] & ((sigCSA_cry_9[16] ^ sigCSA_sum_10[12]))));
  assign sigCSA_sum_14[17] = sigCSA_cry_9[17] ^ sigCSA_sum_10[13] ^ sigCSA_cry_10[12];
  assign sigCSA_cry_14[17] = ((sigCSA_cry_9[17] & sigCSA_sum_10[13])) | ((sigCSA_cry_10[12] & ((sigCSA_cry_9[17] ^ sigCSA_sum_10[13]))));
  assign sigCSA_sum_14[18] = sigCSA_cry_9[18] ^ sigCSA_sum_10[14] ^ sigCSA_cry_10[13];
  assign sigCSA_cry_14[18] = ((sigCSA_cry_9[18] & sigCSA_sum_10[14])) | ((sigCSA_cry_10[13] & ((sigCSA_cry_9[18] ^ sigCSA_sum_10[14]))));
  assign sigCSA_sum_14[19] = sigCSA_cry_9[19] ^ sigCSA_sum_10[15] ^ sigCSA_cry_10[14];
  assign sigCSA_cry_14[19] = ((sigCSA_cry_9[19] & sigCSA_sum_10[15])) | ((sigCSA_cry_10[14] & ((sigCSA_cry_9[19] ^ sigCSA_sum_10[15]))));
  assign sigCSA_sum_14[20] = sigCSA_cry_9[20] ^ sigCSA_sum_10[16] ^ sigCSA_cry_10[15];
  assign sigCSA_cry_14[20] = ((sigCSA_cry_9[20] & sigCSA_sum_10[16])) | ((sigCSA_cry_10[15] & ((sigCSA_cry_9[20] ^ sigCSA_sum_10[16]))));
  assign sigCSA_sum_14[21] = sigCSA_cry_9[21] ^ sigCSA_sum_10[17] ^ sigCSA_cry_10[16];
  assign sigCSA_cry_14[21] = ((sigCSA_cry_9[21] & sigCSA_sum_10[17])) | ((sigCSA_cry_10[16] & ((sigCSA_cry_9[21] ^ sigCSA_sum_10[17]))));
  assign sigCSA_sum_14[22] = sigCSA_cry_9[22] ^ sigCSA_sum_10[18] ^ sigCSA_cry_10[17];
  assign sigCSA_cry_14[22] = ((sigCSA_cry_9[22] & sigCSA_sum_10[18])) | ((sigCSA_cry_10[17] & ((sigCSA_cry_9[22] ^ sigCSA_sum_10[18]))));
  assign sigCSA_sum_14[23] = sigCSA_cry_9[23] ^ sigCSA_sum_10[19] ^ sigCSA_cry_10[18];
  assign sigCSA_cry_14[23] = ((sigCSA_cry_9[23] & sigCSA_sum_10[19])) | ((sigCSA_cry_10[18] & ((sigCSA_cry_9[23] ^ sigCSA_sum_10[19]))));
  assign sigCSA_sum_14[24] = sigCSA_cry_9[24] ^ sigCSA_sum_10[20] ^ sigCSA_cry_10[19];
  assign sigCSA_cry_14[24] = ((sigCSA_cry_9[24] & sigCSA_sum_10[20])) | ((sigCSA_cry_10[19] & ((sigCSA_cry_9[24] ^ sigCSA_sum_10[20]))));
  assign sigCSA_sum_14[25] = sigCSA_cry_9[25] ^ sigCSA_sum_10[21] ^ sigCSA_cry_10[20];
  assign sigCSA_cry_14[25] = ((sigCSA_cry_9[25] & sigCSA_sum_10[21])) | ((sigCSA_cry_10[20] & ((sigCSA_cry_9[25] ^ sigCSA_sum_10[21]))));
  assign sigCSA_sum_14[26] = sigCSA_cry_9[26] ^ sigCSA_sum_10[22] ^ sigCSA_cry_10[21];
  assign sigCSA_cry_14[26] = ((sigCSA_cry_9[26] & sigCSA_sum_10[22])) | ((sigCSA_cry_10[21] & ((sigCSA_cry_9[26] ^ sigCSA_sum_10[22]))));
  assign sigCSA_sum_14[27] = sigCSA_cry_9[27] ^ sigCSA_sum_10[23] ^ sigCSA_cry_10[22];
  assign sigCSA_cry_14[27] = ((sigCSA_cry_9[27] & sigCSA_sum_10[23])) | ((sigCSA_cry_10[22] & ((sigCSA_cry_9[27] ^ sigCSA_sum_10[23]))));
  assign sigCSA_sum_14[28] = sigCSA_cry_9[28] ^ sigCSA_sum_10[24] ^ sigCSA_cry_10[23];
  assign sigCSA_cry_14[28] = ((sigCSA_cry_9[28] & sigCSA_sum_10[24])) | ((sigCSA_cry_10[23] & ((sigCSA_cry_9[28] ^ sigCSA_sum_10[24]))));
  assign sigCSA_sum_14[29] = 1'b 0 ^ sigCSA_sum_10[25] ^ sigCSA_cry_10[24];
  assign sigCSA_cry_14[29] = ((1'b 0 & sigCSA_sum_10[25])) | ((sigCSA_cry_10[24] & ((1'b 0 ^ sigCSA_sum_10[25]))));
  assign sigCSA_sum_14[30] = 1'b 0 ^ sigCSA_sum_10[26] ^ sigCSA_cry_10[25];
  assign sigCSA_cry_14[30] = ((1'b 0 & sigCSA_sum_10[26])) | ((sigCSA_cry_10[25] & ((1'b 0 ^ sigCSA_sum_10[26]))));
  assign sigCSA_sum_14[31] = 1'b 0 ^ sigCSA_sum_10[27] ^ sigCSA_cry_10[26];
  assign sigCSA_cry_14[31] = ((1'b 0 & sigCSA_sum_10[27])) | ((sigCSA_cry_10[26] & ((1'b 0 ^ sigCSA_sum_10[27]))));
  assign sigCSA_sum_14[32] = 1'b 0 ^ sigCSA_sum_10[28] ^ sigCSA_cry_10[27];
  assign sigCSA_cry_14[32] = ((1'b 0 & sigCSA_sum_10[28])) | ((sigCSA_cry_10[27] & ((1'b 0 ^ sigCSA_sum_10[28]))));
  assign sigCSA_sum_14[33] = 1'b 0 ^ 1'b 0 ^ sigCSA_cry_10[28];
  assign sigCSA_cry_14[33] = ((1'b 0 & 1'b 0)) | ((sigCSA_cry_10[28] & ((1'b 0 ^ 1'b 0))));
  // csa : 15
  // generating sigCSA_sum_15 and sigCSA_cry_15
  assign sigCSA_sum_15[0] = sigCSA_sum_11[0] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_15[0] = ((sigCSA_sum_11[0] & 1'b 0)) | ((1'b 0 & ((sigCSA_sum_11[0] ^ 1'b 0))));
  assign sigCSA_sum_15[1] = sigCSA_sum_11[1] ^ sigCSA_cry_11[0] ^ 1'b 0;
  assign sigCSA_cry_15[1] = ((sigCSA_sum_11[1] & sigCSA_cry_11[0])) | ((1'b 0 & ((sigCSA_sum_11[1] ^ sigCSA_cry_11[0]))));
  assign sigCSA_sum_15[2] = sigCSA_sum_11[2] ^ sigCSA_cry_11[1] ^ 1'b 0;
  assign sigCSA_cry_15[2] = ((sigCSA_sum_11[2] & sigCSA_cry_11[1])) | ((1'b 0 & ((sigCSA_sum_11[2] ^ sigCSA_cry_11[1]))));
  assign sigCSA_sum_15[3] = sigCSA_sum_11[3] ^ sigCSA_cry_11[2] ^ 1'b 0;
  assign sigCSA_cry_15[3] = ((sigCSA_sum_11[3] & sigCSA_cry_11[2])) | ((1'b 0 & ((sigCSA_sum_11[3] ^ sigCSA_cry_11[2]))));
  assign sigCSA_sum_15[4] = sigCSA_sum_11[4] ^ sigCSA_cry_11[3] ^ 1'b 0;
  assign sigCSA_cry_15[4] = ((sigCSA_sum_11[4] & sigCSA_cry_11[3])) | ((1'b 0 & ((sigCSA_sum_11[4] ^ sigCSA_cry_11[3]))));
  assign sigCSA_sum_15[5] = sigCSA_sum_11[5] ^ sigCSA_cry_11[4] ^ sigCSA_sum_12[0];
  assign sigCSA_cry_15[5] = ((sigCSA_sum_11[5] & sigCSA_cry_11[4])) | ((sigCSA_sum_12[0] & ((sigCSA_sum_11[5] ^ sigCSA_cry_11[4]))));
  assign sigCSA_sum_15[6] = sigCSA_sum_11[6] ^ sigCSA_cry_11[5] ^ sigCSA_sum_12[1];
  assign sigCSA_cry_15[6] = ((sigCSA_sum_11[6] & sigCSA_cry_11[5])) | ((sigCSA_sum_12[1] & ((sigCSA_sum_11[6] ^ sigCSA_cry_11[5]))));
  assign sigCSA_sum_15[7] = sigCSA_sum_11[7] ^ sigCSA_cry_11[6] ^ sigCSA_sum_12[2];
  assign sigCSA_cry_15[7] = ((sigCSA_sum_11[7] & sigCSA_cry_11[6])) | ((sigCSA_sum_12[2] & ((sigCSA_sum_11[7] ^ sigCSA_cry_11[6]))));
  assign sigCSA_sum_15[8] = sigCSA_sum_11[8] ^ sigCSA_cry_11[7] ^ sigCSA_sum_12[3];
  assign sigCSA_cry_15[8] = ((sigCSA_sum_11[8] & sigCSA_cry_11[7])) | ((sigCSA_sum_12[3] & ((sigCSA_sum_11[8] ^ sigCSA_cry_11[7]))));
  assign sigCSA_sum_15[9] = sigCSA_sum_11[9] ^ sigCSA_cry_11[8] ^ sigCSA_sum_12[4];
  assign sigCSA_cry_15[9] = ((sigCSA_sum_11[9] & sigCSA_cry_11[8])) | ((sigCSA_sum_12[4] & ((sigCSA_sum_11[9] ^ sigCSA_cry_11[8]))));
  assign sigCSA_sum_15[10] = sigCSA_sum_11[10] ^ sigCSA_cry_11[9] ^ sigCSA_sum_12[5];
  assign sigCSA_cry_15[10] = ((sigCSA_sum_11[10] & sigCSA_cry_11[9])) | ((sigCSA_sum_12[5] & ((sigCSA_sum_11[10] ^ sigCSA_cry_11[9]))));
  assign sigCSA_sum_15[11] = sigCSA_sum_11[11] ^ sigCSA_cry_11[10] ^ sigCSA_sum_12[6];
  assign sigCSA_cry_15[11] = ((sigCSA_sum_11[11] & sigCSA_cry_11[10])) | ((sigCSA_sum_12[6] & ((sigCSA_sum_11[11] ^ sigCSA_cry_11[10]))));
  assign sigCSA_sum_15[12] = sigCSA_sum_11[12] ^ sigCSA_cry_11[11] ^ sigCSA_sum_12[7];
  assign sigCSA_cry_15[12] = ((sigCSA_sum_11[12] & sigCSA_cry_11[11])) | ((sigCSA_sum_12[7] & ((sigCSA_sum_11[12] ^ sigCSA_cry_11[11]))));
  assign sigCSA_sum_15[13] = sigCSA_sum_11[13] ^ sigCSA_cry_11[12] ^ sigCSA_sum_12[8];
  assign sigCSA_cry_15[13] = ((sigCSA_sum_11[13] & sigCSA_cry_11[12])) | ((sigCSA_sum_12[8] & ((sigCSA_sum_11[13] ^ sigCSA_cry_11[12]))));
  assign sigCSA_sum_15[14] = sigCSA_sum_11[14] ^ sigCSA_cry_11[13] ^ sigCSA_sum_12[9];
  assign sigCSA_cry_15[14] = ((sigCSA_sum_11[14] & sigCSA_cry_11[13])) | ((sigCSA_sum_12[9] & ((sigCSA_sum_11[14] ^ sigCSA_cry_11[13]))));
  assign sigCSA_sum_15[15] = sigCSA_sum_11[15] ^ sigCSA_cry_11[14] ^ sigCSA_sum_12[10];
  assign sigCSA_cry_15[15] = ((sigCSA_sum_11[15] & sigCSA_cry_11[14])) | ((sigCSA_sum_12[10] & ((sigCSA_sum_11[15] ^ sigCSA_cry_11[14]))));
  assign sigCSA_sum_15[16] = sigCSA_sum_11[16] ^ sigCSA_cry_11[15] ^ sigCSA_sum_12[11];
  assign sigCSA_cry_15[16] = ((sigCSA_sum_11[16] & sigCSA_cry_11[15])) | ((sigCSA_sum_12[11] & ((sigCSA_sum_11[16] ^ sigCSA_cry_11[15]))));
  assign sigCSA_sum_15[17] = sigCSA_sum_11[17] ^ sigCSA_cry_11[16] ^ sigCSA_sum_12[12];
  assign sigCSA_cry_15[17] = ((sigCSA_sum_11[17] & sigCSA_cry_11[16])) | ((sigCSA_sum_12[12] & ((sigCSA_sum_11[17] ^ sigCSA_cry_11[16]))));
  assign sigCSA_sum_15[18] = sigCSA_sum_11[18] ^ sigCSA_cry_11[17] ^ sigCSA_sum_12[13];
  assign sigCSA_cry_15[18] = ((sigCSA_sum_11[18] & sigCSA_cry_11[17])) | ((sigCSA_sum_12[13] & ((sigCSA_sum_11[18] ^ sigCSA_cry_11[17]))));
  assign sigCSA_sum_15[19] = sigCSA_sum_11[19] ^ sigCSA_cry_11[18] ^ sigCSA_sum_12[14];
  assign sigCSA_cry_15[19] = ((sigCSA_sum_11[19] & sigCSA_cry_11[18])) | ((sigCSA_sum_12[14] & ((sigCSA_sum_11[19] ^ sigCSA_cry_11[18]))));
  assign sigCSA_sum_15[20] = sigCSA_sum_11[20] ^ sigCSA_cry_11[19] ^ sigCSA_sum_12[15];
  assign sigCSA_cry_15[20] = ((sigCSA_sum_11[20] & sigCSA_cry_11[19])) | ((sigCSA_sum_12[15] & ((sigCSA_sum_11[20] ^ sigCSA_cry_11[19]))));
  assign sigCSA_sum_15[21] = sigCSA_sum_11[21] ^ sigCSA_cry_11[20] ^ sigCSA_sum_12[16];
  assign sigCSA_cry_15[21] = ((sigCSA_sum_11[21] & sigCSA_cry_11[20])) | ((sigCSA_sum_12[16] & ((sigCSA_sum_11[21] ^ sigCSA_cry_11[20]))));
  assign sigCSA_sum_15[22] = sigCSA_sum_11[22] ^ sigCSA_cry_11[21] ^ sigCSA_sum_12[17];
  assign sigCSA_cry_15[22] = ((sigCSA_sum_11[22] & sigCSA_cry_11[21])) | ((sigCSA_sum_12[17] & ((sigCSA_sum_11[22] ^ sigCSA_cry_11[21]))));
  assign sigCSA_sum_15[23] = sigCSA_sum_11[23] ^ sigCSA_cry_11[22] ^ sigCSA_sum_12[18];
  assign sigCSA_cry_15[23] = ((sigCSA_sum_11[23] & sigCSA_cry_11[22])) | ((sigCSA_sum_12[18] & ((sigCSA_sum_11[23] ^ sigCSA_cry_11[22]))));
  assign sigCSA_sum_15[24] = sigCSA_sum_11[24] ^ sigCSA_cry_11[23] ^ sigCSA_sum_12[19];
  assign sigCSA_cry_15[24] = ((sigCSA_sum_11[24] & sigCSA_cry_11[23])) | ((sigCSA_sum_12[19] & ((sigCSA_sum_11[24] ^ sigCSA_cry_11[23]))));
  assign sigCSA_sum_15[25] = sigCSA_sum_11[25] ^ sigCSA_cry_11[24] ^ sigCSA_sum_12[20];
  assign sigCSA_cry_15[25] = ((sigCSA_sum_11[25] & sigCSA_cry_11[24])) | ((sigCSA_sum_12[20] & ((sigCSA_sum_11[25] ^ sigCSA_cry_11[24]))));
  assign sigCSA_sum_15[26] = sigCSA_sum_11[26] ^ sigCSA_cry_11[25] ^ sigCSA_sum_12[21];
  assign sigCSA_cry_15[26] = ((sigCSA_sum_11[26] & sigCSA_cry_11[25])) | ((sigCSA_sum_12[21] & ((sigCSA_sum_11[26] ^ sigCSA_cry_11[25]))));
  assign sigCSA_sum_15[27] = sigCSA_sum_11[27] ^ sigCSA_cry_11[26] ^ sigCSA_sum_12[22];
  assign sigCSA_cry_15[27] = ((sigCSA_sum_11[27] & sigCSA_cry_11[26])) | ((sigCSA_sum_12[22] & ((sigCSA_sum_11[27] ^ sigCSA_cry_11[26]))));
  assign sigCSA_sum_15[28] = sigCSA_sum_11[28] ^ sigCSA_cry_11[27] ^ sigCSA_sum_12[23];
  assign sigCSA_cry_15[28] = ((sigCSA_sum_11[28] & sigCSA_cry_11[27])) | ((sigCSA_sum_12[23] & ((sigCSA_sum_11[28] ^ sigCSA_cry_11[27]))));
  assign sigCSA_sum_15[29] = 1'b 0 ^ sigCSA_cry_11[28] ^ sigCSA_sum_12[24];
  assign sigCSA_cry_15[29] = ((1'b 0 & sigCSA_cry_11[28])) | ((sigCSA_sum_12[24] & ((1'b 0 ^ sigCSA_cry_11[28]))));
  assign sigCSA_sum_15[30] = 1'b 0 ^ 1'b 0 ^ sigCSA_sum_12[25];
  assign sigCSA_cry_15[30] = ((1'b 0 & 1'b 0)) | ((sigCSA_sum_12[25] & ((1'b 0 ^ 1'b 0))));
  assign sigCSA_sum_15[31] = 1'b 0 ^ 1'b 0 ^ sigCSA_sum_12[26];
  assign sigCSA_cry_15[31] = ((1'b 0 & 1'b 0)) | ((sigCSA_sum_12[26] & ((1'b 0 ^ 1'b 0))));
  assign sigCSA_sum_15[32] = 1'b 0 ^ 1'b 0 ^ sigCSA_sum_12[27];
  assign sigCSA_cry_15[32] = ((1'b 0 & 1'b 0)) | ((sigCSA_sum_12[27] & ((1'b 0 ^ 1'b 0))));
  assign sigCSA_sum_15[33] = 1'b 0 ^ 1'b 0 ^ sigCSA_sum_12[28];
  assign sigCSA_cry_15[33] = ((1'b 0 & 1'b 0)) | ((sigCSA_sum_12[28] & ((1'b 0 ^ 1'b 0))));
  // csa : 16
  // generating sigCSA_sum_16 and sigCSA_cry_16
  assign sigCSA_sum_16[0] = sigCSA_sum_13[0] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_16[0] = ((sigCSA_sum_13[0] & 1'b 0)) | ((1'b 0 & ((sigCSA_sum_13[0] ^ 1'b 0))));
  assign sigCSA_sum_16[1] = sigCSA_sum_13[1] ^ sigCSA_cry_13[0] ^ 1'b 0;
  assign sigCSA_cry_16[1] = ((sigCSA_sum_13[1] & sigCSA_cry_13[0])) | ((1'b 0 & ((sigCSA_sum_13[1] ^ sigCSA_cry_13[0]))));
  assign sigCSA_sum_16[2] = sigCSA_sum_13[2] ^ sigCSA_cry_13[1] ^ 1'b 0;
  assign sigCSA_cry_16[2] = ((sigCSA_sum_13[2] & sigCSA_cry_13[1])) | ((1'b 0 & ((sigCSA_sum_13[2] ^ sigCSA_cry_13[1]))));
  assign sigCSA_sum_16[3] = sigCSA_sum_13[3] ^ sigCSA_cry_13[2] ^ 1'b 0;
  assign sigCSA_cry_16[3] = ((sigCSA_sum_13[3] & sigCSA_cry_13[2])) | ((1'b 0 & ((sigCSA_sum_13[3] ^ sigCSA_cry_13[2]))));
  assign sigCSA_sum_16[4] = sigCSA_sum_13[4] ^ sigCSA_cry_13[3] ^ 1'b 0;
  assign sigCSA_cry_16[4] = ((sigCSA_sum_13[4] & sigCSA_cry_13[3])) | ((1'b 0 & ((sigCSA_sum_13[4] ^ sigCSA_cry_13[3]))));
  assign sigCSA_sum_16[5] = sigCSA_sum_13[5] ^ sigCSA_cry_13[4] ^ sigCSA_sum_14[0];
  assign sigCSA_cry_16[5] = ((sigCSA_sum_13[5] & sigCSA_cry_13[4])) | ((sigCSA_sum_14[0] & ((sigCSA_sum_13[5] ^ sigCSA_cry_13[4]))));
  assign sigCSA_sum_16[6] = sigCSA_sum_13[6] ^ sigCSA_cry_13[5] ^ sigCSA_sum_14[1];
  assign sigCSA_cry_16[6] = ((sigCSA_sum_13[6] & sigCSA_cry_13[5])) | ((sigCSA_sum_14[1] & ((sigCSA_sum_13[6] ^ sigCSA_cry_13[5]))));
  assign sigCSA_sum_16[7] = sigCSA_sum_13[7] ^ sigCSA_cry_13[6] ^ sigCSA_sum_14[2];
  assign sigCSA_cry_16[7] = ((sigCSA_sum_13[7] & sigCSA_cry_13[6])) | ((sigCSA_sum_14[2] & ((sigCSA_sum_13[7] ^ sigCSA_cry_13[6]))));
  assign sigCSA_sum_16[8] = sigCSA_sum_13[8] ^ sigCSA_cry_13[7] ^ sigCSA_sum_14[3];
  assign sigCSA_cry_16[8] = ((sigCSA_sum_13[8] & sigCSA_cry_13[7])) | ((sigCSA_sum_14[3] & ((sigCSA_sum_13[8] ^ sigCSA_cry_13[7]))));
  assign sigCSA_sum_16[9] = sigCSA_sum_13[9] ^ sigCSA_cry_13[8] ^ sigCSA_sum_14[4];
  assign sigCSA_cry_16[9] = ((sigCSA_sum_13[9] & sigCSA_cry_13[8])) | ((sigCSA_sum_14[4] & ((sigCSA_sum_13[9] ^ sigCSA_cry_13[8]))));
  assign sigCSA_sum_16[10] = sigCSA_sum_13[10] ^ sigCSA_cry_13[9] ^ sigCSA_sum_14[5];
  assign sigCSA_cry_16[10] = ((sigCSA_sum_13[10] & sigCSA_cry_13[9])) | ((sigCSA_sum_14[5] & ((sigCSA_sum_13[10] ^ sigCSA_cry_13[9]))));
  assign sigCSA_sum_16[11] = sigCSA_sum_13[11] ^ sigCSA_cry_13[10] ^ sigCSA_sum_14[6];
  assign sigCSA_cry_16[11] = ((sigCSA_sum_13[11] & sigCSA_cry_13[10])) | ((sigCSA_sum_14[6] & ((sigCSA_sum_13[11] ^ sigCSA_cry_13[10]))));
  assign sigCSA_sum_16[12] = sigCSA_sum_13[12] ^ sigCSA_cry_13[11] ^ sigCSA_sum_14[7];
  assign sigCSA_cry_16[12] = ((sigCSA_sum_13[12] & sigCSA_cry_13[11])) | ((sigCSA_sum_14[7] & ((sigCSA_sum_13[12] ^ sigCSA_cry_13[11]))));
  assign sigCSA_sum_16[13] = sigCSA_sum_13[13] ^ sigCSA_cry_13[12] ^ sigCSA_sum_14[8];
  assign sigCSA_cry_16[13] = ((sigCSA_sum_13[13] & sigCSA_cry_13[12])) | ((sigCSA_sum_14[8] & ((sigCSA_sum_13[13] ^ sigCSA_cry_13[12]))));
  assign sigCSA_sum_16[14] = sigCSA_sum_13[14] ^ sigCSA_cry_13[13] ^ sigCSA_sum_14[9];
  assign sigCSA_cry_16[14] = ((sigCSA_sum_13[14] & sigCSA_cry_13[13])) | ((sigCSA_sum_14[9] & ((sigCSA_sum_13[14] ^ sigCSA_cry_13[13]))));
  assign sigCSA_sum_16[15] = sigCSA_sum_13[15] ^ sigCSA_cry_13[14] ^ sigCSA_sum_14[10];
  assign sigCSA_cry_16[15] = ((sigCSA_sum_13[15] & sigCSA_cry_13[14])) | ((sigCSA_sum_14[10] & ((sigCSA_sum_13[15] ^ sigCSA_cry_13[14]))));
  assign sigCSA_sum_16[16] = sigCSA_sum_13[16] ^ sigCSA_cry_13[15] ^ sigCSA_sum_14[11];
  assign sigCSA_cry_16[16] = ((sigCSA_sum_13[16] & sigCSA_cry_13[15])) | ((sigCSA_sum_14[11] & ((sigCSA_sum_13[16] ^ sigCSA_cry_13[15]))));
  assign sigCSA_sum_16[17] = sigCSA_sum_13[17] ^ sigCSA_cry_13[16] ^ sigCSA_sum_14[12];
  assign sigCSA_cry_16[17] = ((sigCSA_sum_13[17] & sigCSA_cry_13[16])) | ((sigCSA_sum_14[12] & ((sigCSA_sum_13[17] ^ sigCSA_cry_13[16]))));
  assign sigCSA_sum_16[18] = sigCSA_sum_13[18] ^ sigCSA_cry_13[17] ^ sigCSA_sum_14[13];
  assign sigCSA_cry_16[18] = ((sigCSA_sum_13[18] & sigCSA_cry_13[17])) | ((sigCSA_sum_14[13] & ((sigCSA_sum_13[18] ^ sigCSA_cry_13[17]))));
  assign sigCSA_sum_16[19] = sigCSA_sum_13[19] ^ sigCSA_cry_13[18] ^ sigCSA_sum_14[14];
  assign sigCSA_cry_16[19] = ((sigCSA_sum_13[19] & sigCSA_cry_13[18])) | ((sigCSA_sum_14[14] & ((sigCSA_sum_13[19] ^ sigCSA_cry_13[18]))));
  assign sigCSA_sum_16[20] = sigCSA_sum_13[20] ^ sigCSA_cry_13[19] ^ sigCSA_sum_14[15];
  assign sigCSA_cry_16[20] = ((sigCSA_sum_13[20] & sigCSA_cry_13[19])) | ((sigCSA_sum_14[15] & ((sigCSA_sum_13[20] ^ sigCSA_cry_13[19]))));
  assign sigCSA_sum_16[21] = sigCSA_sum_13[21] ^ sigCSA_cry_13[20] ^ sigCSA_sum_14[16];
  assign sigCSA_cry_16[21] = ((sigCSA_sum_13[21] & sigCSA_cry_13[20])) | ((sigCSA_sum_14[16] & ((sigCSA_sum_13[21] ^ sigCSA_cry_13[20]))));
  assign sigCSA_sum_16[22] = sigCSA_sum_13[22] ^ sigCSA_cry_13[21] ^ sigCSA_sum_14[17];
  assign sigCSA_cry_16[22] = ((sigCSA_sum_13[22] & sigCSA_cry_13[21])) | ((sigCSA_sum_14[17] & ((sigCSA_sum_13[22] ^ sigCSA_cry_13[21]))));
  assign sigCSA_sum_16[23] = sigCSA_sum_13[23] ^ sigCSA_cry_13[22] ^ sigCSA_sum_14[18];
  assign sigCSA_cry_16[23] = ((sigCSA_sum_13[23] & sigCSA_cry_13[22])) | ((sigCSA_sum_14[18] & ((sigCSA_sum_13[23] ^ sigCSA_cry_13[22]))));
  assign sigCSA_sum_16[24] = sigCSA_sum_13[24] ^ sigCSA_cry_13[23] ^ sigCSA_sum_14[19];
  assign sigCSA_cry_16[24] = ((sigCSA_sum_13[24] & sigCSA_cry_13[23])) | ((sigCSA_sum_14[19] & ((sigCSA_sum_13[24] ^ sigCSA_cry_13[23]))));
  assign sigCSA_sum_16[25] = sigCSA_sum_13[25] ^ sigCSA_cry_13[24] ^ sigCSA_sum_14[20];
  assign sigCSA_cry_16[25] = ((sigCSA_sum_13[25] & sigCSA_cry_13[24])) | ((sigCSA_sum_14[20] & ((sigCSA_sum_13[25] ^ sigCSA_cry_13[24]))));
  assign sigCSA_sum_16[26] = sigCSA_sum_13[26] ^ sigCSA_cry_13[25] ^ sigCSA_sum_14[21];
  assign sigCSA_cry_16[26] = ((sigCSA_sum_13[26] & sigCSA_cry_13[25])) | ((sigCSA_sum_14[21] & ((sigCSA_sum_13[26] ^ sigCSA_cry_13[25]))));
  assign sigCSA_sum_16[27] = sigCSA_sum_13[27] ^ sigCSA_cry_13[26] ^ sigCSA_sum_14[22];
  assign sigCSA_cry_16[27] = ((sigCSA_sum_13[27] & sigCSA_cry_13[26])) | ((sigCSA_sum_14[22] & ((sigCSA_sum_13[27] ^ sigCSA_cry_13[26]))));
  assign sigCSA_sum_16[28] = sigCSA_sum_13[28] ^ sigCSA_cry_13[27] ^ sigCSA_sum_14[23];
  assign sigCSA_cry_16[28] = ((sigCSA_sum_13[28] & sigCSA_cry_13[27])) | ((sigCSA_sum_14[23] & ((sigCSA_sum_13[28] ^ sigCSA_cry_13[27]))));
  assign sigCSA_sum_16[29] = sigCSA_sum_13[29] ^ sigCSA_cry_13[28] ^ sigCSA_sum_14[24];
  assign sigCSA_cry_16[29] = ((sigCSA_sum_13[29] & sigCSA_cry_13[28])) | ((sigCSA_sum_14[24] & ((sigCSA_sum_13[29] ^ sigCSA_cry_13[28]))));
  assign sigCSA_sum_16[30] = sigCSA_sum_13[30] ^ sigCSA_cry_13[29] ^ sigCSA_sum_14[25];
  assign sigCSA_cry_16[30] = ((sigCSA_sum_13[30] & sigCSA_cry_13[29])) | ((sigCSA_sum_14[25] & ((sigCSA_sum_13[30] ^ sigCSA_cry_13[29]))));
  assign sigCSA_sum_16[31] = sigCSA_sum_13[31] ^ sigCSA_cry_13[30] ^ sigCSA_sum_14[26];
  assign sigCSA_cry_16[31] = ((sigCSA_sum_13[31] & sigCSA_cry_13[30])) | ((sigCSA_sum_14[26] & ((sigCSA_sum_13[31] ^ sigCSA_cry_13[30]))));
  assign sigCSA_sum_16[32] = sigCSA_sum_13[32] ^ sigCSA_cry_13[31] ^ sigCSA_sum_14[27];
  assign sigCSA_cry_16[32] = ((sigCSA_sum_13[32] & sigCSA_cry_13[31])) | ((sigCSA_sum_14[27] & ((sigCSA_sum_13[32] ^ sigCSA_cry_13[31]))));
  assign sigCSA_sum_16[33] = 1'b 0 ^ sigCSA_cry_13[32] ^ sigCSA_sum_14[28];
  assign sigCSA_cry_16[33] = ((1'b 0 & sigCSA_cry_13[32])) | ((sigCSA_sum_14[28] & ((1'b 0 ^ sigCSA_cry_13[32]))));
  assign sigCSA_sum_16[34] = 1'b 0 ^ 1'b 0 ^ sigCSA_sum_14[29];
  assign sigCSA_cry_16[34] = ((1'b 0 & 1'b 0)) | ((sigCSA_sum_14[29] & ((1'b 0 ^ 1'b 0))));
  assign sigCSA_sum_16[35] = 1'b 0 ^ 1'b 0 ^ sigCSA_sum_14[30];
  assign sigCSA_cry_16[35] = ((1'b 0 & 1'b 0)) | ((sigCSA_sum_14[30] & ((1'b 0 ^ 1'b 0))));
  assign sigCSA_sum_16[36] = 1'b 0 ^ 1'b 0 ^ sigCSA_sum_14[31];
  assign sigCSA_cry_16[36] = ((1'b 0 & 1'b 0)) | ((sigCSA_sum_14[31] & ((1'b 0 ^ 1'b 0))));
  assign sigCSA_sum_16[37] = 1'b 0 ^ 1'b 0 ^ sigCSA_sum_14[32];
  assign sigCSA_cry_16[37] = ((1'b 0 & 1'b 0)) | ((sigCSA_sum_14[32] & ((1'b 0 ^ 1'b 0))));
  assign sigCSA_sum_16[38] = 1'b 0 ^ 1'b 0 ^ sigCSA_sum_14[33];
  assign sigCSA_cry_16[38] = ((1'b 0 & 1'b 0)) | ((sigCSA_sum_14[33] & ((1'b 0 ^ 1'b 0))));
  // csa : 17
  // generating sigCSA_sum_17 and sigCSA_cry_17
  assign sigCSA_sum_17[0] = sigCSA_cry_14[0] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_17[0] = ((sigCSA_cry_14[0] & 1'b 0)) | ((1'b 0 & ((sigCSA_cry_14[0] ^ 1'b 0))));
  assign sigCSA_sum_17[1] = sigCSA_cry_14[1] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_17[1] = ((sigCSA_cry_14[1] & 1'b 0)) | ((1'b 0 & ((sigCSA_cry_14[1] ^ 1'b 0))));
  assign sigCSA_sum_17[2] = sigCSA_cry_14[2] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_17[2] = ((sigCSA_cry_14[2] & 1'b 0)) | ((1'b 0 & ((sigCSA_cry_14[2] ^ 1'b 0))));
  assign sigCSA_sum_17[3] = sigCSA_cry_14[3] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_17[3] = ((sigCSA_cry_14[3] & 1'b 0)) | ((1'b 0 & ((sigCSA_cry_14[3] ^ 1'b 0))));
  assign sigCSA_sum_17[4] = sigCSA_cry_14[4] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_17[4] = ((sigCSA_cry_14[4] & 1'b 0)) | ((1'b 0 & ((sigCSA_cry_14[4] ^ 1'b 0))));
  assign sigCSA_sum_17[5] = sigCSA_cry_14[5] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_17[5] = ((sigCSA_cry_14[5] & 1'b 0)) | ((1'b 0 & ((sigCSA_cry_14[5] ^ 1'b 0))));
  assign sigCSA_sum_17[6] = sigCSA_cry_14[6] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_17[6] = ((sigCSA_cry_14[6] & 1'b 0)) | ((1'b 0 & ((sigCSA_cry_14[6] ^ 1'b 0))));
  assign sigCSA_sum_17[7] = sigCSA_cry_14[7] ^ sigCSA_sum_15[0] ^ 1'b 0;
  assign sigCSA_cry_17[7] = ((sigCSA_cry_14[7] & sigCSA_sum_15[0])) | ((1'b 0 & ((sigCSA_cry_14[7] ^ sigCSA_sum_15[0]))));
  assign sigCSA_sum_17[8] = sigCSA_cry_14[8] ^ sigCSA_sum_15[1] ^ sigCSA_cry_15[0];
  assign sigCSA_cry_17[8] = ((sigCSA_cry_14[8] & sigCSA_sum_15[1])) | ((sigCSA_cry_15[0] & ((sigCSA_cry_14[8] ^ sigCSA_sum_15[1]))));
  assign sigCSA_sum_17[9] = sigCSA_cry_14[9] ^ sigCSA_sum_15[2] ^ sigCSA_cry_15[1];
  assign sigCSA_cry_17[9] = ((sigCSA_cry_14[9] & sigCSA_sum_15[2])) | ((sigCSA_cry_15[1] & ((sigCSA_cry_14[9] ^ sigCSA_sum_15[2]))));
  assign sigCSA_sum_17[10] = sigCSA_cry_14[10] ^ sigCSA_sum_15[3] ^ sigCSA_cry_15[2];
  assign sigCSA_cry_17[10] = ((sigCSA_cry_14[10] & sigCSA_sum_15[3])) | ((sigCSA_cry_15[2] & ((sigCSA_cry_14[10] ^ sigCSA_sum_15[3]))));
  assign sigCSA_sum_17[11] = sigCSA_cry_14[11] ^ sigCSA_sum_15[4] ^ sigCSA_cry_15[3];
  assign sigCSA_cry_17[11] = ((sigCSA_cry_14[11] & sigCSA_sum_15[4])) | ((sigCSA_cry_15[3] & ((sigCSA_cry_14[11] ^ sigCSA_sum_15[4]))));
  assign sigCSA_sum_17[12] = sigCSA_cry_14[12] ^ sigCSA_sum_15[5] ^ sigCSA_cry_15[4];
  assign sigCSA_cry_17[12] = ((sigCSA_cry_14[12] & sigCSA_sum_15[5])) | ((sigCSA_cry_15[4] & ((sigCSA_cry_14[12] ^ sigCSA_sum_15[5]))));
  assign sigCSA_sum_17[13] = sigCSA_cry_14[13] ^ sigCSA_sum_15[6] ^ sigCSA_cry_15[5];
  assign sigCSA_cry_17[13] = ((sigCSA_cry_14[13] & sigCSA_sum_15[6])) | ((sigCSA_cry_15[5] & ((sigCSA_cry_14[13] ^ sigCSA_sum_15[6]))));
  assign sigCSA_sum_17[14] = sigCSA_cry_14[14] ^ sigCSA_sum_15[7] ^ sigCSA_cry_15[6];
  assign sigCSA_cry_17[14] = ((sigCSA_cry_14[14] & sigCSA_sum_15[7])) | ((sigCSA_cry_15[6] & ((sigCSA_cry_14[14] ^ sigCSA_sum_15[7]))));
  assign sigCSA_sum_17[15] = sigCSA_cry_14[15] ^ sigCSA_sum_15[8] ^ sigCSA_cry_15[7];
  assign sigCSA_cry_17[15] = ((sigCSA_cry_14[15] & sigCSA_sum_15[8])) | ((sigCSA_cry_15[7] & ((sigCSA_cry_14[15] ^ sigCSA_sum_15[8]))));
  assign sigCSA_sum_17[16] = sigCSA_cry_14[16] ^ sigCSA_sum_15[9] ^ sigCSA_cry_15[8];
  assign sigCSA_cry_17[16] = ((sigCSA_cry_14[16] & sigCSA_sum_15[9])) | ((sigCSA_cry_15[8] & ((sigCSA_cry_14[16] ^ sigCSA_sum_15[9]))));
  assign sigCSA_sum_17[17] = sigCSA_cry_14[17] ^ sigCSA_sum_15[10] ^ sigCSA_cry_15[9];
  assign sigCSA_cry_17[17] = ((sigCSA_cry_14[17] & sigCSA_sum_15[10])) | ((sigCSA_cry_15[9] & ((sigCSA_cry_14[17] ^ sigCSA_sum_15[10]))));
  assign sigCSA_sum_17[18] = sigCSA_cry_14[18] ^ sigCSA_sum_15[11] ^ sigCSA_cry_15[10];
  assign sigCSA_cry_17[18] = ((sigCSA_cry_14[18] & sigCSA_sum_15[11])) | ((sigCSA_cry_15[10] & ((sigCSA_cry_14[18] ^ sigCSA_sum_15[11]))));
  assign sigCSA_sum_17[19] = sigCSA_cry_14[19] ^ sigCSA_sum_15[12] ^ sigCSA_cry_15[11];
  assign sigCSA_cry_17[19] = ((sigCSA_cry_14[19] & sigCSA_sum_15[12])) | ((sigCSA_cry_15[11] & ((sigCSA_cry_14[19] ^ sigCSA_sum_15[12]))));
  assign sigCSA_sum_17[20] = sigCSA_cry_14[20] ^ sigCSA_sum_15[13] ^ sigCSA_cry_15[12];
  assign sigCSA_cry_17[20] = ((sigCSA_cry_14[20] & sigCSA_sum_15[13])) | ((sigCSA_cry_15[12] & ((sigCSA_cry_14[20] ^ sigCSA_sum_15[13]))));
  assign sigCSA_sum_17[21] = sigCSA_cry_14[21] ^ sigCSA_sum_15[14] ^ sigCSA_cry_15[13];
  assign sigCSA_cry_17[21] = ((sigCSA_cry_14[21] & sigCSA_sum_15[14])) | ((sigCSA_cry_15[13] & ((sigCSA_cry_14[21] ^ sigCSA_sum_15[14]))));
  assign sigCSA_sum_17[22] = sigCSA_cry_14[22] ^ sigCSA_sum_15[15] ^ sigCSA_cry_15[14];
  assign sigCSA_cry_17[22] = ((sigCSA_cry_14[22] & sigCSA_sum_15[15])) | ((sigCSA_cry_15[14] & ((sigCSA_cry_14[22] ^ sigCSA_sum_15[15]))));
  assign sigCSA_sum_17[23] = sigCSA_cry_14[23] ^ sigCSA_sum_15[16] ^ sigCSA_cry_15[15];
  assign sigCSA_cry_17[23] = ((sigCSA_cry_14[23] & sigCSA_sum_15[16])) | ((sigCSA_cry_15[15] & ((sigCSA_cry_14[23] ^ sigCSA_sum_15[16]))));
  assign sigCSA_sum_17[24] = sigCSA_cry_14[24] ^ sigCSA_sum_15[17] ^ sigCSA_cry_15[16];
  assign sigCSA_cry_17[24] = ((sigCSA_cry_14[24] & sigCSA_sum_15[17])) | ((sigCSA_cry_15[16] & ((sigCSA_cry_14[24] ^ sigCSA_sum_15[17]))));
  assign sigCSA_sum_17[25] = sigCSA_cry_14[25] ^ sigCSA_sum_15[18] ^ sigCSA_cry_15[17];
  assign sigCSA_cry_17[25] = ((sigCSA_cry_14[25] & sigCSA_sum_15[18])) | ((sigCSA_cry_15[17] & ((sigCSA_cry_14[25] ^ sigCSA_sum_15[18]))));
  assign sigCSA_sum_17[26] = sigCSA_cry_14[26] ^ sigCSA_sum_15[19] ^ sigCSA_cry_15[18];
  assign sigCSA_cry_17[26] = ((sigCSA_cry_14[26] & sigCSA_sum_15[19])) | ((sigCSA_cry_15[18] & ((sigCSA_cry_14[26] ^ sigCSA_sum_15[19]))));
  assign sigCSA_sum_17[27] = sigCSA_cry_14[27] ^ sigCSA_sum_15[20] ^ sigCSA_cry_15[19];
  assign sigCSA_cry_17[27] = ((sigCSA_cry_14[27] & sigCSA_sum_15[20])) | ((sigCSA_cry_15[19] & ((sigCSA_cry_14[27] ^ sigCSA_sum_15[20]))));
  assign sigCSA_sum_17[28] = sigCSA_cry_14[28] ^ sigCSA_sum_15[21] ^ sigCSA_cry_15[20];
  assign sigCSA_cry_17[28] = ((sigCSA_cry_14[28] & sigCSA_sum_15[21])) | ((sigCSA_cry_15[20] & ((sigCSA_cry_14[28] ^ sigCSA_sum_15[21]))));
  assign sigCSA_sum_17[29] = sigCSA_cry_14[29] ^ sigCSA_sum_15[22] ^ sigCSA_cry_15[21];
  assign sigCSA_cry_17[29] = ((sigCSA_cry_14[29] & sigCSA_sum_15[22])) | ((sigCSA_cry_15[21] & ((sigCSA_cry_14[29] ^ sigCSA_sum_15[22]))));
  assign sigCSA_sum_17[30] = sigCSA_cry_14[30] ^ sigCSA_sum_15[23] ^ sigCSA_cry_15[22];
  assign sigCSA_cry_17[30] = ((sigCSA_cry_14[30] & sigCSA_sum_15[23])) | ((sigCSA_cry_15[22] & ((sigCSA_cry_14[30] ^ sigCSA_sum_15[23]))));
  assign sigCSA_sum_17[31] = sigCSA_cry_14[31] ^ sigCSA_sum_15[24] ^ sigCSA_cry_15[23];
  assign sigCSA_cry_17[31] = ((sigCSA_cry_14[31] & sigCSA_sum_15[24])) | ((sigCSA_cry_15[23] & ((sigCSA_cry_14[31] ^ sigCSA_sum_15[24]))));
  assign sigCSA_sum_17[32] = sigCSA_cry_14[32] ^ sigCSA_sum_15[25] ^ sigCSA_cry_15[24];
  assign sigCSA_cry_17[32] = ((sigCSA_cry_14[32] & sigCSA_sum_15[25])) | ((sigCSA_cry_15[24] & ((sigCSA_cry_14[32] ^ sigCSA_sum_15[25]))));
  assign sigCSA_sum_17[33] = sigCSA_cry_14[33] ^ sigCSA_sum_15[26] ^ sigCSA_cry_15[25];
  assign sigCSA_cry_17[33] = ((sigCSA_cry_14[33] & sigCSA_sum_15[26])) | ((sigCSA_cry_15[25] & ((sigCSA_cry_14[33] ^ sigCSA_sum_15[26]))));
  assign sigCSA_sum_17[34] = 1'b 0 ^ sigCSA_sum_15[27] ^ sigCSA_cry_15[26];
  assign sigCSA_cry_17[34] = ((1'b 0 & sigCSA_sum_15[27])) | ((sigCSA_cry_15[26] & ((1'b 0 ^ sigCSA_sum_15[27]))));
  assign sigCSA_sum_17[35] = 1'b 0 ^ sigCSA_sum_15[28] ^ sigCSA_cry_15[27];
  assign sigCSA_cry_17[35] = ((1'b 0 & sigCSA_sum_15[28])) | ((sigCSA_cry_15[27] & ((1'b 0 ^ sigCSA_sum_15[28]))));
  assign sigCSA_sum_17[36] = 1'b 0 ^ sigCSA_sum_15[29] ^ sigCSA_cry_15[28];
  assign sigCSA_cry_17[36] = ((1'b 0 & sigCSA_sum_15[29])) | ((sigCSA_cry_15[28] & ((1'b 0 ^ sigCSA_sum_15[29]))));
  assign sigCSA_sum_17[37] = 1'b 0 ^ sigCSA_sum_15[30] ^ sigCSA_cry_15[29];
  assign sigCSA_cry_17[37] = ((1'b 0 & sigCSA_sum_15[30])) | ((sigCSA_cry_15[29] & ((1'b 0 ^ sigCSA_sum_15[30]))));
  assign sigCSA_sum_17[38] = 1'b 0 ^ sigCSA_sum_15[31] ^ sigCSA_cry_15[30];
  assign sigCSA_cry_17[38] = ((1'b 0 & sigCSA_sum_15[31])) | ((sigCSA_cry_15[30] & ((1'b 0 ^ sigCSA_sum_15[31]))));
  assign sigCSA_sum_17[39] = 1'b 0 ^ sigCSA_sum_15[32] ^ sigCSA_cry_15[31];
  assign sigCSA_cry_17[39] = ((1'b 0 & sigCSA_sum_15[32])) | ((sigCSA_cry_15[31] & ((1'b 0 ^ sigCSA_sum_15[32]))));
  assign sigCSA_sum_17[40] = 1'b 0 ^ sigCSA_sum_15[33] ^ sigCSA_cry_15[32];
  assign sigCSA_cry_17[40] = ((1'b 0 & sigCSA_sum_15[33])) | ((sigCSA_cry_15[32] & ((1'b 0 ^ sigCSA_sum_15[33]))));
  assign sigCSA_sum_17[41] = 1'b 0 ^ 1'b 0 ^ sigCSA_cry_15[33];
  assign sigCSA_cry_17[41] = ((1'b 0 & 1'b 0)) | ((sigCSA_cry_15[33] & ((1'b 0 ^ 1'b 0))));
  // csa : 18
  // generating sigCSA_sum_18 and sigCSA_cry_18
  assign sigCSA_sum_18[0] = sigCSA_sum_16[0] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_18[0] = ((sigCSA_sum_16[0] & 1'b 0)) | ((1'b 0 & ((sigCSA_sum_16[0] ^ 1'b 0))));
  assign sigCSA_sum_18[1] = sigCSA_sum_16[1] ^ sigCSA_cry_16[0] ^ 1'b 0;
  assign sigCSA_cry_18[1] = ((sigCSA_sum_16[1] & sigCSA_cry_16[0])) | ((1'b 0 & ((sigCSA_sum_16[1] ^ sigCSA_cry_16[0]))));
  assign sigCSA_sum_18[2] = sigCSA_sum_16[2] ^ sigCSA_cry_16[1] ^ 1'b 0;
  assign sigCSA_cry_18[2] = ((sigCSA_sum_16[2] & sigCSA_cry_16[1])) | ((1'b 0 & ((sigCSA_sum_16[2] ^ sigCSA_cry_16[1]))));
  assign sigCSA_sum_18[3] = sigCSA_sum_16[3] ^ sigCSA_cry_16[2] ^ 1'b 0;
  assign sigCSA_cry_18[3] = ((sigCSA_sum_16[3] & sigCSA_cry_16[2])) | ((1'b 0 & ((sigCSA_sum_16[3] ^ sigCSA_cry_16[2]))));
  assign sigCSA_sum_18[4] = sigCSA_sum_16[4] ^ sigCSA_cry_16[3] ^ 1'b 0;
  assign sigCSA_cry_18[4] = ((sigCSA_sum_16[4] & sigCSA_cry_16[3])) | ((1'b 0 & ((sigCSA_sum_16[4] ^ sigCSA_cry_16[3]))));
  assign sigCSA_sum_18[5] = sigCSA_sum_16[5] ^ sigCSA_cry_16[4] ^ 1'b 0;
  assign sigCSA_cry_18[5] = ((sigCSA_sum_16[5] & sigCSA_cry_16[4])) | ((1'b 0 & ((sigCSA_sum_16[5] ^ sigCSA_cry_16[4]))));
  assign sigCSA_sum_18[6] = sigCSA_sum_16[6] ^ sigCSA_cry_16[5] ^ sigCSA_sum_17[0];
  assign sigCSA_cry_18[6] = ((sigCSA_sum_16[6] & sigCSA_cry_16[5])) | ((sigCSA_sum_17[0] & ((sigCSA_sum_16[6] ^ sigCSA_cry_16[5]))));
  assign sigCSA_sum_18[7] = sigCSA_sum_16[7] ^ sigCSA_cry_16[6] ^ sigCSA_sum_17[1];
  assign sigCSA_cry_18[7] = ((sigCSA_sum_16[7] & sigCSA_cry_16[6])) | ((sigCSA_sum_17[1] & ((sigCSA_sum_16[7] ^ sigCSA_cry_16[6]))));
  assign sigCSA_sum_18[8] = sigCSA_sum_16[8] ^ sigCSA_cry_16[7] ^ sigCSA_sum_17[2];
  assign sigCSA_cry_18[8] = ((sigCSA_sum_16[8] & sigCSA_cry_16[7])) | ((sigCSA_sum_17[2] & ((sigCSA_sum_16[8] ^ sigCSA_cry_16[7]))));
  assign sigCSA_sum_18[9] = sigCSA_sum_16[9] ^ sigCSA_cry_16[8] ^ sigCSA_sum_17[3];
  assign sigCSA_cry_18[9] = ((sigCSA_sum_16[9] & sigCSA_cry_16[8])) | ((sigCSA_sum_17[3] & ((sigCSA_sum_16[9] ^ sigCSA_cry_16[8]))));
  assign sigCSA_sum_18[10] = sigCSA_sum_16[10] ^ sigCSA_cry_16[9] ^ sigCSA_sum_17[4];
  assign sigCSA_cry_18[10] = ((sigCSA_sum_16[10] & sigCSA_cry_16[9])) | ((sigCSA_sum_17[4] & ((sigCSA_sum_16[10] ^ sigCSA_cry_16[9]))));
  assign sigCSA_sum_18[11] = sigCSA_sum_16[11] ^ sigCSA_cry_16[10] ^ sigCSA_sum_17[5];
  assign sigCSA_cry_18[11] = ((sigCSA_sum_16[11] & sigCSA_cry_16[10])) | ((sigCSA_sum_17[5] & ((sigCSA_sum_16[11] ^ sigCSA_cry_16[10]))));
  assign sigCSA_sum_18[12] = sigCSA_sum_16[12] ^ sigCSA_cry_16[11] ^ sigCSA_sum_17[6];
  assign sigCSA_cry_18[12] = ((sigCSA_sum_16[12] & sigCSA_cry_16[11])) | ((sigCSA_sum_17[6] & ((sigCSA_sum_16[12] ^ sigCSA_cry_16[11]))));
  assign sigCSA_sum_18[13] = sigCSA_sum_16[13] ^ sigCSA_cry_16[12] ^ sigCSA_sum_17[7];
  assign sigCSA_cry_18[13] = ((sigCSA_sum_16[13] & sigCSA_cry_16[12])) | ((sigCSA_sum_17[7] & ((sigCSA_sum_16[13] ^ sigCSA_cry_16[12]))));
  assign sigCSA_sum_18[14] = sigCSA_sum_16[14] ^ sigCSA_cry_16[13] ^ sigCSA_sum_17[8];
  assign sigCSA_cry_18[14] = ((sigCSA_sum_16[14] & sigCSA_cry_16[13])) | ((sigCSA_sum_17[8] & ((sigCSA_sum_16[14] ^ sigCSA_cry_16[13]))));
  assign sigCSA_sum_18[15] = sigCSA_sum_16[15] ^ sigCSA_cry_16[14] ^ sigCSA_sum_17[9];
  assign sigCSA_cry_18[15] = ((sigCSA_sum_16[15] & sigCSA_cry_16[14])) | ((sigCSA_sum_17[9] & ((sigCSA_sum_16[15] ^ sigCSA_cry_16[14]))));
  assign sigCSA_sum_18[16] = sigCSA_sum_16[16] ^ sigCSA_cry_16[15] ^ sigCSA_sum_17[10];
  assign sigCSA_cry_18[16] = ((sigCSA_sum_16[16] & sigCSA_cry_16[15])) | ((sigCSA_sum_17[10] & ((sigCSA_sum_16[16] ^ sigCSA_cry_16[15]))));
  assign sigCSA_sum_18[17] = sigCSA_sum_16[17] ^ sigCSA_cry_16[16] ^ sigCSA_sum_17[11];
  assign sigCSA_cry_18[17] = ((sigCSA_sum_16[17] & sigCSA_cry_16[16])) | ((sigCSA_sum_17[11] & ((sigCSA_sum_16[17] ^ sigCSA_cry_16[16]))));
  assign sigCSA_sum_18[18] = sigCSA_sum_16[18] ^ sigCSA_cry_16[17] ^ sigCSA_sum_17[12];
  assign sigCSA_cry_18[18] = ((sigCSA_sum_16[18] & sigCSA_cry_16[17])) | ((sigCSA_sum_17[12] & ((sigCSA_sum_16[18] ^ sigCSA_cry_16[17]))));
  assign sigCSA_sum_18[19] = sigCSA_sum_16[19] ^ sigCSA_cry_16[18] ^ sigCSA_sum_17[13];
  assign sigCSA_cry_18[19] = ((sigCSA_sum_16[19] & sigCSA_cry_16[18])) | ((sigCSA_sum_17[13] & ((sigCSA_sum_16[19] ^ sigCSA_cry_16[18]))));
  assign sigCSA_sum_18[20] = sigCSA_sum_16[20] ^ sigCSA_cry_16[19] ^ sigCSA_sum_17[14];
  assign sigCSA_cry_18[20] = ((sigCSA_sum_16[20] & sigCSA_cry_16[19])) | ((sigCSA_sum_17[14] & ((sigCSA_sum_16[20] ^ sigCSA_cry_16[19]))));
  assign sigCSA_sum_18[21] = sigCSA_sum_16[21] ^ sigCSA_cry_16[20] ^ sigCSA_sum_17[15];
  assign sigCSA_cry_18[21] = ((sigCSA_sum_16[21] & sigCSA_cry_16[20])) | ((sigCSA_sum_17[15] & ((sigCSA_sum_16[21] ^ sigCSA_cry_16[20]))));
  assign sigCSA_sum_18[22] = sigCSA_sum_16[22] ^ sigCSA_cry_16[21] ^ sigCSA_sum_17[16];
  assign sigCSA_cry_18[22] = ((sigCSA_sum_16[22] & sigCSA_cry_16[21])) | ((sigCSA_sum_17[16] & ((sigCSA_sum_16[22] ^ sigCSA_cry_16[21]))));
  assign sigCSA_sum_18[23] = sigCSA_sum_16[23] ^ sigCSA_cry_16[22] ^ sigCSA_sum_17[17];
  assign sigCSA_cry_18[23] = ((sigCSA_sum_16[23] & sigCSA_cry_16[22])) | ((sigCSA_sum_17[17] & ((sigCSA_sum_16[23] ^ sigCSA_cry_16[22]))));
  assign sigCSA_sum_18[24] = sigCSA_sum_16[24] ^ sigCSA_cry_16[23] ^ sigCSA_sum_17[18];
  assign sigCSA_cry_18[24] = ((sigCSA_sum_16[24] & sigCSA_cry_16[23])) | ((sigCSA_sum_17[18] & ((sigCSA_sum_16[24] ^ sigCSA_cry_16[23]))));
  assign sigCSA_sum_18[25] = sigCSA_sum_16[25] ^ sigCSA_cry_16[24] ^ sigCSA_sum_17[19];
  assign sigCSA_cry_18[25] = ((sigCSA_sum_16[25] & sigCSA_cry_16[24])) | ((sigCSA_sum_17[19] & ((sigCSA_sum_16[25] ^ sigCSA_cry_16[24]))));
  assign sigCSA_sum_18[26] = sigCSA_sum_16[26] ^ sigCSA_cry_16[25] ^ sigCSA_sum_17[20];
  assign sigCSA_cry_18[26] = ((sigCSA_sum_16[26] & sigCSA_cry_16[25])) | ((sigCSA_sum_17[20] & ((sigCSA_sum_16[26] ^ sigCSA_cry_16[25]))));
  assign sigCSA_sum_18[27] = sigCSA_sum_16[27] ^ sigCSA_cry_16[26] ^ sigCSA_sum_17[21];
  assign sigCSA_cry_18[27] = ((sigCSA_sum_16[27] & sigCSA_cry_16[26])) | ((sigCSA_sum_17[21] & ((sigCSA_sum_16[27] ^ sigCSA_cry_16[26]))));
  assign sigCSA_sum_18[28] = sigCSA_sum_16[28] ^ sigCSA_cry_16[27] ^ sigCSA_sum_17[22];
  assign sigCSA_cry_18[28] = ((sigCSA_sum_16[28] & sigCSA_cry_16[27])) | ((sigCSA_sum_17[22] & ((sigCSA_sum_16[28] ^ sigCSA_cry_16[27]))));
  assign sigCSA_sum_18[29] = sigCSA_sum_16[29] ^ sigCSA_cry_16[28] ^ sigCSA_sum_17[23];
  assign sigCSA_cry_18[29] = ((sigCSA_sum_16[29] & sigCSA_cry_16[28])) | ((sigCSA_sum_17[23] & ((sigCSA_sum_16[29] ^ sigCSA_cry_16[28]))));
  assign sigCSA_sum_18[30] = sigCSA_sum_16[30] ^ sigCSA_cry_16[29] ^ sigCSA_sum_17[24];
  assign sigCSA_cry_18[30] = ((sigCSA_sum_16[30] & sigCSA_cry_16[29])) | ((sigCSA_sum_17[24] & ((sigCSA_sum_16[30] ^ sigCSA_cry_16[29]))));
  assign sigCSA_sum_18[31] = sigCSA_sum_16[31] ^ sigCSA_cry_16[30] ^ sigCSA_sum_17[25];
  assign sigCSA_cry_18[31] = ((sigCSA_sum_16[31] & sigCSA_cry_16[30])) | ((sigCSA_sum_17[25] & ((sigCSA_sum_16[31] ^ sigCSA_cry_16[30]))));
  assign sigCSA_sum_18[32] = sigCSA_sum_16[32] ^ sigCSA_cry_16[31] ^ sigCSA_sum_17[26];
  assign sigCSA_cry_18[32] = ((sigCSA_sum_16[32] & sigCSA_cry_16[31])) | ((sigCSA_sum_17[26] & ((sigCSA_sum_16[32] ^ sigCSA_cry_16[31]))));
  assign sigCSA_sum_18[33] = sigCSA_sum_16[33] ^ sigCSA_cry_16[32] ^ sigCSA_sum_17[27];
  assign sigCSA_cry_18[33] = ((sigCSA_sum_16[33] & sigCSA_cry_16[32])) | ((sigCSA_sum_17[27] & ((sigCSA_sum_16[33] ^ sigCSA_cry_16[32]))));
  assign sigCSA_sum_18[34] = sigCSA_sum_16[34] ^ sigCSA_cry_16[33] ^ sigCSA_sum_17[28];
  assign sigCSA_cry_18[34] = ((sigCSA_sum_16[34] & sigCSA_cry_16[33])) | ((sigCSA_sum_17[28] & ((sigCSA_sum_16[34] ^ sigCSA_cry_16[33]))));
  assign sigCSA_sum_18[35] = sigCSA_sum_16[35] ^ sigCSA_cry_16[34] ^ sigCSA_sum_17[29];
  assign sigCSA_cry_18[35] = ((sigCSA_sum_16[35] & sigCSA_cry_16[34])) | ((sigCSA_sum_17[29] & ((sigCSA_sum_16[35] ^ sigCSA_cry_16[34]))));
  assign sigCSA_sum_18[36] = sigCSA_sum_16[36] ^ sigCSA_cry_16[35] ^ sigCSA_sum_17[30];
  assign sigCSA_cry_18[36] = ((sigCSA_sum_16[36] & sigCSA_cry_16[35])) | ((sigCSA_sum_17[30] & ((sigCSA_sum_16[36] ^ sigCSA_cry_16[35]))));
  assign sigCSA_sum_18[37] = sigCSA_sum_16[37] ^ sigCSA_cry_16[36] ^ sigCSA_sum_17[31];
  assign sigCSA_cry_18[37] = ((sigCSA_sum_16[37] & sigCSA_cry_16[36])) | ((sigCSA_sum_17[31] & ((sigCSA_sum_16[37] ^ sigCSA_cry_16[36]))));
  assign sigCSA_sum_18[38] = sigCSA_sum_16[38] ^ sigCSA_cry_16[37] ^ sigCSA_sum_17[32];
  assign sigCSA_cry_18[38] = ((sigCSA_sum_16[38] & sigCSA_cry_16[37])) | ((sigCSA_sum_17[32] & ((sigCSA_sum_16[38] ^ sigCSA_cry_16[37]))));
  assign sigCSA_sum_18[39] = 1'b 0 ^ sigCSA_cry_16[38] ^ sigCSA_sum_17[33];
  assign sigCSA_cry_18[39] = ((1'b 0 & sigCSA_cry_16[38])) | ((sigCSA_sum_17[33] & ((1'b 0 ^ sigCSA_cry_16[38]))));
  assign sigCSA_sum_18[40] = 1'b 0 ^ 1'b 0 ^ sigCSA_sum_17[34];
  assign sigCSA_cry_18[40] = ((1'b 0 & 1'b 0)) | ((sigCSA_sum_17[34] & ((1'b 0 ^ 1'b 0))));
  assign sigCSA_sum_18[41] = 1'b 0 ^ 1'b 0 ^ sigCSA_sum_17[35];
  assign sigCSA_cry_18[41] = ((1'b 0 & 1'b 0)) | ((sigCSA_sum_17[35] & ((1'b 0 ^ 1'b 0))));
  assign sigCSA_sum_18[42] = 1'b 0 ^ 1'b 0 ^ sigCSA_sum_17[36];
  assign sigCSA_cry_18[42] = ((1'b 0 & 1'b 0)) | ((sigCSA_sum_17[36] & ((1'b 0 ^ 1'b 0))));
  assign sigCSA_sum_18[43] = 1'b 0 ^ 1'b 0 ^ sigCSA_sum_17[37];
  assign sigCSA_cry_18[43] = ((1'b 0 & 1'b 0)) | ((sigCSA_sum_17[37] & ((1'b 0 ^ 1'b 0))));
  assign sigCSA_sum_18[44] = 1'b 0 ^ 1'b 0 ^ sigCSA_sum_17[38];
  assign sigCSA_cry_18[44] = ((1'b 0 & 1'b 0)) | ((sigCSA_sum_17[38] & ((1'b 0 ^ 1'b 0))));
  assign sigCSA_sum_18[45] = 1'b 0 ^ 1'b 0 ^ sigCSA_sum_17[39];
  assign sigCSA_cry_18[45] = ((1'b 0 & 1'b 0)) | ((sigCSA_sum_17[39] & ((1'b 0 ^ 1'b 0))));
  assign sigCSA_sum_18[46] = 1'b 0 ^ 1'b 0 ^ sigCSA_sum_17[40];
  assign sigCSA_cry_18[46] = ((1'b 0 & 1'b 0)) | ((sigCSA_sum_17[40] & ((1'b 0 ^ 1'b 0))));
  assign sigCSA_sum_18[47] = 1'b 0 ^ 1'b 0 ^ sigCSA_sum_17[41];
  assign sigCSA_cry_18[47] = ((1'b 0 & 1'b 0)) | ((sigCSA_sum_17[41] & ((1'b 0 ^ 1'b 0))));
  // csa : 19
  // generating sigCSA_sum_19 and sigCSA_cry_19
  assign sigCSA_sum_19[0] = sigCSA_cry_17[0] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_19[0] = ((sigCSA_cry_17[0] & 1'b 0)) | ((1'b 0 & ((sigCSA_cry_17[0] ^ 1'b 0))));
  assign sigCSA_sum_19[1] = sigCSA_cry_17[1] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_19[1] = ((sigCSA_cry_17[1] & 1'b 0)) | ((1'b 0 & ((sigCSA_cry_17[1] ^ 1'b 0))));
  assign sigCSA_sum_19[2] = sigCSA_cry_17[2] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_19[2] = ((sigCSA_cry_17[2] & 1'b 0)) | ((1'b 0 & ((sigCSA_cry_17[2] ^ 1'b 0))));
  assign sigCSA_sum_19[3] = sigCSA_cry_17[3] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_19[3] = ((sigCSA_cry_17[3] & 1'b 0)) | ((1'b 0 & ((sigCSA_cry_17[3] ^ 1'b 0))));
  assign sigCSA_sum_19[4] = sigCSA_cry_17[4] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_19[4] = ((sigCSA_cry_17[4] & 1'b 0)) | ((1'b 0 & ((sigCSA_cry_17[4] ^ 1'b 0))));
  assign sigCSA_sum_19[5] = sigCSA_cry_17[5] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_19[5] = ((sigCSA_cry_17[5] & 1'b 0)) | ((1'b 0 & ((sigCSA_cry_17[5] ^ 1'b 0))));
  assign sigCSA_sum_19[6] = sigCSA_cry_17[6] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_19[6] = ((sigCSA_cry_17[6] & 1'b 0)) | ((1'b 0 & ((sigCSA_cry_17[6] ^ 1'b 0))));
  assign sigCSA_sum_19[7] = sigCSA_cry_17[7] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_19[7] = ((sigCSA_cry_17[7] & 1'b 0)) | ((1'b 0 & ((sigCSA_cry_17[7] ^ 1'b 0))));
  assign sigCSA_sum_19[8] = sigCSA_cry_17[8] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_19[8] = ((sigCSA_cry_17[8] & 1'b 0)) | ((1'b 0 & ((sigCSA_cry_17[8] ^ 1'b 0))));
  assign sigCSA_sum_19[9] = sigCSA_cry_17[9] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_19[9] = ((sigCSA_cry_17[9] & 1'b 0)) | ((1'b 0 & ((sigCSA_cry_17[9] ^ 1'b 0))));
  assign sigCSA_sum_19[10] = sigCSA_cry_17[10] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_19[10] = ((sigCSA_cry_17[10] & 1'b 0)) | ((1'b 0 & ((sigCSA_cry_17[10] ^ 1'b 0))));
  assign sigCSA_sum_19[11] = sigCSA_cry_17[11] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_19[11] = ((sigCSA_cry_17[11] & 1'b 0)) | ((1'b 0 & ((sigCSA_cry_17[11] ^ 1'b 0))));
  assign sigCSA_sum_19[12] = sigCSA_cry_17[12] ^ sigCSA_cry_12[0] ^ 1'b 0;
  assign sigCSA_cry_19[12] = ((sigCSA_cry_17[12] & sigCSA_cry_12[0])) | ((1'b 0 & ((sigCSA_cry_17[12] ^ sigCSA_cry_12[0]))));
  assign sigCSA_sum_19[13] = sigCSA_cry_17[13] ^ sigCSA_cry_12[1] ^ 1'b 0;
  assign sigCSA_cry_19[13] = ((sigCSA_cry_17[13] & sigCSA_cry_12[1])) | ((1'b 0 & ((sigCSA_cry_17[13] ^ sigCSA_cry_12[1]))));
  assign sigCSA_sum_19[14] = sigCSA_cry_17[14] ^ sigCSA_cry_12[2] ^ 1'b 0;
  assign sigCSA_cry_19[14] = ((sigCSA_cry_17[14] & sigCSA_cry_12[2])) | ((1'b 0 & ((sigCSA_cry_17[14] ^ sigCSA_cry_12[2]))));
  assign sigCSA_sum_19[15] = sigCSA_cry_17[15] ^ sigCSA_cry_12[3] ^ sigCSA_cry_7[0];
  assign sigCSA_cry_19[15] = ((sigCSA_cry_17[15] & sigCSA_cry_12[3])) | ((sigCSA_cry_7[0] & ((sigCSA_cry_17[15] ^ sigCSA_cry_12[3]))));
  assign sigCSA_sum_19[16] = sigCSA_cry_17[16] ^ sigCSA_cry_12[4] ^ sigCSA_cry_7[1];
  assign sigCSA_cry_19[16] = ((sigCSA_cry_17[16] & sigCSA_cry_12[4])) | ((sigCSA_cry_7[1] & ((sigCSA_cry_17[16] ^ sigCSA_cry_12[4]))));
  assign sigCSA_sum_19[17] = sigCSA_cry_17[17] ^ sigCSA_cry_12[5] ^ sigCSA_cry_7[2];
  assign sigCSA_cry_19[17] = ((sigCSA_cry_17[17] & sigCSA_cry_12[5])) | ((sigCSA_cry_7[2] & ((sigCSA_cry_17[17] ^ sigCSA_cry_12[5]))));
  assign sigCSA_sum_19[18] = sigCSA_cry_17[18] ^ sigCSA_cry_12[6] ^ sigCSA_cry_7[3];
  assign sigCSA_cry_19[18] = ((sigCSA_cry_17[18] & sigCSA_cry_12[6])) | ((sigCSA_cry_7[3] & ((sigCSA_cry_17[18] ^ sigCSA_cry_12[6]))));
  assign sigCSA_sum_19[19] = sigCSA_cry_17[19] ^ sigCSA_cry_12[7] ^ sigCSA_cry_7[4];
  assign sigCSA_cry_19[19] = ((sigCSA_cry_17[19] & sigCSA_cry_12[7])) | ((sigCSA_cry_7[4] & ((sigCSA_cry_17[19] ^ sigCSA_cry_12[7]))));
  assign sigCSA_sum_19[20] = sigCSA_cry_17[20] ^ sigCSA_cry_12[8] ^ sigCSA_cry_7[5];
  assign sigCSA_cry_19[20] = ((sigCSA_cry_17[20] & sigCSA_cry_12[8])) | ((sigCSA_cry_7[5] & ((sigCSA_cry_17[20] ^ sigCSA_cry_12[8]))));
  assign sigCSA_sum_19[21] = sigCSA_cry_17[21] ^ sigCSA_cry_12[9] ^ sigCSA_cry_7[6];
  assign sigCSA_cry_19[21] = ((sigCSA_cry_17[21] & sigCSA_cry_12[9])) | ((sigCSA_cry_7[6] & ((sigCSA_cry_17[21] ^ sigCSA_cry_12[9]))));
  assign sigCSA_sum_19[22] = sigCSA_cry_17[22] ^ sigCSA_cry_12[10] ^ sigCSA_cry_7[7];
  assign sigCSA_cry_19[22] = ((sigCSA_cry_17[22] & sigCSA_cry_12[10])) | ((sigCSA_cry_7[7] & ((sigCSA_cry_17[22] ^ sigCSA_cry_12[10]))));
  assign sigCSA_sum_19[23] = sigCSA_cry_17[23] ^ sigCSA_cry_12[11] ^ sigCSA_cry_7[8];
  assign sigCSA_cry_19[23] = ((sigCSA_cry_17[23] & sigCSA_cry_12[11])) | ((sigCSA_cry_7[8] & ((sigCSA_cry_17[23] ^ sigCSA_cry_12[11]))));
  assign sigCSA_sum_19[24] = sigCSA_cry_17[24] ^ sigCSA_cry_12[12] ^ sigCSA_cry_7[9];
  assign sigCSA_cry_19[24] = ((sigCSA_cry_17[24] & sigCSA_cry_12[12])) | ((sigCSA_cry_7[9] & ((sigCSA_cry_17[24] ^ sigCSA_cry_12[12]))));
  assign sigCSA_sum_19[25] = sigCSA_cry_17[25] ^ sigCSA_cry_12[13] ^ sigCSA_cry_7[10];
  assign sigCSA_cry_19[25] = ((sigCSA_cry_17[25] & sigCSA_cry_12[13])) | ((sigCSA_cry_7[10] & ((sigCSA_cry_17[25] ^ sigCSA_cry_12[13]))));
  assign sigCSA_sum_19[26] = sigCSA_cry_17[26] ^ sigCSA_cry_12[14] ^ sigCSA_cry_7[11];
  assign sigCSA_cry_19[26] = ((sigCSA_cry_17[26] & sigCSA_cry_12[14])) | ((sigCSA_cry_7[11] & ((sigCSA_cry_17[26] ^ sigCSA_cry_12[14]))));
  assign sigCSA_sum_19[27] = sigCSA_cry_17[27] ^ sigCSA_cry_12[15] ^ sigCSA_cry_7[12];
  assign sigCSA_cry_19[27] = ((sigCSA_cry_17[27] & sigCSA_cry_12[15])) | ((sigCSA_cry_7[12] & ((sigCSA_cry_17[27] ^ sigCSA_cry_12[15]))));
  assign sigCSA_sum_19[28] = sigCSA_cry_17[28] ^ sigCSA_cry_12[16] ^ sigCSA_cry_7[13];
  assign sigCSA_cry_19[28] = ((sigCSA_cry_17[28] & sigCSA_cry_12[16])) | ((sigCSA_cry_7[13] & ((sigCSA_cry_17[28] ^ sigCSA_cry_12[16]))));
  assign sigCSA_sum_19[29] = sigCSA_cry_17[29] ^ sigCSA_cry_12[17] ^ sigCSA_cry_7[14];
  assign sigCSA_cry_19[29] = ((sigCSA_cry_17[29] & sigCSA_cry_12[17])) | ((sigCSA_cry_7[14] & ((sigCSA_cry_17[29] ^ sigCSA_cry_12[17]))));
  assign sigCSA_sum_19[30] = sigCSA_cry_17[30] ^ sigCSA_cry_12[18] ^ sigCSA_cry_7[15];
  assign sigCSA_cry_19[30] = ((sigCSA_cry_17[30] & sigCSA_cry_12[18])) | ((sigCSA_cry_7[15] & ((sigCSA_cry_17[30] ^ sigCSA_cry_12[18]))));
  assign sigCSA_sum_19[31] = sigCSA_cry_17[31] ^ sigCSA_cry_12[19] ^ sigCSA_cry_7[16];
  assign sigCSA_cry_19[31] = ((sigCSA_cry_17[31] & sigCSA_cry_12[19])) | ((sigCSA_cry_7[16] & ((sigCSA_cry_17[31] ^ sigCSA_cry_12[19]))));
  assign sigCSA_sum_19[32] = sigCSA_cry_17[32] ^ sigCSA_cry_12[20] ^ sigCSA_cry_7[17];
  assign sigCSA_cry_19[32] = ((sigCSA_cry_17[32] & sigCSA_cry_12[20])) | ((sigCSA_cry_7[17] & ((sigCSA_cry_17[32] ^ sigCSA_cry_12[20]))));
  assign sigCSA_sum_19[33] = sigCSA_cry_17[33] ^ sigCSA_cry_12[21] ^ sigCSA_cry_7[18];
  assign sigCSA_cry_19[33] = ((sigCSA_cry_17[33] & sigCSA_cry_12[21])) | ((sigCSA_cry_7[18] & ((sigCSA_cry_17[33] ^ sigCSA_cry_12[21]))));
  assign sigCSA_sum_19[34] = sigCSA_cry_17[34] ^ sigCSA_cry_12[22] ^ sigCSA_cry_7[19];
  assign sigCSA_cry_19[34] = ((sigCSA_cry_17[34] & sigCSA_cry_12[22])) | ((sigCSA_cry_7[19] & ((sigCSA_cry_17[34] ^ sigCSA_cry_12[22]))));
  assign sigCSA_sum_19[35] = sigCSA_cry_17[35] ^ sigCSA_cry_12[23] ^ sigCSA_cry_7[20];
  assign sigCSA_cry_19[35] = ((sigCSA_cry_17[35] & sigCSA_cry_12[23])) | ((sigCSA_cry_7[20] & ((sigCSA_cry_17[35] ^ sigCSA_cry_12[23]))));
  assign sigCSA_sum_19[36] = sigCSA_cry_17[36] ^ sigCSA_cry_12[24] ^ sigCSA_cry_7[21];
  assign sigCSA_cry_19[36] = ((sigCSA_cry_17[36] & sigCSA_cry_12[24])) | ((sigCSA_cry_7[21] & ((sigCSA_cry_17[36] ^ sigCSA_cry_12[24]))));
  assign sigCSA_sum_19[37] = sigCSA_cry_17[37] ^ sigCSA_cry_12[25] ^ sigCSA_cry_7[22];
  assign sigCSA_cry_19[37] = ((sigCSA_cry_17[37] & sigCSA_cry_12[25])) | ((sigCSA_cry_7[22] & ((sigCSA_cry_17[37] ^ sigCSA_cry_12[25]))));
  assign sigCSA_sum_19[38] = sigCSA_cry_17[38] ^ sigCSA_cry_12[26] ^ sigCSA_cry_7[23];
  assign sigCSA_cry_19[38] = ((sigCSA_cry_17[38] & sigCSA_cry_12[26])) | ((sigCSA_cry_7[23] & ((sigCSA_cry_17[38] ^ sigCSA_cry_12[26]))));
  assign sigCSA_sum_19[39] = sigCSA_cry_17[39] ^ sigCSA_cry_12[27] ^ sigCSA_cry_7[24];
  assign sigCSA_cry_19[39] = ((sigCSA_cry_17[39] & sigCSA_cry_12[27])) | ((sigCSA_cry_7[24] & ((sigCSA_cry_17[39] ^ sigCSA_cry_12[27]))));
  assign sigCSA_sum_19[40] = sigCSA_cry_17[40] ^ sigCSA_cry_12[28] ^ sigCSA_cry_7[25];
  assign sigCSA_cry_19[40] = ((sigCSA_cry_17[40] & sigCSA_cry_12[28])) | ((sigCSA_cry_7[25] & ((sigCSA_cry_17[40] ^ sigCSA_cry_12[28]))));
  assign sigCSA_sum_19[41] = sigCSA_cry_17[41] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_19[41] = ((sigCSA_cry_17[41] & 1'b 0)) | ((1'b 0 & ((sigCSA_cry_17[41] ^ 1'b 0))));
  assign sigCSA_sum_19[42] = 1'b 0 ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_19[42] = ((1'b 0 & 1'b 0)) | ((1'b 0 & ((1'b 0 ^ 1'b 0))));
  assign sigCSA_sum_19[43] = 1'b 0 ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_19[43] = ((1'b 0 & 1'b 0)) | ((1'b 0 & ((1'b 0 ^ 1'b 0))));
  assign sigCSA_sum_19[44] = 1'b 0 ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_19[44] = ((1'b 0 & 1'b 0)) | ((1'b 0 & ((1'b 0 ^ 1'b 0))));
  assign sigCSA_sum_19[45] = 1'b 0 ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_19[45] = ((1'b 0 & 1'b 0)) | ((1'b 0 & ((1'b 0 ^ 1'b 0))));
  assign sigCSA_sum_19[46] = 1'b 0 ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_19[46] = ((1'b 0 & 1'b 0)) | ((1'b 0 & ((1'b 0 ^ 1'b 0))));

// csa : 20
  // generating sigCSA_sum_20 and sigCSA_cry_20
  assign sigCSA_sum_20[0] = sigCSA_sum_18[0] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_20[0] = ((sigCSA_sum_18[0] & 1'b 0)) | ((1'b 0 & ((sigCSA_sum_18[0] ^ 1'b 0))));
  assign sigCSA_sum_20[1] = sigCSA_sum_18[1] ^ sigCSA_cry_18[0] ^ 1'b 0;
  assign sigCSA_cry_20[1] = ((sigCSA_sum_18[1] & sigCSA_cry_18[0])) | ((1'b 0 & ((sigCSA_sum_18[1] ^ sigCSA_cry_18[0]))));
  assign sigCSA_sum_20[2] = sigCSA_sum_18[2] ^ sigCSA_cry_18[1] ^ 1'b 0;
  assign sigCSA_cry_20[2] = ((sigCSA_sum_18[2] & sigCSA_cry_18[1])) | ((1'b 0 & ((sigCSA_sum_18[2] ^ sigCSA_cry_18[1]))));
  assign sigCSA_sum_20[3] = sigCSA_sum_18[3] ^ sigCSA_cry_18[2] ^ 1'b 0;
  assign sigCSA_cry_20[3] = ((sigCSA_sum_18[3] & sigCSA_cry_18[2])) | ((1'b 0 & ((sigCSA_sum_18[3] ^ sigCSA_cry_18[2]))));
  assign sigCSA_sum_20[4] = sigCSA_sum_18[4] ^ sigCSA_cry_18[3] ^ 1'b 0;
  assign sigCSA_cry_20[4] = ((sigCSA_sum_18[4] & sigCSA_cry_18[3])) | ((1'b 0 & ((sigCSA_sum_18[4] ^ sigCSA_cry_18[3]))));
  assign sigCSA_sum_20[5] = sigCSA_sum_18[5] ^ sigCSA_cry_18[4] ^ 1'b 0;
  assign sigCSA_cry_20[5] = ((sigCSA_sum_18[5] & sigCSA_cry_18[4])) | ((1'b 0 & ((sigCSA_sum_18[5] ^ sigCSA_cry_18[4]))));
  assign sigCSA_sum_20[6] = sigCSA_sum_18[6] ^ sigCSA_cry_18[5] ^ 1'b 0;
  assign sigCSA_cry_20[6] = ((sigCSA_sum_18[6] & sigCSA_cry_18[5])) | ((1'b 0 & ((sigCSA_sum_18[6] ^ sigCSA_cry_18[5]))));
  assign sigCSA_sum_20[7] = sigCSA_sum_18[7] ^ sigCSA_cry_18[6] ^ sigCSA_sum_19[0];
  assign sigCSA_cry_20[7] = ((sigCSA_sum_18[7] & sigCSA_cry_18[6])) | ((sigCSA_sum_19[0] & ((sigCSA_sum_18[7] ^ sigCSA_cry_18[6]))));
  assign sigCSA_sum_20[8] = sigCSA_sum_18[8] ^ sigCSA_cry_18[7] ^ sigCSA_sum_19[1];
  assign sigCSA_cry_20[8] = ((sigCSA_sum_18[8] & sigCSA_cry_18[7])) | ((sigCSA_sum_19[1] & ((sigCSA_sum_18[8] ^ sigCSA_cry_18[7]))));
  assign sigCSA_sum_20[9] = sigCSA_sum_18[9] ^ sigCSA_cry_18[8] ^ sigCSA_sum_19[2];
  assign sigCSA_cry_20[9] = ((sigCSA_sum_18[9] & sigCSA_cry_18[8])) | ((sigCSA_sum_19[2] & ((sigCSA_sum_18[9] ^ sigCSA_cry_18[8]))));
  assign sigCSA_sum_20[10] = sigCSA_sum_18[10] ^ sigCSA_cry_18[9] ^ sigCSA_sum_19[3];
  assign sigCSA_cry_20[10] = ((sigCSA_sum_18[10] & sigCSA_cry_18[9])) | ((sigCSA_sum_19[3] & ((sigCSA_sum_18[10] ^ sigCSA_cry_18[9]))));
  assign sigCSA_sum_20[11] = sigCSA_sum_18[11] ^ sigCSA_cry_18[10] ^ sigCSA_sum_19[4];
  assign sigCSA_cry_20[11] = ((sigCSA_sum_18[11] & sigCSA_cry_18[10])) | ((sigCSA_sum_19[4] & ((sigCSA_sum_18[11] ^ sigCSA_cry_18[10]))));
  assign sigCSA_sum_20[12] = sigCSA_sum_18[12] ^ sigCSA_cry_18[11] ^ sigCSA_sum_19[5];
  assign sigCSA_cry_20[12] = ((sigCSA_sum_18[12] & sigCSA_cry_18[11])) | ((sigCSA_sum_19[5] & ((sigCSA_sum_18[12] ^ sigCSA_cry_18[11]))));
  assign sigCSA_sum_20[13] = sigCSA_sum_18[13] ^ sigCSA_cry_18[12] ^ sigCSA_sum_19[6];
  assign sigCSA_cry_20[13] = ((sigCSA_sum_18[13] & sigCSA_cry_18[12])) | ((sigCSA_sum_19[6] & ((sigCSA_sum_18[13] ^ sigCSA_cry_18[12]))));
  assign sigCSA_sum_20[14] = sigCSA_sum_18[14] ^ sigCSA_cry_18[13] ^ sigCSA_sum_19[7];
  assign sigCSA_cry_20[14] = ((sigCSA_sum_18[14] & sigCSA_cry_18[13])) | ((sigCSA_sum_19[7] & ((sigCSA_sum_18[14] ^ sigCSA_cry_18[13]))));
  assign sigCSA_sum_20[15] = sigCSA_sum_18[15] ^ sigCSA_cry_18[14] ^ sigCSA_sum_19[8];
  assign sigCSA_cry_20[15] = ((sigCSA_sum_18[15] & sigCSA_cry_18[14])) | ((sigCSA_sum_19[8] & ((sigCSA_sum_18[15] ^ sigCSA_cry_18[14]))));
  assign sigCSA_sum_20[16] = sigCSA_sum_18[16] ^ sigCSA_cry_18[15] ^ sigCSA_sum_19[9];
  assign sigCSA_cry_20[16] = ((sigCSA_sum_18[16] & sigCSA_cry_18[15])) | ((sigCSA_sum_19[9] & ((sigCSA_sum_18[16] ^ sigCSA_cry_18[15]))));
  assign sigCSA_sum_20[17] = sigCSA_sum_18[17] ^ sigCSA_cry_18[16] ^ sigCSA_sum_19[10];
  assign sigCSA_cry_20[17] = ((sigCSA_sum_18[17] & sigCSA_cry_18[16])) | ((sigCSA_sum_19[10] & ((sigCSA_sum_18[17] ^ sigCSA_cry_18[16]))));
  assign sigCSA_sum_20[18] = sigCSA_sum_18[18] ^ sigCSA_cry_18[17] ^ sigCSA_sum_19[11];
  assign sigCSA_cry_20[18] = ((sigCSA_sum_18[18] & sigCSA_cry_18[17])) | ((sigCSA_sum_19[11] & ((sigCSA_sum_18[18] ^ sigCSA_cry_18[17]))));
  assign sigCSA_sum_20[19] = sigCSA_sum_18[19] ^ sigCSA_cry_18[18] ^ sigCSA_sum_19[12];
  assign sigCSA_cry_20[19] = ((sigCSA_sum_18[19] & sigCSA_cry_18[18])) | ((sigCSA_sum_19[12] & ((sigCSA_sum_18[19] ^ sigCSA_cry_18[18]))));
  assign sigCSA_sum_20[20] = sigCSA_sum_18[20] ^ sigCSA_cry_18[19] ^ sigCSA_sum_19[13];
  assign sigCSA_cry_20[20] = ((sigCSA_sum_18[20] & sigCSA_cry_18[19])) | ((sigCSA_sum_19[13] & ((sigCSA_sum_18[20] ^ sigCSA_cry_18[19]))));
  assign sigCSA_sum_20[21] = sigCSA_sum_18[21] ^ sigCSA_cry_18[20] ^ sigCSA_sum_19[14];
  assign sigCSA_cry_20[21] = ((sigCSA_sum_18[21] & sigCSA_cry_18[20])) | ((sigCSA_sum_19[14] & ((sigCSA_sum_18[21] ^ sigCSA_cry_18[20]))));
  assign sigCSA_sum_20[22] = sigCSA_sum_18[22] ^ sigCSA_cry_18[21] ^ sigCSA_sum_19[15];
  assign sigCSA_cry_20[22] = ((sigCSA_sum_18[22] & sigCSA_cry_18[21])) | ((sigCSA_sum_19[15] & ((sigCSA_sum_18[22] ^ sigCSA_cry_18[21]))));
  assign sigCSA_sum_20[23] = sigCSA_sum_18[23] ^ sigCSA_cry_18[22] ^ sigCSA_sum_19[16];
  assign sigCSA_cry_20[23] = ((sigCSA_sum_18[23] & sigCSA_cry_18[22])) | ((sigCSA_sum_19[16] & ((sigCSA_sum_18[23] ^ sigCSA_cry_18[22]))));
  assign sigCSA_sum_20[24] = sigCSA_sum_18[24] ^ sigCSA_cry_18[23] ^ sigCSA_sum_19[17];
  assign sigCSA_cry_20[24] = ((sigCSA_sum_18[24] & sigCSA_cry_18[23])) | ((sigCSA_sum_19[17] & ((sigCSA_sum_18[24] ^ sigCSA_cry_18[23]))));
  assign sigCSA_sum_20[25] = sigCSA_sum_18[25] ^ sigCSA_cry_18[24] ^ sigCSA_sum_19[18];
  assign sigCSA_cry_20[25] = ((sigCSA_sum_18[25] & sigCSA_cry_18[24])) | ((sigCSA_sum_19[18] & ((sigCSA_sum_18[25] ^ sigCSA_cry_18[24]))));
  assign sigCSA_sum_20[26] = sigCSA_sum_18[26] ^ sigCSA_cry_18[25] ^ sigCSA_sum_19[19];
  assign sigCSA_cry_20[26] = ((sigCSA_sum_18[26] & sigCSA_cry_18[25])) | ((sigCSA_sum_19[19] & ((sigCSA_sum_18[26] ^ sigCSA_cry_18[25]))));
  assign sigCSA_sum_20[27] = sigCSA_sum_18[27] ^ sigCSA_cry_18[26] ^ sigCSA_sum_19[20];
  assign sigCSA_cry_20[27] = ((sigCSA_sum_18[27] & sigCSA_cry_18[26])) | ((sigCSA_sum_19[20] & ((sigCSA_sum_18[27] ^ sigCSA_cry_18[26]))));
  assign sigCSA_sum_20[28] = sigCSA_sum_18[28] ^ sigCSA_cry_18[27] ^ sigCSA_sum_19[21];
  assign sigCSA_cry_20[28] = ((sigCSA_sum_18[28] & sigCSA_cry_18[27])) | ((sigCSA_sum_19[21] & ((sigCSA_sum_18[28] ^ sigCSA_cry_18[27]))));
  assign sigCSA_sum_20[29] = sigCSA_sum_18[29] ^ sigCSA_cry_18[28] ^ sigCSA_sum_19[22];
  assign sigCSA_cry_20[29] = ((sigCSA_sum_18[29] & sigCSA_cry_18[28])) | ((sigCSA_sum_19[22] & ((sigCSA_sum_18[29] ^ sigCSA_cry_18[28]))));
  assign sigCSA_sum_20[30] = sigCSA_sum_18[30] ^ sigCSA_cry_18[29] ^ sigCSA_sum_19[23];
  assign sigCSA_cry_20[30] = ((sigCSA_sum_18[30] & sigCSA_cry_18[29])) | ((sigCSA_sum_19[23] & ((sigCSA_sum_18[30] ^ sigCSA_cry_18[29]))));
  assign sigCSA_sum_20[31] = sigCSA_sum_18[31] ^ sigCSA_cry_18[30] ^ sigCSA_sum_19[24];
  assign sigCSA_cry_20[31] = ((sigCSA_sum_18[31] & sigCSA_cry_18[30])) | ((sigCSA_sum_19[24] & ((sigCSA_sum_18[31] ^ sigCSA_cry_18[30]))));
  assign sigCSA_sum_20[32] = sigCSA_sum_18[32] ^ sigCSA_cry_18[31] ^ sigCSA_sum_19[25];
  assign sigCSA_cry_20[32] = ((sigCSA_sum_18[32] & sigCSA_cry_18[31])) | ((sigCSA_sum_19[25] & ((sigCSA_sum_18[32] ^ sigCSA_cry_18[31]))));
  assign sigCSA_sum_20[33] = sigCSA_sum_18[33] ^ sigCSA_cry_18[32] ^ sigCSA_sum_19[26];
  assign sigCSA_cry_20[33] = ((sigCSA_sum_18[33] & sigCSA_cry_18[32])) | ((sigCSA_sum_19[26] & ((sigCSA_sum_18[33] ^ sigCSA_cry_18[32]))));
  assign sigCSA_sum_20[34] = sigCSA_sum_18[34] ^ sigCSA_cry_18[33] ^ sigCSA_sum_19[27];
  assign sigCSA_cry_20[34] = ((sigCSA_sum_18[34] & sigCSA_cry_18[33])) | ((sigCSA_sum_19[27] & ((sigCSA_sum_18[34] ^ sigCSA_cry_18[33]))));
  assign sigCSA_sum_20[35] = sigCSA_sum_18[35] ^ sigCSA_cry_18[34] ^ sigCSA_sum_19[28];
  assign sigCSA_cry_20[35] = ((sigCSA_sum_18[35] & sigCSA_cry_18[34])) | ((sigCSA_sum_19[28] & ((sigCSA_sum_18[35] ^ sigCSA_cry_18[34]))));
  assign sigCSA_sum_20[36] = sigCSA_sum_18[36] ^ sigCSA_cry_18[35] ^ sigCSA_sum_19[29];
  assign sigCSA_cry_20[36] = ((sigCSA_sum_18[36] & sigCSA_cry_18[35])) | ((sigCSA_sum_19[29] & ((sigCSA_sum_18[36] ^ sigCSA_cry_18[35]))));
  assign sigCSA_sum_20[37] = sigCSA_sum_18[37] ^ sigCSA_cry_18[36] ^ sigCSA_sum_19[30];
  assign sigCSA_cry_20[37] = ((sigCSA_sum_18[37] & sigCSA_cry_18[36])) | ((sigCSA_sum_19[30] & ((sigCSA_sum_18[37] ^ sigCSA_cry_18[36]))));
  assign sigCSA_sum_20[38] = sigCSA_sum_18[38] ^ sigCSA_cry_18[37] ^ sigCSA_sum_19[31];
  assign sigCSA_cry_20[38] = ((sigCSA_sum_18[38] & sigCSA_cry_18[37])) | ((sigCSA_sum_19[31] & ((sigCSA_sum_18[38] ^ sigCSA_cry_18[37]))));
  assign sigCSA_sum_20[39] = sigCSA_sum_18[39] ^ sigCSA_cry_18[38] ^ sigCSA_sum_19[32];
  assign sigCSA_cry_20[39] = ((sigCSA_sum_18[39] & sigCSA_cry_18[38])) | ((sigCSA_sum_19[32] & ((sigCSA_sum_18[39] ^ sigCSA_cry_18[38]))));
  assign sigCSA_sum_20[40] = sigCSA_sum_18[40] ^ sigCSA_cry_18[39] ^ sigCSA_sum_19[33];
  assign sigCSA_cry_20[40] = ((sigCSA_sum_18[40] & sigCSA_cry_18[39])) | ((sigCSA_sum_19[33] & ((sigCSA_sum_18[40] ^ sigCSA_cry_18[39]))));
  assign sigCSA_sum_20[41] = sigCSA_sum_18[41] ^ sigCSA_cry_18[40] ^ sigCSA_sum_19[34];
  assign sigCSA_cry_20[41] = ((sigCSA_sum_18[41] & sigCSA_cry_18[40])) | ((sigCSA_sum_19[34] & ((sigCSA_sum_18[41] ^ sigCSA_cry_18[40]))));
  assign sigCSA_sum_20[42] = sigCSA_sum_18[42] ^ sigCSA_cry_18[41] ^ sigCSA_sum_19[35];
  assign sigCSA_cry_20[42] = ((sigCSA_sum_18[42] & sigCSA_cry_18[41])) | ((sigCSA_sum_19[35] & ((sigCSA_sum_18[42] ^ sigCSA_cry_18[41]))));
  assign sigCSA_sum_20[43] = sigCSA_sum_18[43] ^ sigCSA_cry_18[42] ^ sigCSA_sum_19[36];
  assign sigCSA_cry_20[43] = ((sigCSA_sum_18[43] & sigCSA_cry_18[42])) | ((sigCSA_sum_19[36] & ((sigCSA_sum_18[43] ^ sigCSA_cry_18[42]))));
  assign sigCSA_sum_20[44] = sigCSA_sum_18[44] ^ sigCSA_cry_18[43] ^ sigCSA_sum_19[37];
  assign sigCSA_cry_20[44] = ((sigCSA_sum_18[44] & sigCSA_cry_18[43])) | ((sigCSA_sum_19[37] & ((sigCSA_sum_18[44] ^ sigCSA_cry_18[43]))));
  assign sigCSA_sum_20[45] = sigCSA_sum_18[45] ^ sigCSA_cry_18[44] ^ sigCSA_sum_19[38];
  assign sigCSA_cry_20[45] = ((sigCSA_sum_18[45] & sigCSA_cry_18[44])) | ((sigCSA_sum_19[38] & ((sigCSA_sum_18[45] ^ sigCSA_cry_18[44]))));
  assign sigCSA_sum_20[46] = sigCSA_sum_18[46] ^ sigCSA_cry_18[45] ^ sigCSA_sum_19[39];
  assign sigCSA_cry_20[46] = ((sigCSA_sum_18[46] & sigCSA_cry_18[45])) | ((sigCSA_sum_19[39] & ((sigCSA_sum_18[46] ^ sigCSA_cry_18[45]))));
  assign sigCSA_sum_20[47] = sigCSA_sum_18[47] ^ sigCSA_cry_18[46] ^ sigCSA_sum_19[40];
  assign sigCSA_cry_20[47] = ((sigCSA_sum_18[47] & sigCSA_cry_18[46])) | ((sigCSA_sum_19[40] & ((sigCSA_sum_18[47] ^ sigCSA_cry_18[46]))));
  assign sigCSA_sum_20[48] = 1'b 0 ^ sigCSA_cry_18[47] ^ sigCSA_sum_19[41];
  assign sigCSA_cry_20[48] = ((1'b 0 & sigCSA_cry_18[47])) | ((sigCSA_sum_19[41] & ((1'b 0 ^ sigCSA_cry_18[47]))));
  assign sigCSA_sum_20[49] = 1'b 0 ^ 1'b 0 ^ sigCSA_sum_19[42];
  assign sigCSA_cry_20[49] = ((1'b 0 & 1'b 0)) | ((sigCSA_sum_19[42] & ((1'b 0 ^ 1'b 0))));
  assign sigCSA_sum_20[50] = 1'b 0 ^ 1'b 0 ^ sigCSA_sum_19[43];
  assign sigCSA_cry_20[50] = ((1'b 0 & 1'b 0)) | ((sigCSA_sum_19[43] & ((1'b 0 ^ 1'b 0))));
  assign sigCSA_sum_20[51] = 1'b 0 ^ 1'b 0 ^ sigCSA_sum_19[44];
  assign sigCSA_cry_20[51] = ((1'b 0 & 1'b 0)) | ((sigCSA_sum_19[44] & ((1'b 0 ^ 1'b 0))));
  assign sigCSA_sum_20[52] = 1'b 0 ^ 1'b 0 ^ sigCSA_sum_19[45];
  assign sigCSA_cry_20[52] = ((1'b 0 & 1'b 0)) | ((sigCSA_sum_19[45] & ((1'b 0 ^ 1'b 0))));
  assign sigCSA_sum_20[53] = 1'b 0 ^ 1'b 0 ^ sigCSA_sum_19[46];
  assign sigCSA_cry_20[53] = ((1'b 0 & 1'b 0)) | ((sigCSA_sum_19[46] & ((1'b 0 ^ 1'b 0))));
  assign sigCSA_sum_20[54] = 1'b 0 ^ 1'b 0 ^ sigCSA_sum_19[47];
  assign sigCSA_cry_20[54] = ((1'b 0 & 1'b 0)) | ((sigCSA_sum_19[47] & ((1'b 0 ^ 1'b 0))));
  // csa : 21
  // generating sigCSA_sum_21 and sigCSA_cry_21
  assign sigCSA_sum_21[0] = sigCSA_sum_20[0] ^ 1'b 0 ^ 1'b 0;
  assign sigCSA_cry_21[0] = ((sigCSA_sum_20[0] & 1'b 0)) | ((1'b 0 & ((sigCSA_sum_20[0] ^ 1'b 0))));
  assign sigCSA_sum_21[1] = sigCSA_sum_20[1] ^ sigCSA_cry_20[0] ^ 1'b 0;
  assign sigCSA_cry_21[1] = ((sigCSA_sum_20[1] & sigCSA_cry_20[0])) | ((1'b 0 & ((sigCSA_sum_20[1] ^ sigCSA_cry_20[0]))));
  assign sigCSA_sum_21[2] = sigCSA_sum_20[2] ^ sigCSA_cry_20[1] ^ 1'b 0;
  assign sigCSA_cry_21[2] = ((sigCSA_sum_20[2] & sigCSA_cry_20[1])) | ((1'b 0 & ((sigCSA_sum_20[2] ^ sigCSA_cry_20[1]))));
  assign sigCSA_sum_21[3] = sigCSA_sum_20[3] ^ sigCSA_cry_20[2] ^ 1'b 0;
  assign sigCSA_cry_21[3] = ((sigCSA_sum_20[3] & sigCSA_cry_20[2])) | ((1'b 0 & ((sigCSA_sum_20[3] ^ sigCSA_cry_20[2]))));
  assign sigCSA_sum_21[4] = sigCSA_sum_20[4] ^ sigCSA_cry_20[3] ^ 1'b 0;
  assign sigCSA_cry_21[4] = ((sigCSA_sum_20[4] & sigCSA_cry_20[3])) | ((1'b 0 & ((sigCSA_sum_20[4] ^ sigCSA_cry_20[3]))));
  assign sigCSA_sum_21[5] = sigCSA_sum_20[5] ^ sigCSA_cry_20[4] ^ 1'b 0;
  assign sigCSA_cry_21[5] = ((sigCSA_sum_20[5] & sigCSA_cry_20[4])) | ((1'b 0 & ((sigCSA_sum_20[5] ^ sigCSA_cry_20[4]))));
  assign sigCSA_sum_21[6] = sigCSA_sum_20[6] ^ sigCSA_cry_20[5] ^ 1'b 0;
  assign sigCSA_cry_21[6] = ((sigCSA_sum_20[6] & sigCSA_cry_20[5])) | ((1'b 0 & ((sigCSA_sum_20[6] ^ sigCSA_cry_20[5]))));
  assign sigCSA_sum_21[7] = sigCSA_sum_20[7] ^ sigCSA_cry_20[6] ^ 1'b 0;
  assign sigCSA_cry_21[7] = ((sigCSA_sum_20[7] & sigCSA_cry_20[6])) | ((1'b 0 & ((sigCSA_sum_20[7] ^ sigCSA_cry_20[6]))));
  assign sigCSA_sum_21[8] = sigCSA_sum_20[8] ^ sigCSA_cry_20[7] ^ sigCSA_cry_19[0];
  assign sigCSA_cry_21[8] = ((sigCSA_sum_20[8] & sigCSA_cry_20[7])) | ((sigCSA_cry_19[0] & ((sigCSA_sum_20[8] ^ sigCSA_cry_20[7]))));
  assign sigCSA_sum_21[9] = sigCSA_sum_20[9] ^ sigCSA_cry_20[8] ^ sigCSA_cry_19[1];
  assign sigCSA_cry_21[9] = ((sigCSA_sum_20[9] & sigCSA_cry_20[8])) | ((sigCSA_cry_19[1] & ((sigCSA_sum_20[9] ^ sigCSA_cry_20[8]))));
  assign sigCSA_sum_21[10] = sigCSA_sum_20[10] ^ sigCSA_cry_20[9] ^ sigCSA_cry_19[2];
  assign sigCSA_cry_21[10] = ((sigCSA_sum_20[10] & sigCSA_cry_20[9])) | ((sigCSA_cry_19[2] & ((sigCSA_sum_20[10] ^ sigCSA_cry_20[9]))));
  assign sigCSA_sum_21[11] = sigCSA_sum_20[11] ^ sigCSA_cry_20[10] ^ sigCSA_cry_19[3];
  assign sigCSA_cry_21[11] = ((sigCSA_sum_20[11] & sigCSA_cry_20[10])) | ((sigCSA_cry_19[3] & ((sigCSA_sum_20[11] ^ sigCSA_cry_20[10]))));
  assign sigCSA_sum_21[12] = sigCSA_sum_20[12] ^ sigCSA_cry_20[11] ^ sigCSA_cry_19[4];
  assign sigCSA_cry_21[12] = ((sigCSA_sum_20[12] & sigCSA_cry_20[11])) | ((sigCSA_cry_19[4] & ((sigCSA_sum_20[12] ^ sigCSA_cry_20[11]))));
  assign sigCSA_sum_21[13] = sigCSA_sum_20[13] ^ sigCSA_cry_20[12] ^ sigCSA_cry_19[5];
  assign sigCSA_cry_21[13] = ((sigCSA_sum_20[13] & sigCSA_cry_20[12])) | ((sigCSA_cry_19[5] & ((sigCSA_sum_20[13] ^ sigCSA_cry_20[12]))));
  assign sigCSA_sum_21[14] = sigCSA_sum_20[14] ^ sigCSA_cry_20[13] ^ sigCSA_cry_19[6];
  assign sigCSA_cry_21[14] = ((sigCSA_sum_20[14] & sigCSA_cry_20[13])) | ((sigCSA_cry_19[6] & ((sigCSA_sum_20[14] ^ sigCSA_cry_20[13]))));
  assign sigCSA_sum_21[15] = sigCSA_sum_20[15] ^ sigCSA_cry_20[14] ^ sigCSA_cry_19[7];
  assign sigCSA_cry_21[15] = ((sigCSA_sum_20[15] & sigCSA_cry_20[14])) | ((sigCSA_cry_19[7] & ((sigCSA_sum_20[15] ^ sigCSA_cry_20[14]))));
  assign sigCSA_sum_21[16] = sigCSA_sum_20[16] ^ sigCSA_cry_20[15] ^ sigCSA_cry_19[8];
  assign sigCSA_cry_21[16] = ((sigCSA_sum_20[16] & sigCSA_cry_20[15])) | ((sigCSA_cry_19[8] & ((sigCSA_sum_20[16] ^ sigCSA_cry_20[15]))));
  assign sigCSA_sum_21[17] = sigCSA_sum_20[17] ^ sigCSA_cry_20[16] ^ sigCSA_cry_19[9];
  assign sigCSA_cry_21[17] = ((sigCSA_sum_20[17] & sigCSA_cry_20[16])) | ((sigCSA_cry_19[9] & ((sigCSA_sum_20[17] ^ sigCSA_cry_20[16]))));
  assign sigCSA_sum_21[18] = sigCSA_sum_20[18] ^ sigCSA_cry_20[17] ^ sigCSA_cry_19[10];
  assign sigCSA_cry_21[18] = ((sigCSA_sum_20[18] & sigCSA_cry_20[17])) | ((sigCSA_cry_19[10] & ((sigCSA_sum_20[18] ^ sigCSA_cry_20[17]))));
  assign sigCSA_sum_21[19] = sigCSA_sum_20[19] ^ sigCSA_cry_20[18] ^ sigCSA_cry_19[11];
  assign sigCSA_cry_21[19] = ((sigCSA_sum_20[19] & sigCSA_cry_20[18])) | ((sigCSA_cry_19[11] & ((sigCSA_sum_20[19] ^ sigCSA_cry_20[18]))));
  assign sigCSA_sum_21[20] = sigCSA_sum_20[20] ^ sigCSA_cry_20[19] ^ sigCSA_cry_19[12];
  assign sigCSA_cry_21[20] = ((sigCSA_sum_20[20] & sigCSA_cry_20[19])) | ((sigCSA_cry_19[12] & ((sigCSA_sum_20[20] ^ sigCSA_cry_20[19]))));
  assign sigCSA_sum_21[21] = sigCSA_sum_20[21] ^ sigCSA_cry_20[20] ^ sigCSA_cry_19[13];
  assign sigCSA_cry_21[21] = ((sigCSA_sum_20[21] & sigCSA_cry_20[20])) | ((sigCSA_cry_19[13] & ((sigCSA_sum_20[21] ^ sigCSA_cry_20[20]))));
  assign sigCSA_sum_21[22] = sigCSA_sum_20[22] ^ sigCSA_cry_20[21] ^ sigCSA_cry_19[14];
  assign sigCSA_cry_21[22] = ((sigCSA_sum_20[22] & sigCSA_cry_20[21])) | ((sigCSA_cry_19[14] & ((sigCSA_sum_20[22] ^ sigCSA_cry_20[21]))));
  assign sigCSA_sum_21[23] = sigCSA_sum_20[23] ^ sigCSA_cry_20[22] ^ sigCSA_cry_19[15];
  assign sigCSA_cry_21[23] = ((sigCSA_sum_20[23] & sigCSA_cry_20[22])) | ((sigCSA_cry_19[15] & ((sigCSA_sum_20[23] ^ sigCSA_cry_20[22]))));
  assign sigCSA_sum_21[24] = sigCSA_sum_20[24] ^ sigCSA_cry_20[23] ^ sigCSA_cry_19[16];
  assign sigCSA_cry_21[24] = ((sigCSA_sum_20[24] & sigCSA_cry_20[23])) | ((sigCSA_cry_19[16] & ((sigCSA_sum_20[24] ^ sigCSA_cry_20[23]))));
  assign sigCSA_sum_21[25] = sigCSA_sum_20[25] ^ sigCSA_cry_20[24] ^ sigCSA_cry_19[17];
  assign sigCSA_cry_21[25] = ((sigCSA_sum_20[25] & sigCSA_cry_20[24])) | ((sigCSA_cry_19[17] & ((sigCSA_sum_20[25] ^ sigCSA_cry_20[24]))));
  assign sigCSA_sum_21[26] = sigCSA_sum_20[26] ^ sigCSA_cry_20[25] ^ sigCSA_cry_19[18];
  assign sigCSA_cry_21[26] = ((sigCSA_sum_20[26] & sigCSA_cry_20[25])) | ((sigCSA_cry_19[18] & ((sigCSA_sum_20[26] ^ sigCSA_cry_20[25]))));
  assign sigCSA_sum_21[27] = sigCSA_sum_20[27] ^ sigCSA_cry_20[26] ^ sigCSA_cry_19[19];
  assign sigCSA_cry_21[27] = ((sigCSA_sum_20[27] & sigCSA_cry_20[26])) | ((sigCSA_cry_19[19] & ((sigCSA_sum_20[27] ^ sigCSA_cry_20[26]))));
  assign sigCSA_sum_21[28] = sigCSA_sum_20[28] ^ sigCSA_cry_20[27] ^ sigCSA_cry_19[20];
  assign sigCSA_cry_21[28] = ((sigCSA_sum_20[28] & sigCSA_cry_20[27])) | ((sigCSA_cry_19[20] & ((sigCSA_sum_20[28] ^ sigCSA_cry_20[27]))));
  assign sigCSA_sum_21[29] = sigCSA_sum_20[29] ^ sigCSA_cry_20[28] ^ sigCSA_cry_19[21];
  assign sigCSA_cry_21[29] = ((sigCSA_sum_20[29] & sigCSA_cry_20[28])) | ((sigCSA_cry_19[21] & ((sigCSA_sum_20[29] ^ sigCSA_cry_20[28]))));
  assign sigCSA_sum_21[30] = sigCSA_sum_20[30] ^ sigCSA_cry_20[29] ^ sigCSA_cry_19[22];
  assign sigCSA_cry_21[30] = ((sigCSA_sum_20[30] & sigCSA_cry_20[29])) | ((sigCSA_cry_19[22] & ((sigCSA_sum_20[30] ^ sigCSA_cry_20[29]))));
  assign sigCSA_sum_21[31] = sigCSA_sum_20[31] ^ sigCSA_cry_20[30] ^ sigCSA_cry_19[23];
  assign sigCSA_cry_21[31] = ((sigCSA_sum_20[31] & sigCSA_cry_20[30])) | ((sigCSA_cry_19[23] & ((sigCSA_sum_20[31] ^ sigCSA_cry_20[30]))));
  assign sigCSA_sum_21[32] = sigCSA_sum_20[32] ^ sigCSA_cry_20[31] ^ sigCSA_cry_19[24];
  assign sigCSA_cry_21[32] = ((sigCSA_sum_20[32] & sigCSA_cry_20[31])) | ((sigCSA_cry_19[24] & ((sigCSA_sum_20[32] ^ sigCSA_cry_20[31]))));
  assign sigCSA_sum_21[33] = sigCSA_sum_20[33] ^ sigCSA_cry_20[32] ^ sigCSA_cry_19[25];
  assign sigCSA_cry_21[33] = ((sigCSA_sum_20[33] & sigCSA_cry_20[32])) | ((sigCSA_cry_19[25] & ((sigCSA_sum_20[33] ^ sigCSA_cry_20[32]))));
  assign sigCSA_sum_21[34] = sigCSA_sum_20[34] ^ sigCSA_cry_20[33] ^ sigCSA_cry_19[26];
  assign sigCSA_cry_21[34] = ((sigCSA_sum_20[34] & sigCSA_cry_20[33])) | ((sigCSA_cry_19[26] & ((sigCSA_sum_20[34] ^ sigCSA_cry_20[33]))));
  assign sigCSA_sum_21[35] = sigCSA_sum_20[35] ^ sigCSA_cry_20[34] ^ sigCSA_cry_19[27];
  assign sigCSA_cry_21[35] = ((sigCSA_sum_20[35] & sigCSA_cry_20[34])) | ((sigCSA_cry_19[27] & ((sigCSA_sum_20[35] ^ sigCSA_cry_20[34]))));
  assign sigCSA_sum_21[36] = sigCSA_sum_20[36] ^ sigCSA_cry_20[35] ^ sigCSA_cry_19[28];
  assign sigCSA_cry_21[36] = ((sigCSA_sum_20[36] & sigCSA_cry_20[35])) | ((sigCSA_cry_19[28] & ((sigCSA_sum_20[36] ^ sigCSA_cry_20[35]))));
  assign sigCSA_sum_21[37] = sigCSA_sum_20[37] ^ sigCSA_cry_20[36] ^ sigCSA_cry_19[29];
  assign sigCSA_cry_21[37] = ((sigCSA_sum_20[37] & sigCSA_cry_20[36])) | ((sigCSA_cry_19[29] & ((sigCSA_sum_20[37] ^ sigCSA_cry_20[36]))));
  assign sigCSA_sum_21[38] = sigCSA_sum_20[38] ^ sigCSA_cry_20[37] ^ sigCSA_cry_19[30];
  assign sigCSA_cry_21[38] = ((sigCSA_sum_20[38] & sigCSA_cry_20[37])) | ((sigCSA_cry_19[30] & ((sigCSA_sum_20[38] ^ sigCSA_cry_20[37]))));
  assign sigCSA_sum_21[39] = sigCSA_sum_20[39] ^ sigCSA_cry_20[38] ^ sigCSA_cry_19[31];
  assign sigCSA_cry_21[39] = ((sigCSA_sum_20[39] & sigCSA_cry_20[38])) | ((sigCSA_cry_19[31] & ((sigCSA_sum_20[39] ^ sigCSA_cry_20[38]))));
  assign sigCSA_sum_21[40] = sigCSA_sum_20[40] ^ sigCSA_cry_20[39] ^ sigCSA_cry_19[32];
  assign sigCSA_cry_21[40] = ((sigCSA_sum_20[40] & sigCSA_cry_20[39])) | ((sigCSA_cry_19[32] & ((sigCSA_sum_20[40] ^ sigCSA_cry_20[39]))));
  assign sigCSA_sum_21[41] = sigCSA_sum_20[41] ^ sigCSA_cry_20[40] ^ sigCSA_cry_19[33];
  assign sigCSA_cry_21[41] = ((sigCSA_sum_20[41] & sigCSA_cry_20[40])) | ((sigCSA_cry_19[33] & ((sigCSA_sum_20[41] ^ sigCSA_cry_20[40]))));
  assign sigCSA_sum_21[42] = sigCSA_sum_20[42] ^ sigCSA_cry_20[41] ^ sigCSA_cry_19[34];
  assign sigCSA_cry_21[42] = ((sigCSA_sum_20[42] & sigCSA_cry_20[41])) | ((sigCSA_cry_19[34] & ((sigCSA_sum_20[42] ^ sigCSA_cry_20[41]))));
  assign sigCSA_sum_21[43] = sigCSA_sum_20[43] ^ sigCSA_cry_20[42] ^ sigCSA_cry_19[35];
  assign sigCSA_cry_21[43] = ((sigCSA_sum_20[43] & sigCSA_cry_20[42])) | ((sigCSA_cry_19[35] & ((sigCSA_sum_20[43] ^ sigCSA_cry_20[42]))));
  assign sigCSA_sum_21[44] = sigCSA_sum_20[44] ^ sigCSA_cry_20[43] ^ sigCSA_cry_19[36];
  assign sigCSA_cry_21[44] = ((sigCSA_sum_20[44] & sigCSA_cry_20[43])) | ((sigCSA_cry_19[36] & ((sigCSA_sum_20[44] ^ sigCSA_cry_20[43]))));
  assign sigCSA_sum_21[45] = sigCSA_sum_20[45] ^ sigCSA_cry_20[44] ^ sigCSA_cry_19[37];
  assign sigCSA_cry_21[45] = ((sigCSA_sum_20[45] & sigCSA_cry_20[44])) | ((sigCSA_cry_19[37] & ((sigCSA_sum_20[45] ^ sigCSA_cry_20[44]))));
  assign sigCSA_sum_21[46] = sigCSA_sum_20[46] ^ sigCSA_cry_20[45] ^ sigCSA_cry_19[38];
  assign sigCSA_cry_21[46] = ((sigCSA_sum_20[46] & sigCSA_cry_20[45])) | ((sigCSA_cry_19[38] & ((sigCSA_sum_20[46] ^ sigCSA_cry_20[45]))));
  assign sigCSA_sum_21[47] = sigCSA_sum_20[47] ^ sigCSA_cry_20[46] ^ sigCSA_cry_19[39];
  assign sigCSA_cry_21[47] = ((sigCSA_sum_20[47] & sigCSA_cry_20[46])) | ((sigCSA_cry_19[39] & ((sigCSA_sum_20[47] ^ sigCSA_cry_20[46]))));
  assign sigCSA_sum_21[48] = sigCSA_sum_20[48] ^ sigCSA_cry_20[47] ^ sigCSA_cry_19[40];
  assign sigCSA_cry_21[48] = ((sigCSA_sum_20[48] & sigCSA_cry_20[47])) | ((sigCSA_cry_19[40] & ((sigCSA_sum_20[48] ^ sigCSA_cry_20[47]))));
  assign sigCSA_sum_21[49] = sigCSA_sum_20[49] ^ sigCSA_cry_20[48] ^ 1'b 0;
  assign sigCSA_cry_21[49] = ((sigCSA_sum_20[49] & sigCSA_cry_20[48])) | ((1'b 0 & ((sigCSA_sum_20[49] ^ sigCSA_cry_20[48]))));
  assign sigCSA_sum_21[50] = sigCSA_sum_20[50] ^ sigCSA_cry_20[49] ^ 1'b 0;
  assign sigCSA_cry_21[50] = ((sigCSA_sum_20[50] & sigCSA_cry_20[49])) | ((1'b 0 & ((sigCSA_sum_20[50] ^ sigCSA_cry_20[49]))));
  assign sigCSA_sum_21[51] = sigCSA_sum_20[51] ^ sigCSA_cry_20[50] ^ 1'b 0;
  assign sigCSA_cry_21[51] = ((sigCSA_sum_20[51] & sigCSA_cry_20[50])) | ((1'b 0 & ((sigCSA_sum_20[51] ^ sigCSA_cry_20[50]))));
  assign sigCSA_sum_21[52] = sigCSA_sum_20[52] ^ sigCSA_cry_20[51] ^ 1'b 0;
  assign sigCSA_cry_21[52] = ((sigCSA_sum_20[52] & sigCSA_cry_20[51])) | ((1'b 0 & ((sigCSA_sum_20[52] ^ sigCSA_cry_20[51]))));
  assign sigCSA_sum_21[53] = sigCSA_sum_20[53] ^ sigCSA_cry_20[52] ^ 1'b 0;
  assign sigCSA_cry_21[53] = ((sigCSA_sum_20[53] & sigCSA_cry_20[52])) | ((1'b 0 & ((sigCSA_sum_20[53] ^ sigCSA_cry_20[52]))));
  assign sigCSA_sum_21[54] = sigCSA_sum_20[54] ^ sigCSA_cry_20[53] ^ 1'b 0;
  assign sigCSA_cry_21[54] = ((sigCSA_sum_20[54] & sigCSA_cry_20[53])) | ((1'b 0 & ((sigCSA_sum_20[54] ^ sigCSA_cry_20[53]))));
  assign sigCSA_sum_21[55] = 1'b 0 ^ sigCSA_cry_20[54] ^ 1'b 0;
  assign sigCSA_cry_21[55] = ((1'b 0 & sigCSA_cry_20[54])) | ((1'b 0 & ((1'b 0 ^ sigCSA_cry_20[54]))));
  // ******************
  // the final output
  assign result[0] = sigCSA_sum_21[0];
  assign result[1] = sigCSA_sum_21[1] ^ sigCSA_cry_21[0] ^ 1'b 0;
  assign carry_rca[0] = sigCSA_sum_21[1] & sigCSA_cry_21[0];
  assign result[2] = sigCSA_sum_21[2] ^ sigCSA_cry_21[1] ^ carry_rca[0];
  assign carry_rca[1] = ((sigCSA_sum_21[2] & sigCSA_cry_21[1])) | ((carry_rca[0] & ((sigCSA_sum_21[2] ^ sigCSA_cry_21[1]))));
  assign result[3] = sigCSA_sum_21[3] ^ sigCSA_cry_21[2] ^ carry_rca[1];
  assign carry_rca[2] = ((sigCSA_sum_21[3] & sigCSA_cry_21[2])) | ((carry_rca[1] & ((sigCSA_sum_21[3] ^ sigCSA_cry_21[2]))));
  assign result[4] = sigCSA_sum_21[4] ^ sigCSA_cry_21[3] ^ carry_rca[2];
  assign carry_rca[3] = ((sigCSA_sum_21[4] & sigCSA_cry_21[3])) | ((carry_rca[2] & ((sigCSA_sum_21[4] ^ sigCSA_cry_21[3]))));
  assign result[5] = sigCSA_sum_21[5] ^ sigCSA_cry_21[4] ^ carry_rca[3];
  assign carry_rca[4] = ((sigCSA_sum_21[5] & sigCSA_cry_21[4])) | ((carry_rca[3] & ((sigCSA_sum_21[5] ^ sigCSA_cry_21[4]))));
  assign result[6] = sigCSA_sum_21[6] ^ sigCSA_cry_21[5] ^ carry_rca[4];
  assign carry_rca[5] = ((sigCSA_sum_21[6] & sigCSA_cry_21[5])) | ((carry_rca[4] & ((sigCSA_sum_21[6] ^ sigCSA_cry_21[5]))));
  assign result[7] = sigCSA_sum_21[7] ^ sigCSA_cry_21[6] ^ carry_rca[5];
  assign carry_rca[6] = ((sigCSA_sum_21[7] & sigCSA_cry_21[6])) | ((carry_rca[5] & ((sigCSA_sum_21[7] ^ sigCSA_cry_21[6]))));
  assign result[8] = sigCSA_sum_21[8] ^ sigCSA_cry_21[7] ^ carry_rca[6];
  assign carry_rca[7] = ((sigCSA_sum_21[8] & sigCSA_cry_21[7])) | ((carry_rca[6] & ((sigCSA_sum_21[8] ^ sigCSA_cry_21[7]))));
  assign result[9] = sigCSA_sum_21[9] ^ sigCSA_cry_21[8] ^ carry_rca[7];
  assign carry_rca[8] = ((sigCSA_sum_21[9] & sigCSA_cry_21[8])) | ((carry_rca[7] & ((sigCSA_sum_21[9] ^ sigCSA_cry_21[8]))));
  assign result[10] = sigCSA_sum_21[10] ^ sigCSA_cry_21[9] ^ carry_rca[8];
  assign carry_rca[9] = ((sigCSA_sum_21[10] & sigCSA_cry_21[9])) | ((carry_rca[8] & ((sigCSA_sum_21[10] ^ sigCSA_cry_21[9]))));
  assign result[11] = sigCSA_sum_21[11] ^ sigCSA_cry_21[10] ^ carry_rca[9];
  assign carry_rca[10] = ((sigCSA_sum_21[11] & sigCSA_cry_21[10])) | ((carry_rca[9] & ((sigCSA_sum_21[11] ^ sigCSA_cry_21[10]))));
  assign result[12] = sigCSA_sum_21[12] ^ sigCSA_cry_21[11] ^ carry_rca[10];
  assign carry_rca[11] = ((sigCSA_sum_21[12] & sigCSA_cry_21[11])) | ((carry_rca[10] & ((sigCSA_sum_21[12] ^ sigCSA_cry_21[11]))));
  assign result[13] = sigCSA_sum_21[13] ^ sigCSA_cry_21[12] ^ carry_rca[11];
  assign carry_rca[12] = ((sigCSA_sum_21[13] & sigCSA_cry_21[12])) | ((carry_rca[11] & ((sigCSA_sum_21[13] ^ sigCSA_cry_21[12]))));
  assign result[14] = sigCSA_sum_21[14] ^ sigCSA_cry_21[13] ^ carry_rca[12];
  assign carry_rca[13] = ((sigCSA_sum_21[14] & sigCSA_cry_21[13])) | ((carry_rca[12] & ((sigCSA_sum_21[14] ^ sigCSA_cry_21[13]))));
  assign result[15] = sigCSA_sum_21[15] ^ sigCSA_cry_21[14] ^ carry_rca[13];
  assign carry_rca[14] = ((sigCSA_sum_21[15] & sigCSA_cry_21[14])) | ((carry_rca[13] & ((sigCSA_sum_21[15] ^ sigCSA_cry_21[14]))));
  assign result[16] = sigCSA_sum_21[16] ^ sigCSA_cry_21[15] ^ carry_rca[14];
  assign carry_rca[15] = ((sigCSA_sum_21[16] & sigCSA_cry_21[15])) | ((carry_rca[14] & ((sigCSA_sum_21[16] ^ sigCSA_cry_21[15]))));
  assign result[17] = sigCSA_sum_21[17] ^ sigCSA_cry_21[16] ^ carry_rca[15];
  assign carry_rca[16] = ((sigCSA_sum_21[17] & sigCSA_cry_21[16])) | ((carry_rca[15] & ((sigCSA_sum_21[17] ^ sigCSA_cry_21[16]))));
  assign result[18] = sigCSA_sum_21[18] ^ sigCSA_cry_21[17] ^ carry_rca[16];
  assign carry_rca[17] = ((sigCSA_sum_21[18] & sigCSA_cry_21[17])) | ((carry_rca[16] & ((sigCSA_sum_21[18] ^ sigCSA_cry_21[17]))));
  assign result[19] = sigCSA_sum_21[19] ^ sigCSA_cry_21[18] ^ carry_rca[17];
  assign carry_rca[18] = ((sigCSA_sum_21[19] & sigCSA_cry_21[18])) | ((carry_rca[17] & ((sigCSA_sum_21[19] ^ sigCSA_cry_21[18]))));
  assign result[20] = sigCSA_sum_21[20] ^ sigCSA_cry_21[19] ^ carry_rca[18];
  assign carry_rca[19] = ((sigCSA_sum_21[20] & sigCSA_cry_21[19])) | ((carry_rca[18] & ((sigCSA_sum_21[20] ^ sigCSA_cry_21[19]))));
  assign result[21] = sigCSA_sum_21[21] ^ sigCSA_cry_21[20] ^ carry_rca[19];
  assign carry_rca[20] = ((sigCSA_sum_21[21] & sigCSA_cry_21[20])) | ((carry_rca[19] & ((sigCSA_sum_21[21] ^ sigCSA_cry_21[20]))));
  assign result[22] = sigCSA_sum_21[22] ^ sigCSA_cry_21[21] ^ carry_rca[20];
  assign carry_rca[21] = ((sigCSA_sum_21[22] & sigCSA_cry_21[21])) | ((carry_rca[20] & ((sigCSA_sum_21[22] ^ sigCSA_cry_21[21]))));
  assign result[23] = sigCSA_sum_21[23] ^ sigCSA_cry_21[22] ^ carry_rca[21];
  assign carry_rca[22] = ((sigCSA_sum_21[23] & sigCSA_cry_21[22])) | ((carry_rca[21] & ((sigCSA_sum_21[23] ^ sigCSA_cry_21[22]))));
  assign result[24] = sigCSA_sum_21[24] ^ sigCSA_cry_21[23] ^ carry_rca[22];
  assign carry_rca[23] = ((sigCSA_sum_21[24] & sigCSA_cry_21[23])) | ((carry_rca[22] & ((sigCSA_sum_21[24] ^ sigCSA_cry_21[23]))));
  assign result[25] = sigCSA_sum_21[25] ^ sigCSA_cry_21[24] ^ carry_rca[23];
  assign carry_rca[24] = ((sigCSA_sum_21[25] & sigCSA_cry_21[24])) | ((carry_rca[23] & ((sigCSA_sum_21[25] ^ sigCSA_cry_21[24]))));
  assign result[26] = sigCSA_sum_21[26] ^ sigCSA_cry_21[25] ^ carry_rca[24];
  assign carry_rca[25] = ((sigCSA_sum_21[26] & sigCSA_cry_21[25])) | ((carry_rca[24] & ((sigCSA_sum_21[26] ^ sigCSA_cry_21[25]))));
  assign result[27] = sigCSA_sum_21[27] ^ sigCSA_cry_21[26] ^ carry_rca[25];
  assign carry_rca[26] = ((sigCSA_sum_21[27] & sigCSA_cry_21[26])) | ((carry_rca[25] & ((sigCSA_sum_21[27] ^ sigCSA_cry_21[26]))));
  assign result[28] = sigCSA_sum_21[28] ^ sigCSA_cry_21[27] ^ carry_rca[26];
  assign carry_rca[27] = ((sigCSA_sum_21[28] & sigCSA_cry_21[27])) | ((carry_rca[26] & ((sigCSA_sum_21[28] ^ sigCSA_cry_21[27]))));
  assign result[29] = sigCSA_sum_21[29] ^ sigCSA_cry_21[28] ^ carry_rca[27];
  assign carry_rca[28] = ((sigCSA_sum_21[29] & sigCSA_cry_21[28])) | ((carry_rca[27] & ((sigCSA_sum_21[29] ^ sigCSA_cry_21[28]))));
  assign result[30] = sigCSA_sum_21[30] ^ sigCSA_cry_21[29] ^ carry_rca[28];
  assign carry_rca[29] = ((sigCSA_sum_21[30] & sigCSA_cry_21[29])) | ((carry_rca[28] & ((sigCSA_sum_21[30] ^ sigCSA_cry_21[29]))));
  assign result[31] = sigCSA_sum_21[31] ^ sigCSA_cry_21[30] ^ carry_rca[29];
  assign carry_rca[30] = ((sigCSA_sum_21[31] & sigCSA_cry_21[30])) | ((carry_rca[29] & ((sigCSA_sum_21[31] ^ sigCSA_cry_21[30]))));
  assign result[32] = sigCSA_sum_21[32] ^ sigCSA_cry_21[31] ^ carry_rca[30];
  assign carry_rca[31] = ((sigCSA_sum_21[32] & sigCSA_cry_21[31])) | ((carry_rca[30] & ((sigCSA_sum_21[32] ^ sigCSA_cry_21[31]))));
  assign result[33] = sigCSA_sum_21[33] ^ sigCSA_cry_21[32] ^ carry_rca[31];
  assign carry_rca[32] = ((sigCSA_sum_21[33] & sigCSA_cry_21[32])) | ((carry_rca[31] & ((sigCSA_sum_21[33] ^ sigCSA_cry_21[32]))));
  assign result[34] = sigCSA_sum_21[34] ^ sigCSA_cry_21[33] ^ carry_rca[32];
  assign carry_rca[33] = ((sigCSA_sum_21[34] & sigCSA_cry_21[33])) | ((carry_rca[32] & ((sigCSA_sum_21[34] ^ sigCSA_cry_21[33]))));
  assign result[35] = sigCSA_sum_21[35] ^ sigCSA_cry_21[34] ^ carry_rca[33];
  assign carry_rca[34] = ((sigCSA_sum_21[35] & sigCSA_cry_21[34])) | ((carry_rca[33] & ((sigCSA_sum_21[35] ^ sigCSA_cry_21[34]))));
  assign result[36] = sigCSA_sum_21[36] ^ sigCSA_cry_21[35] ^ carry_rca[34];
  assign carry_rca[35] = ((sigCSA_sum_21[36] & sigCSA_cry_21[35])) | ((carry_rca[34] & ((sigCSA_sum_21[36] ^ sigCSA_cry_21[35]))));
  assign result[37] = sigCSA_sum_21[37] ^ sigCSA_cry_21[36] ^ carry_rca[35];
  assign carry_rca[36] = ((sigCSA_sum_21[37] & sigCSA_cry_21[36])) | ((carry_rca[35] & ((sigCSA_sum_21[37] ^ sigCSA_cry_21[36]))));
  assign result[38] = sigCSA_sum_21[38] ^ sigCSA_cry_21[37] ^ carry_rca[36];
  assign carry_rca[37] = ((sigCSA_sum_21[38] & sigCSA_cry_21[37])) | ((carry_rca[36] & ((sigCSA_sum_21[38] ^ sigCSA_cry_21[37]))));
  assign result[39] = sigCSA_sum_21[39] ^ sigCSA_cry_21[38] ^ carry_rca[37];
  assign carry_rca[38] = ((sigCSA_sum_21[39] & sigCSA_cry_21[38])) | ((carry_rca[37] & ((sigCSA_sum_21[39] ^ sigCSA_cry_21[38]))));
  assign result[40] = sigCSA_sum_21[40] ^ sigCSA_cry_21[39] ^ carry_rca[38];
  assign carry_rca[39] = ((sigCSA_sum_21[40] & sigCSA_cry_21[39])) | ((carry_rca[38] & ((sigCSA_sum_21[40] ^ sigCSA_cry_21[39]))));
  assign result[41] = sigCSA_sum_21[41] ^ sigCSA_cry_21[40] ^ carry_rca[39];
  assign carry_rca[40] = ((sigCSA_sum_21[41] & sigCSA_cry_21[40])) | ((carry_rca[39] & ((sigCSA_sum_21[41] ^ sigCSA_cry_21[40]))));
  assign result[42] = sigCSA_sum_21[42] ^ sigCSA_cry_21[41] ^ carry_rca[40];
  assign carry_rca[41] = ((sigCSA_sum_21[42] & sigCSA_cry_21[41])) | ((carry_rca[40] & ((sigCSA_sum_21[42] ^ sigCSA_cry_21[41]))));
  assign result[43] = sigCSA_sum_21[43] ^ sigCSA_cry_21[42] ^ carry_rca[41];
  assign carry_rca[42] = ((sigCSA_sum_21[43] & sigCSA_cry_21[42])) | ((carry_rca[41] & ((sigCSA_sum_21[43] ^ sigCSA_cry_21[42]))));
  assign result[44] = sigCSA_sum_21[44] ^ sigCSA_cry_21[43] ^ carry_rca[42];
  assign carry_rca[43] = ((sigCSA_sum_21[44] & sigCSA_cry_21[43])) | ((carry_rca[42] & ((sigCSA_sum_21[44] ^ sigCSA_cry_21[43]))));
  assign result[45] = sigCSA_sum_21[45] ^ sigCSA_cry_21[44] ^ carry_rca[43];
  assign carry_rca[44] = ((sigCSA_sum_21[45] & sigCSA_cry_21[44])) | ((carry_rca[43] & ((sigCSA_sum_21[45] ^ sigCSA_cry_21[44]))));
  assign result[46] = sigCSA_sum_21[46] ^ sigCSA_cry_21[45] ^ carry_rca[44];
  assign carry_rca[45] = ((sigCSA_sum_21[46] & sigCSA_cry_21[45])) | ((carry_rca[44] & ((sigCSA_sum_21[46] ^ sigCSA_cry_21[45]))));
  assign result[47] = sigCSA_sum_21[47] ^ sigCSA_cry_21[46] ^ carry_rca[45];
  assign carry_rca[46] = ((sigCSA_sum_21[47] & sigCSA_cry_21[46])) | ((carry_rca[45] & ((sigCSA_sum_21[47] ^ sigCSA_cry_21[46]))));
  assign result[48] = sigCSA_sum_21[48] ^ sigCSA_cry_21[47] ^ carry_rca[46];
  assign carry_rca[47] = ((sigCSA_sum_21[48] & sigCSA_cry_21[47])) | ((carry_rca[46] & ((sigCSA_sum_21[48] ^ sigCSA_cry_21[47]))));
  assign result[48] = sigCSA_cry_21[47] ^ carry_rca[46];

endmodule