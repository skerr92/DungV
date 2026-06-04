# MVV

Encoding: `CLASS=10`, `OPCODE=10`

Syntax: `MVV ra, rb`

Operation: `ra = rb`

Flags: none

Cycles: one execute cycle in DungV

Exceptions: none

Example:

```asm
MVI r1, 0x1234
MVV r2, r1
```
