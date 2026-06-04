# SUB

Encoding: `CLASS=01`, `OPCODE=0010`

Syntax: `SUB ra, rb`

Operation: `ra = ra - rb`

Flags: none

Cycles: one execute cycle in DungV

Exceptions: none

Example:

```asm
MVI r1, 30
MVI r2, 20
SUB r1, r2
```
