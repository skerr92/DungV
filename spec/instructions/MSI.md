# MSI

Encoding: `CLASS=11`, `OPCODE=11`

Syntax: `MSI [addr9], imm16`

Operation: `memory[addr9] = imm16`

Flags: none

Cycles: one execute cycle in DungV

Exceptions: none

Example:

```asm
MSI [0x001], 0x1234
```
