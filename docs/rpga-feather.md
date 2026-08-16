# RPGA Feather Bring-Up

DungV can run on an RPGA Feather-style iCE5LP4K board using the OASIS SPI
programming path.

## FPGA Pins

The RPGA wrapper in `rtl/dungv/board/top.v` exposes:

| Signal | Direction | Meaning |
| ------ | --------- | ------- |
| `clk` | output | DungV serial debug clock on FPGA F2 |
| `enable` | input | RP2040-controlled reset/programming gate on FPGA F3 |
| `data` | input | Reserved RPGA sideband control input |
| `data_out` | output | DungV serial debug data on FPGA F6 |
| `I2C_SCL` | open drain | FPGA F13 drives/samples sensor SCL |
| `I2C_SDA` | open drain | FPGA F20 drives/samples sensor SDA |
| `SPI_SS` | input | OASIS programming SPI chip select |
| `SPI_SCK` | input | OASIS programming SPI clock |
| `SPI_MOSI` | input | OASIS programming SPI data from RP2040 to FPGA |
| `SPI_MISO` | output | OASIS programming SPI data from FPGA to RP2040 |
| `RGB0` | output | Dedicated FPGA RGB-driver channel on F39; MMIO bit 2 |
| `RGB1` | output | Dedicated FPGA RGB-driver channel on F40; MMIO bit 3 |
| `RGB2` | output | Dedicated FPGA RGB-driver channel on F41; MMIO bit 4 |

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

This produces `.build/examples/bma530_rgb_tilt.spi16` along with the other
example images.

## CIRCUITPY Files

Copy these files to the RPGA Feather CIRCUITPY drive:

| Source | CIRCUITPY destination |
| ------ | --------------------- |
| `circuitpython/code.py` | `/code.py` |
| `rtl/dungv/top.bin` | `/top.bin` |
| `.build/examples/bma530_rgb_tilt.spi16` | `/bma530_rgb_tilt.spi16` |

`code.py` configures the FPGA, streams the BMA530 XYZ-to-RGB program over SPI,
and observes diagnostics through the F2/F6 debug link. The program configures
100 Hz, ±2 g acceleration data, maps absolute X/Y/Z magnitude to red/green/blue
PWM, and reports the mapped triplets. Setup and runtime I2C errors produce a
steady error color plus a specific `0xde01`–`0xde03` diagnostic.

## I2C Wiring

F2/F3/F6 retain the synchronous debug and external reset interface. FPGA F13 is
I2C SCL and F20 is I2C SDA. Both signals are open drain and require pull-ups.

The first peripheral register map is:

| MMIO word | Name | Access | Meaning |
| --------- | ---- | ------ | ------- |
| `io:[0x000]` | `GPIO_OUT` | Read/write | Low two bits drive D3 and D8 |
| `io:[0x001]` | `GPIO_IN` | Read-only | Bit 0 samples the `data`/`F4` sideband input |
| `io:[0x010]` | `PWM_CONTROL` | Read/write | Bit 0 enables RGB PWM |
| `io:[0x011]` | `PWM_RED` | Read/write | Red shadow duty |
| `io:[0x012]` | `PWM_GREEN` | Read/write | Green shadow duty |
| `io:[0x013]` | `PWM_BLUE` | Read/write | Blue shadow duty |
| `io:[0x014]` | `PWM_COMMIT` | Write-only | Applies all three duties atomically |
| `io:[0x020]` | `UART_DATA` | Read/write | Blocking receive/transmit byte |
| `io:[0x021]` | `UART_STATUS` | Read/W1C | RX/TX readiness and sticky errors |
| `io:[0x022]` | `UART_DIVISOR` | Read/write | Core clocks per serial bit; reset 104 |
| `io:[0x030]` | `I2C_COMMAND` | Read/write | START/STOP/WRITE/READ byte command |
| `io:[0x031]` | `I2C_TXDATA` | Read/write | Next transmitted byte |
| `io:[0x032]` | `I2C_RXDATA` | Read-only | Most recently received byte |
| `io:[0x033]` | `I2C_STATUS` | Read/W1C | Busy, NACK, and sampled line state |
| `io:[0x034]` | `I2C_DIVISOR` | Read/write | Reset 80 for approximately 50 kHz |

Writes to `GPIO_IN` and accesses to unmapped addresses complete with a bus
error. Base-16 currently treats that error as a failed operation with no trap;
the optional OASIS-16P integration will translate it into the specified precise
access fault.

If your CircuitPython board exposes different pin names, edit the pin selection
near the top of `circuitpython/code.py` and keep `common/io.pcf` aligned with
that wiring.
