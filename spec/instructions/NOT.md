# NOT

Encoding: `CLASS=01`, `OPCODE=1010`

Syntax: `NOT ra`

Operation: `ra = ~ra`

Flags: none

Cycles: one execute cycle in DungV

Exceptions: none

Example:

```asm
MVI r1, 0x00ff
NOT r1
```
