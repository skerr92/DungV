# OASIS Compatibility

DungV targets the OASIS v0.1 baseline pinned in the `OASIS/` submodule. The
local `spec/oasis-v0.1.md` snapshot remains as historical context, but the
submodule is the active source for assembler tooling and compliance inputs.

## Target

| Item | Value |
| ---- | ----- |
| ISA profile | OASIS Base-16 draft |
| OASIS source | `OASIS/` submodule |
| Local spec snapshot | `spec/oasis-v0.1.md` |
| DungV status | Experimental |
| Data width | 16 bits |
| Instruction width | 32 bits |
| Register count | 64 |
| Program counter | 8-bit instruction index |

## Compliance Inputs

Run the current Base-16 v0.1 compliance-image generation flow with:

```sh
make compliance
```

This filters `OASIS/tests/compliance/` to `oasis-base16-v0.1-draft` and emits
DungV-readable `.oas` and `.mem` files under
`.build/compliance/base16-v0.1/`.

Base-16T compliance is intentionally out of scope until DungV implements the
class `00` toolchain instructions.

## Instruction Status

| Instruction | Specified | Implemented | Tested |
| ----------- | --------- | ----------- | ------ |
| `ADD` | Yes | Yes | Compliance image generated |
| `SUB` | Yes | Yes | Compliance image generated |
| `AND` | Yes | Yes | Compliance image generated |
| `OOR` | Yes | Yes | Compliance image generated |
| `XOR` | Yes | Yes | Compliance image generated |
| `SHR` | Yes | Yes | Compliance image generated |
| `SHL` | Yes | Yes | Compliance image generated |
| `RTR` | Yes | Yes | Compliance image generated |
| `RTL` | Yes | Yes | Compliance image generated |
| `NOT` | Yes | Yes | Compliance image generated |
| `MLT` | Yes | Yes | Compliance image generated |
| `JEQ` | Yes | Yes | Compliance image generated |
| `JNE` | Yes | Yes | Compliance image generated |
| `JMP` | Yes | Yes | Compliance image generated |
| `NOP` | Yes | Yes | Compliance image generated |
| `MVV` | Yes | Yes | Compliance image generated |
| `MVI` | Yes | Yes | Compliance image generated |
| `MVF` | Yes | Yes | Compliance image generated |
| `MVT` | Yes | Yes | Compliance image generated |
| `MSI` | Yes | Yes | Compliance image generated |

## Open Compatibility Questions

These should move to the OASIS ISA repository when it becomes the source of
truth:

- Whether `r0` remains writable or becomes hardwired zero
- Whether reset values for registers and memory are architectural
- Whether data memory should stay word-addressed or become byte-addressed
- Whether invalid or reserved instructions remain no-ops
- Whether future branches use absolute targets or relative offsets
