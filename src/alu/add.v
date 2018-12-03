module ALU_ADD (
	/********************** another way to calculate add 
    input  wire [`ALUDATA] in_0,  // input signal 0
	input  wire [`ALUDATA] in_1,  // input signal 1 
	output reg	[`ALUDATA] out,	  // output 
	output reg	Carry	  // error
);
    wire [24:0] sum;
	
	always @(*) begin
           sum = in_0 + in_1;
           out = sum[23:0];
           Carry = sum[24];

	end
    endmodule
    ************************/

	input  wire [`ALUDATA] in_0,  // input signal 0
	input  wire [`ALUDATA] in_1,  // input signal 1 
	output reg	[`ALUDATA] out,	  // output 
	output reg	overflow	  // overflow
);

    wire signed [`ALUDATA] s_in_0 = $signed(in_0); // signed R0
	wire signed [`ALUDATA] s_in_1 = $signed(in_1); // signed R1
	wire signed [`ALUDATA] s_out  = $signed(out);  // signed out



/*************** calculation ************/
	always @(*) begin
           out = in_0 + in_1;

	end
    endmodule

/************* overflow check ************/
	always @(*) begin
if (((s_in_0 > 0) && (s_in_1 > 0) && (s_out < 0)) ||
					((s_in_0 < 0) && (s_in_1 < 0) && (s_out > 0))) begin
					of = `ENABLE;
				end else begin
					of = `DISABLE;
				end

default		: begin // initial value 
				of = `DISABLE;
			end

	end

endmodule