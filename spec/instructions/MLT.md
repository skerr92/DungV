# MLT

Encoding: `CLASS=01`, `OPCODE=1011`

Syntax: `MLT ra, rb`

Operation: `ra = low16(ra * rb)`

Flags: none

Cycles: one execute cycle in DungV

Exceptions: none

Example:

```asm
MVI r1, 7
MVI r2, 6
MLT r1, r2
```
