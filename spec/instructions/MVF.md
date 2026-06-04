# MVF

Encoding: `CLASS=11`, `OPCODE=01`

Syntax: `MVF ra, [addr9]`

Operation: `ra = memory[addr9]`

Flags: none

Cycles: one execute cycle in DungV

Exceptions: none

Example:

```asm
MVF r1, [0x001]
```
