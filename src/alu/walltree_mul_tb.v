module walltree_mul_tb;
    
    reg [23:0] op1;
    reg [23:0] op2;
    wire [48:0] result;

    walltree_mul wm(.op1(op1), .op2(op2), .result(result));

    initial begin
        #0 begin
            op1 <= 24'h96;
            op2 <= 24'ha7;    
        end  
    end
endmodule // walltree_mul_tb




