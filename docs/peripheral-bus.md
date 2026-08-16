# DungV Peripheral Bus

DungV maps OASIS v1.0 `io:[addr11]` operations onto a synchronous request and
response bus. Ordinary memory never reaches this bus.

## Signals

| Signal | Direction from core | Meaning |
| ------ | ------------------- | ------- |
| `mmio_valid` | Output | A request is active and remains stable until completion |
| `mmio_write` | Output | `1` for `MVT`/`MSI`, `0` for `MVF` |
| `mmio_addr[10:0]` | Output | MMIO word address |
| `mmio_wdata[15:0]` | Output | Store data |
| `mmio_rdata[15:0]` | Input | Load result |
| `mmio_ready` | Input | Completes the active request |
| `mmio_error` | Input | Completion failed; meaningful with `mmio_ready` |

The core holds request signals stable and does not retire the MMIO instruction
while `mmio_ready` is low. A successful `MVF` writes `mmio_rdata` to its
destination register. A failed Base-16 operation retires without a register
write; the future OASIS-16P system block will convert `mmio_error` into the
precise load/store access-fault cause.

## Initial GPIO Peripheral

`rtl/dungv/peripherals/gpio_mmio.v` is the first bus target:

| Address | Register | Access | Reset | Meaning |
| ------- | -------- | ------ | ----- | ------- |
| `0x000` | `GPIO_OUT` | Read/write | `0x0000` | Low two bits drive routed board GPIO outputs |
| `0x001` | `GPIO_IN` | Read-only | N/A | Low two bits report sampled inputs |

The RPGA wrapper connects `GPIO_IN[0]` to sideband `data`/F4; input bit 1 reads
zero. Its GPIO outputs are currently unpinned because I2C owns F13/F20. Writes
to `GPIO_IN` complete with `mmio_error` asserted.

## RGB PWM Peripheral

`rtl/dungv/peripherals/pwm_mmio.v` provides three 8-bit channels. At the 12 MHz
core clock, its 256-count period produces a 46.875 kHz PWM carrier.

| Address | Register | Access | Reset | Meaning |
| ------- | -------- | ------ | ----- | ------- |
| `0x010` | `PWM_CONTROL` | Read/write | `0x0000` | Bit 0 enables all channels |
| `0x011` | `PWM_RED` | Read/write | `0x0000` | Red shadow duty in bits 7:0 |
| `0x012` | `PWM_GREEN` | Read/write | `0x0000` | Green shadow duty in bits 7:0 |
| `0x013` | `PWM_BLUE` | Read/write | `0x0000` | Blue shadow duty in bits 7:0 |
| `0x014` | `PWM_COMMIT` | Write-only | N/A | Atomically copies all shadows to active duties |

The board wrapper feeds the PWM outputs into the split
`SB_LED_DRV_CUR`/`SB_RGB_DRV` block. Shadow registers let software prepare a
complete color before committing it without intermediate color tearing.
Addresses outside the GPIO and PWM windows complete with `mmio_error`.

## UART Peripheral

`rtl/dungv/peripherals/uart_mmio.v` implements 115200-baud 8-N-1 by default.
Blocking DATA accesses use normal MMIO backpressure: a read waits for a byte and
a write waits for transmitter capacity.

| Address | Register | Access | Reset | Meaning |
| ------- | -------- | ------ | ----- | ------- |
| `0x020` | `UART_DATA` | Read/write | N/A | RX byte on read; TX byte on write |
| `0x021` | `UART_STATUS` | Read/W1C | `0x0004` | RX valid, overrun, TX ready, frame error |
| `0x022` | `UART_DIVISOR` | Read/write | `104` | Core clocks per serial bit |

Status bits are `RX_VALID=0`, `RX_OVERRUN=1`, `TX_READY=2`, and
`FRAME_ERROR=3`. Writing ones to bits 1 or 3 clears those sticky errors.

The UART remains in the RPGA build's MMIO map, but its RX is tied idle and TX is
unpinned while F13/F20 are assigned to I2C.

## I2C Master Peripheral

`rtl/dungv/peripherals/i2c_master_mmio.v` is a single-master, open-drain byte
engine. Software composes register transactions from blocking commands.

| Address | Register | Access | Reset | Meaning |
| ------- | -------- | ------ | ----- | ------- |
| `0x030` | `I2C_COMMAND` | Read/write | idle | START=bit 0, STOP=1, WRITE=2, READ=3, READ_NACK=4 |
| `0x031` | `I2C_TXDATA` | Read/write | `0x00` | Byte transmitted by WRITE |
| `0x032` | `I2C_RXDATA` | Read-only | `0x00` | Most recently received byte |
| `0x033` | `I2C_STATUS` | Read/W1C | idle | BUSY=0, NACK=1, sampled SCL=2, SDA=3 |
| `0x034` | `I2C_DIVISOR` | Read/write | `80` | Clocks per engine phase; about 50 kHz at 12 MHz |

All accesses stall behind an active command, so reading RXDATA immediately
after issuing READ returns the completed byte. FPGA F13 is SCL and F20 is SDA;
both require pull-ups (normally supplied by the sensor breakout).

This interface is hardware-verified against a BMA530 at 7-bit address `0x18`.
The CPU performed the required initial interface-selection read and then read
CHIP_ID register `0x00` as `0xC2`. The command engine retains its full phase
interval between MMIO commands so back-to-back instructions cannot shorten the
I2C low or bus-free timing.
