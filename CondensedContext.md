# CondensedContext

## Context Freshness
Context ID: FRESH-001
Last Verified Commit: 70d4cc79ce45d1877735b125d07a2f969ee1a247
Current HEAD: 70d4cc79ce45d1877735b125d07a2f969ee1a247
Generated: 2026-08-16
Status:
- Ready to commit: OASIS v1.0 Base-16 MMIO and GPIO/PWM/UART/I2C peripherals
  are implemented; BMA530 I2C is confirmed on hardware at address `0x18`.

## Purpose
Durable, compact memory for OASIS ISA integration work in DungV.

## Current Focus
Context ID: ACTIVE-001
Confidence: High; based on the pinned OASIS candidate and its integration guide.
- Commit and push the verified DungV v1.0/MMIO peripheral milestone, then update
  the OASIS documentation with DungV as a verified implementation reference.

## Handoff
Context ID: HANDOFF-001
Confidence: High.
- Last known state: DungV adds a blocking 8-N-1 UART at MMIO `0x020`–`0x022`.
  RP2040 D8 TX reaches FPGA F20 RX; FPGA F13 TX reaches RP2040 D9 RX. F2/F3/F6
  retain debug/reset. The default clock is now 12 MHz for timing margin.
- Next useful step: commit/push DungV, then document the verified implementation
  in OASIS.
- Validation: the I2C byte engine test, all RTL tests, assembly/images, full
  FPGA build, and BMA530 hardware transaction pass.

## Stable Facts
Context ID: FACTS-001
Confidence: High; verified against OASIS commit `251f2a3`.
- OASIS v1.0 direct operands use `{mmio, addr11}`: MVF/MVT encode the fields at
  bits 21 and 20:10; MSI uses bits 27 and 26:16.
- Ordinary memory and MMIO are distinct 2048-word address spaces.
- OASIS-16P is optional and must be reported separately from Base-16 v1.0.
- The core holds MMIO request fields stable and stalls retirement until `ready`.
- MMIO map: `0x000 GPIO_OUT` RW and `0x001 GPIO_IN` RO for two routed bits;
  `0x010` PWM control, `0x011`/`0x012`/`0x013` RGB shadow duties, and `0x014`
  atomic commit; `0x020` UART data, `0x021` status, `0x022` divisor; other
  `0x030` I2C command, `0x031` TX data, `0x032` RX data, `0x033` status,
  `0x034` divisor; other accesses error.

## Decisions
Context ID: DECISIONS-001
Confidence: High; user direction recorded 2026-08-16.
- Treat v1.0 as the compatibility boundary after v0.2 and update DungV to build
  and validate against the latest OASIS candidate.
- Use a valid/write/address/data/ready/error peripheral bus so variable-latency
  targets can be added without changing instruction execution semantics.
- Keep PWM generation in hardware but hue progression in OASIS software; use
  shadow duty registers plus commit so three MMIO writes appear simultaneously.
- UART supersedes routed GPIO on F13/F20: RP2040 D8 is TX into FPGA F20 and D9
  is RX from FPGA F13. F2/F3 remain debug clock/external enable.
- UART echo was verified on hardware for repeated variable-length messages.
- Next board role: FPGA F13 is I2C SCL and F20 is bidirectional open-drain SDA;
  UART remains an MMIO block but becomes unpinned on this RPGA build.
- Bosch BMA530 default 7-bit I2C address is `0x18`; CHIP_ID register `0x00`
  returns `0xC2`. After power-on, the first I2C read intentionally NACKs and
  selects the interface, so software must perform a second read for validation.
- RPGA RGB channels F39/F40/F41 are dedicated low-side driver pins. `top.v`
  uses `SB_LED_DRV_CUR` plus `SB_RGB_DRV`; active-high MMIO bits feed PWM inputs,
  and the primitive implements physical polarity/current drive.
- Reacquire serial debug sync `0xa5` at bit granularity after every printed frame;
  CircuitPython printing can cross byte boundaries in the free-running stream.

## Known Constraints
Context ID: CONSTRAINTS-001
Confidence: High.
- Preserve untracked files inside the OASIS submodule; they predate this work.
- Do not report OASIS-16P conformance until precise bus-error traps exist.

## File Map
Context ID: FILEMAP-001
Confidence: Medium.
- `OASIS/`: authoritative ISA submodule and compliance/tool inputs.
- `rtl/dungv/decode/instr_decode.v`: architectural instruction-field decode.
- `rtl/dungv/include/oasis_defs.vh`: implementation widths and opcode constants.
- `tools/generate_compliance_programs.py`: converts selected OASIS YAML fixtures.
- `docs/oasis-compatibility.md`: DungV conformance boundary and implementation status.
- `examples/*.oas`: v1.0 explicit-memory-syntax assembly fixtures.
- `rtl/dungv/peripherals/gpio_mmio.v`: first MMIO bus target and register map.
- `rtl/dungv/peripherals/pwm_mmio.v`: 46.875 kHz three-channel 8-bit PWM target.
- `rtl/dungv/peripherals/uart_mmio.v`: blocking 115200 8-N-1 UART target.
- `rtl/dungv/peripherals/i2c_master_mmio.v`: blocking open-drain I2C byte engine.
- `examples/uart_echo.oas`: three-instruction CPU-mediated byte echo loop.
- `examples/i2c_bma530_id.oas`: double-read BMA530 CHIP_ID hardware test.
- `examples/pwm_rgb_rainbow.oas`: CPU-driven R→G→B→R fade demonstration.
- `docs/peripheral-bus.md`: MMIO handshake contract.
- `circuitpython/code.py`: RPGA programmer and BMA530 result/debug reader.

## Validation Memory
Context ID: VALIDATION-001
Confidence: Medium.
- `make check` runs upstream OASIS checks, DungV RTL unit tests, and compliance
  image generation.
- `make -C OASIS check` passed on 2026-08-16.
- `make -B examples`, `make compliance`, legacy compliance generation, and
  `git diff --check` passed on 2026-08-16.
- oss-cad-suite provides the local `iverilog`, Yosys, nextpnr, and icepack tools.
- `make -B examples`, `make compliance`, CircuitPython `py_compile`, and
  `git diff --check` passed after the GPIO peripheral update on 2026-08-16.
- Rebuilt the five-bit GPIO walk and passed CircuitPython syntax plus
  `git diff --check` after pin-map/debug-resync correction on 2026-08-16.
- Hardware observation confirmed stable `0xa5` debug synchronization, D3/D8
  MMIO transitions, and RGB activity. Active-low correction plus formatter-safe
  CircuitPython output passed syntax, example assembly, and diff checks.
- Full iCE5LP4K synthesis/place/route/pack passed with the dedicated RGB driver:
  1559/3520 LCs (44%), 14/20 RAMs, 27.83 MHz initial placement and 28.74 MHz
  final maximum versus the required 24 MHz; generated `rtl/dungv/top.bin`.
- RPGA hardware deployment confirmed the expected individual RED, GREEN, BLUE
  sequence from MMIO GPIO bits 2, 3, and 4 on F39, F40, and F41.
- PWM unit test measured exactly 64/128/255 asserted clocks per 256-count period;
  ALU, decode, and GPIO RTL tests also passed.
- PWM FPGA flow uses 1689/3520 LCs (47%), 14/20 RAMs, and passes 24 MHz timing
  with a final 29.32 MHz maximum; `top.bin` was packed successfully.
- UART loopback test passed at an accelerated divisor. The F20/D8 RX and F13/D9
  TX board build uses 1976/3520 LCs (56%), 14/20 RAMs, and passes its 12 MHz
  clock with a final 23.17 MHz maximum; `top.bin` packed successfully.
- I2C unit test passed START, ACKed WRITE, `0xC4` READ, and STOP. The full
  iCE5LP4K synthesis/place/route/pack flow passes 12 MHz timing at 26.31 MHz
  maximum and generated a new `top.bin`.
- A core-level simulation of the assembled BMA530 program confirmed that MMIO
  execution actively pulls both I2C lines low. The test now polls continuously
  because the original two one-shot transactions were easy to miss on a scope.
- Hardware produced traffic but returned failure. Root cause found in the byte
  engine: it returned to IDLE before the final phase timer expired, allowing
  back-to-back MMIO commands to violate inter-byte SCL-low and bus-free timing.
  MMIO readiness now waits for both IDLE and `tick_count == 0`.
- The corrected I2C board image passes place/route at 12 MHz with a 23.87 MHz
  reported maximum frequency and was packed as `rtl/dungv/top.bin`.
- After continued hardware failure, default I2C was slowed from about 100 kHz
  to 50 kHz for additional rise-time margin. The BMA test now reports `0xDExx`
  with the raw received byte and `0xE0ss` with status/NACK/line-state bits.
- Hardware returned `0xC2`, identifying the attached board as BMA530 rather
  than BMA580 and confirming I2C address `0x18`, repeated START, and byte read.

## Changes
| Date | Tags | Change | Files | Commit | Remote |
| --- | --- | --- | --- | --- | --- |
| 2026-08-16 | `[v1.0]` `[integration]` `[decode]` | Pinned rc.1, selected v1.0 compliance, migrated examples, and implemented explicit-space addr11 decode without MMIO/RAM aliasing. | OASIS, build, RTL, tests, examples, docs | Uncommitted | Not confirmed |
| 2026-08-16 | `[v1.0]` `[mmio]` `[gpio]` `[rpga]` | Added a stalling peripheral bus, width-parameterized GPIO target, walking-output program, CircuitPython observer, and bus documentation. | Core, GPIO RTL/test, board/PCF, example, CircuitPython, docs | Uncommitted | Not confirmed |
| 2026-08-16 | `[debug]` `[gpio]` `[rpga]` | Corrected D3/D8 observation, assigned all RGB channels to MMIO, and replaced byte-assumed debug parsing with bit-level sync acquisition. | CircuitPython, board/PCF, GPIO example, docs | Uncommitted | Not confirmed |
| 2026-08-16 | `[gpio]` `[rpga]` `[hardware]` | Hardware feedback confirmed MMIO/debug operation; corrected active-low RGB polarity and CircuitPython binary display compatibility. | Board RTL, CircuitPython, docs | Uncommitted | Not confirmed |
| 2026-08-16 | `[gpio]` `[rpga]` `[synthesis]` | Replaced invalid ordinary/direct RGB drive with the iCE5LP4K split LED primitives; full FPGA flow passed. | Board RTL, RGB docs | Uncommitted | Not confirmed |
| 2026-08-16 | `[gpio]` `[rpga]` `[hardware]` | Deployed dedicated RGB driver and confirmed RED, GREEN, BLUE walking sequence on hardware. | Validation only | Uncommitted | Not confirmed |
| 2026-08-16 | `[pwm]` `[mmio]` `[rgb]` | Added atomic three-channel PWM, CPU rainbow fade, RTL duty test, bus routing/docs, and CircuitPython deployment default. | PWM RTL/test, board, example, CircuitPython, docs | Uncommitted | Not confirmed |
| 2026-08-16 | `[uart]` `[mmio]` `[rpga]` | Added blocking UART, CPU echo, D8/D9 CircuitPython validation, preserved F2/F3 debug/reset, and reduced the core clock to 12 MHz for margin. | UART RTL/test, board/PCF, example, CircuitPython, docs | Uncommitted | Not confirmed |
| 2026-08-16 | `[uart]` `[hardware]` | Confirmed repeated CPU-mediated UART echo on RPGA hardware. | Validation only | Uncommitted | Not confirmed |
| 2026-08-16 | `[i2c]` `[mmio]` `[rpga]` | Added an open-drain byte engine, F13/F20 routing, BMA580 double-read CHIP_ID test, CircuitPython debug validation, RTL test, and docs. | I2C RTL/test, board/PCF, example, CircuitPython, docs | Uncommitted | Not confirmed |
| 2026-08-16 | `[i2c]` `[hardware]` `[bma530]` | Hardware returned CHIP_ID `0xC2` at address `0x18`, confirming the board is BMA530 and validating I2C end to end. | Example, CircuitPython, docs | Uncommitted | Not confirmed |

## Open Threads
Context ID: OPEN-001
Confidence: High.
- Deploy the renamed BMA530 test image and confirm its PASS label.
- Add executable core-level wait-state and error-path tests.
- Implement Base-16T MCP/scratch behavior, then optional OASIS-16P as separate milestones.
