# DungV Testing

DungV should use layered tests.

## 1. RTL Unit Tests

Local RTL tests should cover individual modules:

| Module | First tests |
| ------ | ----------- |
| `instr_decode` | Decode each instruction class and reserved defaults |
| `alu` | ALU opcodes, wraparound, rotate-by-zero |
| `register_file` | Reset, read, write, read-after-write behavior |
| `data_mem` | Read default, write, read-after-write behavior |
| `oasis_core` | Tiny programs for moves, ALU, memory, and jumps |

These belong under `tests/rtl/` or `rtl/dungv/sim/testbenches/`.

Current smoke tests live in `rtl/dungv/sim/testbenches/` and can be run from the
DungV RTL directory when `iverilog` and `vvp` are installed:

```sh
cd rtl/dungv
make test
```

## 2. ISA Compliance Tests

Once the sister OASIS ISA repository exists, DungV should consume its compliance
programs as a pinned dependency. Until then, `tests/compliance/` records the
coverage plan for the local OASIS v0.1 draft.

## 3. Golden Model Tests

The long-term verification loop should compare DungV simulation results against
a small software OASIS model:

```text
assembly program -> assembler -> binary image
binary image -> software model -> expected state
binary image -> RTL simulation -> observed state
expected state == observed state
```

## 4. CI Targets

Useful DungV CI jobs:

- Verilog lint
- RTL unit tests
- OASIS compliance programs
- iCE40 synthesis smoke test
- Documentation link checks

CI should report the spec version or commit used for compliance.
