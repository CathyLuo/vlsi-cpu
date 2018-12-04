module csa24_tb;
    
    reg [23:0] op1;
    reg [23:0] op2;
    wire [24:0] result;

    csa24 csa(.op1(op1), .op2(op2), .result(result));

    initial begin
        #0 begin
            op1 <= 24'h96;
            op2 <= 24'ha7;   
        end
        #1 begin    
            op2 <= ~op2 + 1;
        end  
    end
endmodule // walltree_mul_tb