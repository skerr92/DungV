# DungV Implementation Notes

DungV is a minimal Verilog implementation of OASIS Base-16 v0.1. The active ISA
tooling and compliance inputs come from the pinned `OASIS/` submodule, while
the local spec snapshot remains useful historical context.

## RTL Layout

| File | Role |
| ---- | ---- |
| `rtl/dungv/board/top.v` | RPGA Feather iCE5LP4K board wrapper |
| `rtl/dungv/core/oasis_core.v` | Core execution state and instruction dispatch |
| `rtl/dungv/decode/instr_decode.v` | Combinational instruction decoder |
| `rtl/dungv/execute/alu.v` | Combinational 16-bit ALU |
| `rtl/dungv/memory/instr_mem.v` | 256-entry instruction memory |
| `rtl/dungv/memory/data_mem.v` | 512-entry data memory |
| `rtl/dungv/programming/hard_spi_programmer.v` | OASIS programming access port over iCE40 hard SPI |
| `rtl/dungv/programming/spi_programmer.v` | Soft-SPI programming reference implementation |
| `rtl/dungv/programming/serial_debug_out.v` | Sideband serial debug stream |
| `rtl/dungv/registers/register_file.v` | 64-entry register file |
| `rtl/dungv/include/oasis_defs.vh` | Width, class, opcode, and memory constants |

## Execution Model

The current core is intentionally simple:

- Instructions are fetched from an asynchronous instruction memory.
- Decode and writeback selection are combinational.
- Register and data-memory reads are synchronous so yosys can map them to
  FPGA-friendly memory resources.
- The core uses a two-phase fetch/execute cadence: one clock captures decoded
  operands and read addresses, and the next clock executes the instruction.
- Architectural state updates during the execute phase.
- `CONTROL.HALT` from the SPI programming port pauses core state updates.
- The program counter increments by one for non-jump instructions.
- Jump instructions replace the next program counter value with the 8-bit target.
- Data memory writes occur on the rising clock edge during execute.

This keeps DungV small enough for the original iCE5LP4K target while preserving
a simple teaching-core structure. A future pipelined core should stay compliant
with the OASIS version pinned by DungV.

## Reset

Reset drives `pc` and `debug_out` to zero. Register and data-memory contents are
initialized to zero in RTL for simulation/synthesis convenience, but they are not
cleared by reset in the FPGA datapath. Whether these reset values are
architectural should be decided in the OASIS ISA repository.

## Debug Output

`debug_out` reports the latest value written or stored by most instructions. It
is not part of the OASIS ISA; it exists so the FPGA wrapper can expose useful
activity on output pins.

## Compatibility

See [oasis-compatibility.md](oasis-compatibility.md) for DungV's current
instruction implementation status against the pinned OASIS baseline.
