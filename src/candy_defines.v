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

`define EXE_ADD 6'b000000
`define EXE_ADDI 4'b0000
`define EXE_SUB 6'b000001

`define EXE_MUL 6'b000010
`define EXE_DIV 6'b000011
`define EXE_DIVU 6'b000100
`define EXE_REM 6'b000101
`define EXE_REMU 6'b000110

`define EXE_AND 6'b001000
`define EXE_ANDI 4'b0001
`define EXE_OR 6'b001001
`define EXE_ORI 4'b0010
`define EXE_XOR 6'b001010
`define EXE_XORI 4'b0011

`define EXE_SLL 6'b010000
`define EXE_SLLI 4'b0100
`define EXE_SRA 6'b010001
`define EXE_SRAI 4'b0101
`define EXE_SRL 6'b010010
`define EXE_SRLI 4'b0110

//NEG
`define EXE_NEG 6'b100000
`define EXE_NOT 6'b110000

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

//SRAM controller
`define SRAMDataWidth   23:0
`define SRAMAddrWidth   16:0 
`define LoadEnable 1'b1
`define ReadReady 1'b1
`define ReadNotReady 1'b0


`define ChipDisable 1'b0
`define ChipEnable 1'b1

//inst format
`define type 1:0
`define ROP 5:0
`define IOP 3:0
`define SOP 3:0
`define UOP 1:0
`define ImmWidth 15:0

`define R 00
`define I 01
`define S 10
`define U 11

//execution
`define IF 00
`define ID 01
`define EX 10
`define WB 11