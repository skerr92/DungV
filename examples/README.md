# Examples

This directory holds source examples. Generated images are written to `.build/`
so checked-in examples stay readable and reproducible.

## Assembly Examples

Assembly examples use OASIS Base-16 v1.0 syntax and the subset that the current
DungV RTL implements:

- `add_store.oas` adds two registers and stores the result at data-memory word
  `0x001`.
- `branch_counter.oas` loops until a counter reaches three and stores the result
  at data-memory word `0x002`.
- `mmio_gpio_walk.oas` writes a walking `1` to the two routed GPIO outputs.
- `pwm_rgb_rainbow.oas` computes R→G→B fades on the CPU and atomically commits
  three 8-bit PWM duties to the RGB peripheral.
- `uart_echo.oas` blocks on UART receive and echoes every byte through the CPU.
- `i2c_bma530_id.oas` performs the BMA530's required throwaway first I2C read,
  then continuously polls CHIP_ID `0xC2` and reports the result through
  debug output. Continuous polling keeps activity visible to test equipment.
- `v1_0_full_sweep.oas` exercises the Base-16 v1.0 ALU, memory, branch, and
  loop behavior over most of the 256-word instruction memory.

Generate instruction-memory and SPI programming images with:

```sh
make examples
```

The generated `.mem` files are suitable for the `PROGRAM_FILE` parameter on
`rtl/dungv/core/oasis_core.v`. The generated `.spi16` files can be streamed over
the DungV SPI programming interface described in
[`docs/spi-programming.md`](../docs/spi-programming.md).

## C Examples

`add.c` is a freestanding OASIS toolchain smoke example. Build it with:

```sh
OASIS_TOOLCHAIN_PREFIX=/path/to/oasis16 make examples-c
```

The current DungV RTL does not yet implement the Base-16T class `00`
instructions that GCC emits for calls, stack access, and returns.
