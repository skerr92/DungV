# XOR

Encoding: `CLASS=01`, `OPCODE=0101`

Syntax: `XOR ra, rb`

Operation: `ra = ra ^ rb`

Flags: none

Cycles: one execute cycle in DungV

Exceptions: none

Example:

```asm
MVI r1, 0x00ff
MVI r2, 0x0f0f
XOR r1, r2
```
