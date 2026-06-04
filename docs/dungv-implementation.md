# DungV Implementation Notes

DungV is a minimal Verilog implementation of the local OASIS v0.1 draft. The
long-term plan is for DungV to consume a pinned version of the sister OASIS ISA
repository instead of carrying the full source-of-truth spec locally.

## RTL Layout

| File | Role |
| ---- | ---- |
| `rtl/dungv/board/top.v` | IcyBlue FPGA board wrapper |
| `rtl/dungv/core/oasis_core.v` | Core execution state and instruction dispatch |
| `rtl/dungv/decode/instr_decode.v` | Combinational instruction decoder |
| `rtl/dungv/execute/alu.v` | Combinational 16-bit ALU |
| `rtl/dungv/memory/instr_mem.v` | 256-entry instruction memory |
| `rtl/dungv/memory/data_mem.v` | 512-entry data memory |
| `rtl/dungv/registers/register_file.v` | 64-entry register file |
| `rtl/dungv/include/oasis_defs.vh` | Width, class, opcode, and memory constants |

## Execution Model

The current core is intentionally simple:

- Instructions are fetched from an asynchronous instruction memory.
- Decode, register reads, writeback selection, and ALU logic are combinational.
- Architectural state updates on the rising clock edge.
- The program counter increments by one for non-jump instructions.
- Jump instructions replace the next program counter value with the 8-bit target.
- Data memory reads are asynchronous and writes occur on the rising clock edge.

This keeps DungV close to a single-cycle teaching core. A future pipelined core
should stay compliant with the OASIS version pinned by DungV.

## Reset

Reset drives `pc`, `debug_out`, and the DungV register file to zero. Data memory
contents are initialized to zero in RTL for simulation/synthesis convenience.
Whether these reset values are architectural should be decided in the OASIS ISA
repository.

## Debug Output

`debug_out` reports the latest value written or stored by most instructions. It
is not part of the OASIS ISA; it exists so the FPGA wrapper can expose useful
activity on output pins.

## Compatibility

See [oasis-compatibility.md](oasis-compatibility.md) for DungV's current
instruction implementation status against the local OASIS v0.1 draft.
