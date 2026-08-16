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
| `gpio_mmio` | Register access, pin state, invalid writes |
| `pwm_mmio` | Shadow/commit behavior and exact duty counts |
| `uart_mmio` | TX/RX loopback and blocking behavior |
| `i2c_master_mmio` | START, ACK, byte write/read, STOP, command timing |

These belong under `tests/rtl/` or `rtl/dungv/sim/testbenches/`.

Current smoke tests live in `rtl/dungv/sim/testbenches/` and can be run from the
DungV RTL directory when `iverilog` and `vvp` are installed:

```sh
cd rtl/dungv
make test
```

## 2. ISA Compliance Tests

DungV consumes OASIS compliance programs from the pinned `OASIS/` submodule.
Generate Base-16 v1.0 assembly and instruction-memory images with:

```sh
make compliance
```

The generated files live under `.build/compliance/base16-v1.0/`. Base-16T
programs are excluded until DungV implements class `00` toolchain instructions.

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

## 5. RPGA Hardware Results

Hardware tests complement simulation by exercising the FPGA I/O primitives,
board routing, pull-ups, and RP2040 host software. The current verified set is:

- GPIO output transitions on the routed RPGA pins.
- Three-channel PWM rainbow output on the dedicated RGB LED driver.
- Repeated UART echo at 115200 baud.
- I2C CHIP_ID read of `0xC2` from a BMA530 at 7-bit address `0x18`.

The I2C result also validates open-drain release, external pull-ups, repeated
START, ACK/NACK sampling, and a CPU-visible blocking read.
