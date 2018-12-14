`include "candy_defines.v"

module candy_id(
    input wire clk,
    input wire rst,
    input wire [`RegBus] inst,
    input wire id_enable,
     
    output reg[`ROP] op,
    output reg [`RegAddrBus] rs1,
    output reg [`RegAddrBus] rs2,
    output reg [`RegAddrBus] rd,

    output reg [`ImmWidth] imm_data,
    output reg re1,
    output reg re2
);

wire [`type] typecode = inst[23:22];

always @ (posedge clk) begin
    if(rst == `RstEnable) begin
        rs1 <= 4'b0;
        rs2 <= 4'b0;
        op <= 6'b0;
        re1 <= 1'b0;
        re2 <= 1'b0;
    end
    else begin
        if(id_enable) begin
            case(typecode)
                `R:     begin
                    op <= inst[21:16];
                    rs1 <= inst[15:12];
                    rs2 <= inst[11:8];
                    rd <= inst[7:3];
                    re1 <= 1'b1;
                    re2 <= 1'b1;                    
                end
                `I:     begin
                    op <= {2'b0 + inst[21:18]};
                    rs1 <= inst[17:14];
                    rd <= inst[13:10];
                    imm_data <= inst[9:0];
                    re1 <= 1'b1;
                    re2 <= 1'b0;
                end 
                `S:     begin
                    op <= {2'b0 + inst[21:18]};
                    rs1 <= inst[17:14];
                    rs2 <= inst[13:10];
                    imm_data <= inst[9:0];
                    re1 <= 1'b1;
                    re2 <= 1'b1;  
                end
                `U:     begin
                    op <= {4'b0 + inst[21:19]};
                    rd <= inst[19:16];
                    imm_data <= inst[15:0];
                    re1 <= 1'b0;
                    re2 <= 1'b0;  
                end
            endcase
        end
    end
end

endmodule