# SHR

Encoding: `CLASS=01`, `OPCODE=0110`

Syntax: `SHR ra, imm6`

Operation: `ra = ra >> imm6`

Flags: none

Cycles: one execute cycle in DungV

Exceptions: none

Example:

```asm
MVI r1, 0x8000
SHR r1, 4
```
