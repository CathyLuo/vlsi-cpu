module div_tb;
    
    reg clk;
    reg rst;

    reg signed_div_i;
        

	reg[23:0] opdata1_i;
	reg[23:0] opdata2_i;
	reg start_i;
	reg annul_i;

    //wire[47:0] result_o;
    wire [23:0]		quotient_o;
	wire [23:0]		remainder_o;
    wire ready_o;

   
    div div0(.clk(clk),
            .rst(rst),
            .signed_div_i(signed_div_i),
            .opdata1_i(opdata1_i),
            .opdata2_i(opdata2_i),
            .start_i(start_i),
            .annul_i(annul_i),
            .remainder_o(remainder_o),
            .quotient_o(quotient_o),
            .ready_o(ready_o));

    
    
    initial begin
        #0 begin
            clk <= 1'b0;
            rst <= 1'b1;
            signed_div_i <= 1'b0;
            opdata1_i <= 24'd704;
            opdata2_i <= 24'd36;
            start_i <= 1'b1;
            annul_i <= 1'b0;
        end
        #20 begin
            rst <= 1'b0;
        end
    end


    always #5 clk <= ~clk;
    

endmodule // div_tb