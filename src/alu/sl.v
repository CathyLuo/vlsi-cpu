module ALU_SL (
	input  wire [`ALUDATA] in_0,  // input signal 0
	input  wire [`ALUDATA] in_1,  // input signal 1 
	output reg	[`ALUDATA] out,	  // output 
	output reg	error	  // error
);

	
	always @(*) begin
            out	  = in_0 << in_1[`ShAmountLoc];
	end
    endmodule