# RTR

Encoding: `CLASS=01`, `OPCODE=1000`

Syntax: `RTR ra, imm6`

Operation: `ra = rotate_right(ra, imm6)`

Flags: none

Cycles: one execute cycle in DungV

Exceptions: none

Example:

```asm
MVI r1, 0x0001
RTR r1, 1
```
