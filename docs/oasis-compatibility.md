# OASIS Compatibility

DungV currently targets the local OASIS v0.1 draft in
`spec/oasis-v0.1.md`. When the sister OASIS ISA repository exists, this page
should record the pinned spec version or commit consumed by DungV.

## Target

| Item | Value |
| ---- | ----- |
| ISA profile | OASIS Base-16 draft |
| Local spec | `spec/oasis-v0.1.md` |
| DungV status | Experimental |
| Data width | 16 bits |
| Instruction width | 32 bits |
| Register count | 64 |
| Program counter | 8-bit instruction index |

## Instruction Status

| Instruction | Specified | Implemented | Tested |
| ----------- | --------- | ----------- | ------ |
| `ADD` | Yes | Yes | No |
| `SUB` | Yes | Yes | No |
| `AND` | Yes | Yes | No |
| `OOR` | Yes | Yes | No |
| `XOR` | Yes | Yes | No |
| `SHR` | Yes | Yes | No |
| `SHL` | Yes | Yes | No |
| `RTR` | Yes | Yes | No |
| `RTL` | Yes | Yes | No |
| `NOT` | Yes | Yes | No |
| `MLT` | Yes | Yes | No |
| `JEQ` | Yes | Yes | No |
| `JNE` | Yes | Yes | No |
| `JMP` | Yes | Yes | No |
| `NOP` | Yes | Yes | No |
| `MVV` | Yes | Yes | No |
| `MVI` | Yes | Yes | No |
| `MVF` | Yes | Yes | No |
| `MVT` | Yes | Yes | No |
| `MSI` | Yes | Yes | No |

## Open Compatibility Questions

These should move to the OASIS ISA repository when it becomes the source of
truth:

- Whether `r0` remains writable or becomes hardwired zero
- Whether reset values for registers and memory are architectural
- Whether data memory should stay word-addressed or become byte-addressed
- Whether invalid or reserved instructions remain no-ops
- Whether future branches use absolute targets or relative offsets
