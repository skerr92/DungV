# OASIS Assembly

DungV uses the assembler from the pinned OASIS submodule:

```sh
python3 ../OASIS/tools/oasis_asm.py ../examples/add_store.oas -o ../.build/examples/add_store.mem
```

The syntax described here matches OASIS Base-16 v0.1.

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

## Generated Images

Run `make examples` from the repo root to assemble every `examples/*.oas` source
into a `$readmemb`-friendly `.mem` file under `.build/examples/`.
