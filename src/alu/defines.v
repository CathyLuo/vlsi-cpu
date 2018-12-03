`define RstEnable 1'b1
`define RstDisable 1'b0 

`define WriteEnable 1'b1
`define WriteDisable 1'b0
`define ReadEnable 1'b1
`define ReadDisable 1'b0

`define ZeroWord 24'b0

//candy: intruction format
`define R_typecode 00
`define I_typecode 01
`define S_typecode 10
`define SB_typecode 10
`define U_typecode 11
`define UJ_typecode 11

`define R_opcode 5:0
`define I_opcode 3:0
`define S_opcode 3:0
`define SB_opcode 3:0
`define U_opcode 1:0
`define UJ_opcode 1:0

`define EXE_MUL 000010
`define EXE_DIV 000011
`define EXE_DIVU 000100
`define EXE_REM 000101
`define EXE_REMU 000110

`define EXE_SLL 010000
`define EXE_SLLI 0100
`define EXE_SRA 010001
`define EXE_SRAI 0101
`define EXE_SRL 010010
`define EXE_SRLI 0110

//candy: register file
`define RegAddrBus 3:0
`define RegBus 23:0
`define DoubleRegBus 47:0
`define RegWidth 24
`define RegNum 16

//candy: ALU

`define AluOpBus 5:0


//candy: error code
`define Overflow 00
`define Dividebyzero 01

//div
`define ResultWidth 47:0
//`define Dividebyzero 01
`define singed_div 1'b1
`define unsigned_div 1'b0


//div
`define DivFree 			2'b00
`define DivByZero 			2'b01
`define DivOn 				2'b10
`define DivEnd 				2'b11
`define DivResultReady 		1'b1
`define DivResultNotReady 	1'b0
`define DivStart 			1'b1
`define DivStop 			1'b0
