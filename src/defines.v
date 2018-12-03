`define RstEnable 1'b1
`define RstDisable 1'b0 

`define WriteEnable 1'b1
`define WriteDisable 1'b0
`define ReadEnable 1'b1
`define ReadDisable 1'b0

`define ZeroWord 24'b0

//candy: register file
`define RegAddrBus 3:0
`define RegBus 23:0
`define RegWidth 24
`define RegNum 16
`define ALUDATA 23:0
`define EXE_OP 5:0
`define EXE_ADD 000000
`define EXE_ADDI 0000
`define EXE_SUB 000001
`define EXE_AND 001000
`define EXE_ANDI 0001
`define EXE_OR 001001
`define EXE_ORI 0010
`define EXE_XOR 001010
`define EXE_XORI 0011
`define ShAmountLoc	4:0