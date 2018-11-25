module candy (input clk,
			input reset,
			);
endmodule

module candy_regs(input clk,
                input write_enable,
                input [3:0] waddr,
                input [3:0] raddr1,
                input [3:0] raddr2,
                input [23:0] wdata,
                output [23:0] rdata1,
                output [23:0] rdata2
                );

    reg [23:0] regs [0:15];

    always @(posedge clk)
        if (write_enable) begin
			regs[waddr] <= wdata;
        end

	assign rdata1 = regs[raddr1];
	assign rdata2 = regs[raddr2];

endmodule

//module candy_mem()

//endmodule