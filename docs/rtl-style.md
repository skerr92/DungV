# DungV RTL Style

DungV uses a small Verilog-2005 style intended to stay readable and synthesis
friendly.

## Rules

- Use `default_nettype none` in every RTL file.
- Use `snake_case` for internal signals and module ports.
- Keep every module port width explicit.
- Keep architectural widths and opcodes in `rtl/dungv/include/oasis_defs.vh`.
- Prefer combinational decode, control, and ALU logic in `always @(*)`.
- Keep state updates in `always @(posedge clk)`.
- Put reset handling first in sequential blocks.
- Use nonblocking assignments for sequential logic.
- Use blocking assignments for combinational logic.
- Keep board-specific FPGA logic in `rtl/dungv/board/`.
- Keep implementation logic independent of FPGA pins.

## Current RTL Boundaries

| Directory | Responsibility |
| --------- | -------------- |
| `rtl/dungv/board/` | FPGA wrapper and board integration |
| `rtl/dungv/core/` | Core control, PC, writeback, debug output |
| `rtl/dungv/decode/` | Instruction decode |
| `rtl/dungv/execute/` | ALU and execute-stage logic |
| `rtl/dungv/memory/` | Instruction and data memories |
| `rtl/dungv/registers/` | Register file |
| `rtl/dungv/include/` | Width, class, opcode, and memory constants |

## Future Boundaries

As DungV grows, split additional behavior into:

- `fetch`
- `control_unit`
- `memory_interface`
- `writeback`

Do that only when the extra modules make tests or timing easier to understand.
