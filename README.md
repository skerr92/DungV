# DungV

DungV is a Verilog implementation of OASIS, the Open Architecture Simplified
Instruction Set. OASIS is the architecture contract; DungV answers how this
specific FPGA-oriented core implements that contract.

This repo consumes OASIS as a pinned submodule so the RTL has a concrete ISA and
tooling baseline to target.

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
| `asm/` | Notes for using the OASIS assembler with DungV |
| `examples/` | Source assembly and C examples for generated program images |
| `tests/` | Compliance and RTL verification scaffolding |
| `docs/` | DungV implementation notes, style, compatibility, and diagrams |
| `common/io.pcf` | FPGA pin constraints |
| `OASIS/` | Pinned OASIS ISA/tooling submodule |

## Examples And Compliance Images

Generate DungV-readable assembly and SPI programming examples:

```sh
make examples
```

This assembles `examples/*.oas` into `.build/examples/*.mem` and emits OASIS
programming scripts as `.build/examples/*.dap16` and
`.build/examples/*.spi16`.

Generate OASIS Base-16 v0.1 compliance program images:

```sh
make compliance
```

This filters the OASIS submodule compliance corpus to
`oasis-base16-v0.1-draft` and emits `.oas` plus `.mem` files under
`.build/compliance/base16-v0.1/`.

C examples require an installed OASIS toolchain:

```sh
OASIS_TOOLCHAIN_PREFIX=/path/to/oasis16 make examples-c
```

The current DungV RTL targets Base-16 v0.1. C output from the toolchain uses the
Base-16T calling-convention instructions, so those examples are useful
toolchain artifacts before they are runnable on this RTL.

See [docs/spi-programming.md](docs/spi-programming.md) for the FPGA programming
interface and [docs/rpga-feather.md](docs/rpga-feather.md) for RPGA Feather
bring-up.

## Building

The `rtl/dungv/Makefile` targets the iCE40 UltraPlus flow:

```sh
cd rtl/dungv
make build
```

The build expects `yosys`, `nextpnr-ice40`, and `icepack` to be installed.
