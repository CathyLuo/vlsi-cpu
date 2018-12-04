module fulladder(
    input wire rs1_i,
    input wire rs2_i,
    input wire cin_i,

    output reg sum_o,
    output reg cout_o
);

    assign sum_o = rs1_i ^ rs2_i ^ cin_i;
    assign cout_o = (rs1_i & rs2_i) | (rs1_i & cin_i) | (rs2_i & cin_i);

endmodule // fulladder