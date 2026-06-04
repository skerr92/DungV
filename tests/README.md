# Tests

This directory is reserved for DungV RTL tests and OASIS compliance tests.

The first verification target should be an instruction-by-instruction compliance
suite that runs small programs against `rtl/dungv/core/oasis_core.v` and checks:

- Final `pc`
- Final `debug_out`
- Selected register values
- Selected data memory values

Recommended first programs:

- `mvi_mvv`: immediate and register moves
- `alu_basic`: add, subtract, and, or, xor, not, multiply
- `shift_rotate`: shift and rotate edge cases, including amount zero
- `memory`: `MSI`, `MVF`, and `MVT`
- `jumps`: `JEQ`, `JNE`, `JMP`, and `NOP`
