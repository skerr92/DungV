# RTL

Encoding: `CLASS=01`, `OPCODE=1001`

Syntax: `RTL ra, imm6`

Operation: `ra = rotate_left(ra, imm6)`

Flags: none

Cycles: one execute cycle in DungV

Exceptions: none

Example:

```asm
MVI r1, 0x8000
RTL r1, 1
```
