module halfadder(
    input wire rs1_i,
    input wire rs2_i,

    output reg sum_o,
    output reg cout_o
);

assign sum_o = rs1_i ^ rs2_i;
assign cout_o = rs1_i & rs2_i;

endmodule // halfadde
