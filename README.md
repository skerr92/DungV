# DungV

DungV is a Verilog implementation of OASIS, the Open Architecture Simplified
Instruction Set. OASIS is the architecture contract; DungV answers how this
specific FPGA-oriented core implements that contract.

This repo carries a local OASIS v0.1 draft so the RTL has something concrete to
target. The long-term plan is for a sister OASIS ISA repository to become the
source of truth, with DungV consuming a pinned version of that spec.

The current DungV RTL implements:

- 32-bit OASIS instructions
- 16-bit register and memory data path
- 64 general purpose registers
- 8-bit program counter
- ALU operations: add, subtract, and, or, xor, shifts, rotates, not, multiply
- Register moves, immediate loads, memory loads, memory stores, and jumps

See [spec/oasis-v0.1.md](spec/oasis-v0.1.md) for the frozen OASIS v0.1
instruction encoding and architectural state.

## Repository Layout

| Path | Purpose |
| ---- | ------- |
| `spec/` | Local OASIS v0.1 draft snapshot used by DungV |
| `rtl/dungv/` | DungV RTL, split by implementation responsibility |
| `rtl/dungv/include/` | Shared OASIS/DungV width and opcode definitions |
| `asm/` | Assembler syntax notes and future DungV assembler tools |
| `examples/` | Example memory images and future sample programs |
| `tests/` | Compliance and RTL verification scaffolding |
| `docs/` | DungV implementation notes, style, compatibility, and diagrams |
| `common/io.pcf` | FPGA pin constraints |

## Building

The `rtl/dungv/Makefile` targets the iCE40 UltraPlus flow:

```sh
cd rtl/dungv
make build
```

The build expects `yosys`, `nextpnr-ice40`, and `icepack` to be installed.
