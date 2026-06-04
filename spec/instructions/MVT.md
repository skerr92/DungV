# MVT

Encoding: `CLASS=11`, `OPCODE=10`

Syntax: `MVT ra, [addr9]`

Operation: `memory[addr9] = ra`

Flags: none

Cycles: one execute cycle in DungV

Exceptions: none

Example:

```asm
MVI r1, 0x1234
MVT r1, [0x001]
```
