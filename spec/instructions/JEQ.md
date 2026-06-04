# JEQ

Encoding: `CLASS=01`, `OPCODE=1100`

Syntax: `JEQ ra, rb, target8`

Operation: `pc = target8` when `ra == rb`

Flags: none

Cycles: one execute cycle in DungV

Exceptions: none

Example:

```asm
MVI r1, 5
MVI r2, 5
JEQ r1, r2, equal
```
