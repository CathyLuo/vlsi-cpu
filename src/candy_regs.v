`include "defines.v"

module candy_regs(input wire clk,
                input wire rst,

                input wire we,
                input wire [`RegAddrBus] waddr,
                input wire [`RegBus] wdata,

                input wire re1,
                input wire [`RegAddrBus] raddr1,
                output reg [`RegAddrBus] rdata1,

                input wire re2,
                input wire [`RegAddrBus] raddr2,
                output reg [`RegAddrBus] rdata2
);

    reg [`RegBus] regs [0:`RegNum-1];

    always @(posedge clk) begin
        if(rst == `RstDisable) begin
            //write
            if((we == `WriteEnable) && (waddr != `RegWidth'b0)) begin
                regs[waddr] <= waddr;
            end
            //read 1
            if(raddr1 == `RegWidth'b0) begin
                rdata1 <= `ZeroWord;
            end
            else if ((raddr1 == waddr) && (we == `WriteEnable) && (re1)) begin
                rdata1 <= wdata;
            end
            else if (re1 == `ReadEnable) begin
                rdata1 <= regs[raddr1];
            end            
            else begin
                rdata1 <= `ZeroWord;
            end
            
            //read2
            if(raddr2 == `RegWidth'b0) begin
                rdata2 <= `ZeroWord;
            end
            else if ((raddr2 == waddr) && (we == `WriteEnable) && (re2)) begin
                rdata2 <= wdata;
            end
            else if (re2 == `ReadEnable) begin
                rdata2 <= regs[raddr2];
            end            
            else begin
                rdata2 <= `ZeroWord;
            end
        

            if(rst == `RstEnable) begin
                rdata1 <= `ZeroWord;
                rdata2 <= `ZeroWord;
            end
        end
    end

endmodule