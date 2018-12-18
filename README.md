# 24bit RISC-V Variation CPU Design from Layout Level

# 1. Instruction Set
  Customized RISC-V ISA

| Inst  | Function                           | Type | TypeCode | Opcode |
|-------|------------------------------------|------|----------|--------|
| add   | Add                                | R    | 00       | 000000 |
| addi  | Add immediate                      | I    | 01       | 0000   |
| sub   | Sub                                | R    | 00       | 000001 |
| mul   | Mul                                | R    | 00       | 000010 |
| div   | Div                                | R    | 00       | 000011 |
| divu  | Div unsigned                       | R    | 00       | 000100 |
| rem   | Rem                                | R    | 00       | 000101 |
| remu  | Rem unsigned                       | R    | 00       | 000110 |
| and   | And                                | R    | 00       | 001000 |
| andi  | And immediate                      | I    | 01       | 0001   |
| or    | Or                                 | R    | 00       | 001001 |
| ori   | Or immediate                       | I    | 01       | 0010   |
| xor   | Xor                                | R    | 00       | 001010 |
| xori  | Xor immediate                      | I    | 01       | 0011   |
| sll   | Shift left                         | R    | 00       | 010000 |
| slli  | Shift left immediate               | I    | 01       | 0100   |
| sra   | Shift right   arithmetic           | R    | 00       | 010001 |
| srai  | Shift right   arithmetic immediate | I    | 01       | 0101   |
| srl   | Shift right                        | R    | 00       | 010010 |
| srli  | Shift right immediate              | I    | 01       | 0110   |
| slt   | Set less than                      | R    | 00       | 100000 |
| slti  | Set less than   immediate          | I    | 01       | 0111   |
| sltiu | Set less than   immediate unsigned | I    | 01       | 1000   |
| beq   | Branch if equal                    | SB   | 10       | 0000   |
| bge   | Branch if >=                       | SB   | 10       | 0001   |
| bgeu  | Branch if >=   unsigned            | SB   | 10       | 0010   |
| blt   | Branch if <                        | SB   | 10       | 0011   |
| bltu  | Branch if <   unsigned             | SB   | 10       | 0100   |
| bne   | Branch if !=                       | SB   | 10       | 0101   |
| jal   | Jump and Link                      | UJ   | 11       | 000    |
| jalr  | Jump and Link   register           | I    | 01       | 1001   |
| lb    | Load byte                          | I    | 01       | 1010   |
| lw    | Load word                          | I    | 01       | 1011   |
| lui   | Load upper immediate               | U    | 11       | 101    |
| lli   | Load lower immediate               | U    | 11       | 100    |
| sb    | Store byte                         | S    | 10       | 1000   |
| sw    | Store word                         | S    | 10       | 1001   |

# 2. Instruction Set Format
| Inst type        | Typecode | Opcode | RS1 | RS2 | RD | Imm       |
|------------------|----------|--------|-----|-----|----|-----------|
| R(Register)      | Typecode | Opcode | RS1 | RS2 | RD |           |
| I(immediate+Reg) | Typecode | Opcode | RS1 |     | RD | imm       |
| S(Reg+Addr)      | Typecode | Opcode | RS1 | RS2 |    | imm(addr) |
| SB(Branch)       | Typecode | Opcode | RS1 | RS2 |    | imm       |
| U(big imm)       | Typecode | Opcode |     |     | RD | imm(big)  |
| UJ(Jump addr)    | Typecode | Opcode |     |     | RD | imm(addr) |
# 3. Register File
# 4. Communication BUS


