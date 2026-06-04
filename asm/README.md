# OASIS Assembly

This directory is reserved for future assembler tooling. The syntax described
here matches OASIS v0.1.

## Syntax

- One instruction per line.
- Labels end with `:`.
- Comments begin with `;`.
- Registers are written as `r0` through `r63`.
- Decimal immediates are written as `42`.
- Binary immediates are written as `0b101010`.
- Hex immediates are written as `0x002a`.
- Memory operands use brackets, such as `[0x001]`.

## Example

```asm
start:
MVI r1, 0x000a
MVI r2, 0x0014
ADD r1, r2
MVT r1, [0x001]
JMP start
```

## Future Tooling

The next useful tool here is a small assembler that emits 32-bit binary words
for `instr_mem`.
