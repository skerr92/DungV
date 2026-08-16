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
- OASIS v1.0 `{mmio, addr11}` operations with a stalling peripheral bus
- Hardware-verified GPIO, RGB PWM, UART, and open-drain I2C peripherals

See the pinned [`OASIS/`](OASIS/) submodule for the active v1.0 candidate and
[docs/oasis-compatibility.md](docs/oasis-compatibility.md) for implementation
status. The local v0.1 specification is retained only as historical context.

## Repository Layout

| Path | Purpose |
| ---- | ------- |
| `spec/` | Historical local OASIS v0.1 snapshot |
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

Generate OASIS Base-16 v1.0 compliance program images:

```sh
make compliance
```

This filters the OASIS submodule compliance corpus to
`oasis-base16-v1.0` and emits `.oas` plus `.mem` files under
`.build/compliance/base16-v1.0/`.

C examples require an installed OASIS toolchain:

```sh
OASIS_TOOLCHAIN_PREFIX=/path/to/oasis16 make examples-c
```

The current DungV RTL is crossing the Base-16 v1.0 compatibility boundary. C
output uses Base-16T calling-convention instructions, so those examples remain
toolchain artifacts until the class `00` implementation milestone is complete.

See [docs/spi-programming.md](docs/spi-programming.md) for the FPGA programming
interface and [docs/rpga-feather.md](docs/rpga-feather.md) for RPGA Feather
bring-up.

## Verified RPGA Peripherals

The current iCE5LP4K build has been exercised on RPGA hardware:

| Peripheral | MMIO words | Hardware result |
| ---------- | ---------- | --------------- |
| GPIO | `0x000`–`0x001` | Routed output transitions observed from OASIS software |
| RGB PWM | `0x010`–`0x014` | CPU-driven R→G→B rainbow fade observed on the FPGA LED |
| UART | `0x020`–`0x022` | Repeated 115200-baud CPU-mediated echo passed |
| I2C | `0x030`–`0x034` | BMA530 at address `0x18` returned CHIP_ID `0xC2` |

These results verify that Base-16 v1.0 MMIO instructions reach real,
variable-latency peripherals through the DungV request/completion interface.
See [docs/peripheral-bus.md](docs/peripheral-bus.md) for the register contract.

## Building

The `rtl/dungv/Makefile` targets the iCE40 UltraPlus flow:

```sh
cd rtl/dungv
make build
```

The build expects `yosys`, `nextpnr-ice40`, and `icepack` to be installed.
