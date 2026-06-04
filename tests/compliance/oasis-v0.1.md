# OASIS v0.1 Compliance Plan

Each instruction should have at least one passing test program and one edge-case
test where applicable.

| Instruction | Required coverage |
| ----------- | ----------------- |
| `ADD` | Basic addition and 16-bit wrap |
| `SUB` | Basic subtraction and underflow wrap |
| `AND` | Mixed bit mask |
| `OOR` | Mixed bit mask |
| `XOR` | Mixed bit mask |
| `SHR` | Shift by zero and nonzero amount |
| `SHL` | Shift by zero and nonzero amount |
| `RTR` | Rotate by zero, one, and larger amount |
| `RTL` | Rotate by zero, one, and larger amount |
| `NOT` | Invert all bits |
| `MLT` | Basic multiply and low-16-bit truncation |
| `JEQ` | Taken and not-taken branches |
| `JNE` | Taken and not-taken branches |
| `JMP` | Unconditional branch |
| `NOP` | No architectural state change besides `pc` |
| `MVV` | Copy source register to destination register |
| `MVI` | Load immediate into register |
| `MVF` | Load data memory into register |
| `MVT` | Store register into data memory |
| `MSI` | Store immediate into data memory |

## Harness Requirements

The harness should support:

- Loading an instruction memory image
- Clocking the core for a bounded number of cycles
- Reading selected registers and memory locations through simulation hierarchy
- Reporting failures in a machine-readable format
