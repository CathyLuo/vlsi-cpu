`include "candy_defines.v"

module candy_id(
    input wire clk,
    input wire rst,
    input wire [`RegBus] inst,
     
    output reg[`Rop] op,
    output reg [`RegAddrBus] rs1,
    output reg [`RegAddrBus] rs2,
    output reg [`RegAddrBus] rd,

    output [`ImmWdith] imm_data
);

wire [`type] typecode = inst[23:22];

always @ (posedge clk) begin
    if(rst == `RstEnable) begin
        raddr1 <= 4'b0;
        raddr2 <= 4'b0;

        reg1_data <= 24'b0;
        reg2_data <= 24'b0;
        
        op <= 6'b0;
    end
    else begin
        case(typecode)
            `R:     begin
                op <= inst[21:16];
                rs1 <= inst[15:12];
                rs2 <= inst[11:8];
                rd <= inst[7:3];
            end
            `I:     begin
                op <= {2'b0 + inst[21:18]};
                rs1 <= inst[17:14];
                rd <= inst[13:10];
                imm <= inst[9:0];
            end 
            `S:     begin
                op <= {2'b0 + inst[21:18]};
                rs1 <= inst[17:14];
                rs2 <= inst[13:10];
                imm <= inst[9:0];
            end
            `U:     begin
                op <= {4'b0 + inst[21:19]};
                rd <= inst[19:16];
                imm <= inst[15:0];
            end
        endcase
    end
end