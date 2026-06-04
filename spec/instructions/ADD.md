# ADD

Encoding: `CLASS=01`, `OPCODE=0001`

Syntax: `ADD ra, rb`

Operation: `ra = ra + rb`

Flags: none

Cycles: one execute cycle in DungV

Exceptions: none

Example:

```asm
MVI r1, 10
MVI r2, 20
ADD r1, r2
```
