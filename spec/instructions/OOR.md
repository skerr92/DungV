# OOR

Encoding: `CLASS=01`, `OPCODE=0100`

Syntax: `OOR ra, rb`

Operation: `ra = ra | rb`

Flags: none

Cycles: one execute cycle in DungV

Exceptions: none

Example:

```asm
MVI r1, 0x00f0
MVI r2, 0x0f00
OOR r1, r2
```
