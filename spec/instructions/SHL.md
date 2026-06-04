# SHL

Encoding: `CLASS=01`, `OPCODE=0111`

Syntax: `SHL ra, imm6`

Operation: `ra = ra << imm6`

Flags: none

Cycles: one execute cycle in DungV

Exceptions: none

Example:

```asm
MVI r1, 0x0001
SHL r1, 4
```
