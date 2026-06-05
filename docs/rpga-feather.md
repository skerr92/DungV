# RPGA Feather Bring-Up

DungV can run on an RPGA Feather-style iCE5LP4K board using the OASIS SPI
programming path.

## FPGA Pins

The RPGA wrapper in `rtl/dungv/board/top.v` exposes:

| Signal | Direction | Meaning |
| ------ | --------- | ------- |
| `clk` | output | DungV serial debug clock |
| `enable` | input | Active-high DungV enable; low holds the core/programmer in reset |
| `data` | input | Reserved RPGA sideband control input |
| `data_out` | output | DungV serial debug data |
| `SPI_SS` | input | OASIS programming SPI chip select |
| `SPI_SCK` | input | OASIS programming SPI clock |
| `SPI_MOSI` | input | OASIS programming SPI data from RP2040 to FPGA |
| `SPI_MISO` | output | OASIS programming SPI data from FPGA to RP2040 |
| `STATUS_ALU` | output | High while an ALU instruction is in the execute phase |
| `STATUS_OP` | output | High while a non-ALU, non-memory instruction is in execute |
| `STATUS_MEM` | output | High while a memory instruction is in execute |
| `STATUS_RUN` | output | High when the core is out of reset and not halted |
| `HEARTBEAT` | output | Free-running FPGA heartbeat |

The current `common/io.pcf` maps those logical names to available RPGA pins.
Adjust that file to match the exact pins you have wired to the RP2040 or to
headers.

## Build

Build the FPGA image with oss-cad-suite on `PATH`:

```sh
cd rtl/dungv
PATH=/path/to/oss-cad-suite/bin:$PATH make build
```

This produces `rtl/dungv/top.bin`.

Generate the OASIS program image:

```sh
make examples
```

This produces `.build/examples/v0_1_full_sweep.spi16`.

## CIRCUITPY Files

Copy these files to the RPGA Feather CIRCUITPY drive:

| Source | CIRCUITPY destination |
| ------ | --------------------- |
| `circuitpython/code.py` | `/code.py` |
| `rtl/dungv/top.bin` | `/top.bin` |
| `.build/examples/v0_1_full_sweep.spi16` | `/v0_1_full_sweep.spi16` |

`code.py` first attempts to configure the FPGA through an installed
`icepython` module. It then streams the `.spi16` OASIS programming frames over
SPI and reads the serial debug stream from `clk`/`data_out`.

## Serial Debug Stream

DungV drives a simple synchronous serial stream on the sideband pins:

| Signal | RPGA pin in `common/io.pcf` | CircuitPython pin |
| ------ | --------------------------- | ----------------- |
| `clk` | FPGA pin 2 | `board.F2` |
| `data_out` | FPGA pin 6 | `board.F6` |

Data changes while `clk` is low and is sampled by `code.py` on rising edges.
Each four-byte group is:

| Byte | Meaning |
| ---- | ------- |
| `0` | Sync byte, currently `0xa5` |
| `1` | Program counter low byte |
| `2` | `debug_out[15:8]` |
| `3` | `debug_out[7:0]` |

The CircuitPython reader prints one four-byte group per line and then clears
the local buffer for the next group.

`STATUS_ALU`, `STATUS_OP`, and `STATUS_MEM` are execute-phase pulses at the
FPGA clock rate. They are useful on a logic analyzer or with LED/pulse-stretch
hardware. CircuitPython polling should reliably show `STATUS_RUN`, but may miss
individual instruction-class pulses.

If your CircuitPython board exposes different pin names, edit the pin selection
near the top of `circuitpython/code.py` and keep `common/io.pcf` aligned with
that wiring.
