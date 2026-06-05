# SPI Programming

DungV exposes the OASIS v0.1 recommended programming access port through an SPI
slave on the board-level `SPI_SS`, `SPI_SCK`, `SPI_MOSI`, and `SPI_MISO` pins.

The SPI bridge implements the transport framing documented in
`OASIS/spec/programming.md`:

| Byte | Field |
| ---- | ----- |
| `0` | Command |
| `1` | Register address high byte |
| `2` | Register address low byte |
| `3` | Data high byte for writes |
| `4` | Data low byte for writes |

Commands:

| Command | Meaning |
| ------- | ------- |
| `0x01` | 16-bit register write |
| `0x02` | 16-bit register read |

For read frames, DungV shifts the selected 16-bit register value on `SPI_MISO`
during bytes `3` and `4`.

## Register Map

DungV implements the OASIS v0.1 programming registers:

| Address | Name | Notes |
| ------- | ---- | ----- |
| `0x0000` | `CONTROL` | `HALT`, `RESET`, `IMEM_WRITE`, `IMEM_READ`, `AUTO_INC` |
| `0x0001` | `STATUS` | Halt/reset status bits |
| `0x0002` | `CORE_ID` | Reads `0xd016` |
| `0x0003` | `OASIS_PROFILE` | Reads `0x0001` for Base-16 v0.1 |
| `0x0004` | `IMEM_ADDR` | Instruction-memory word index |
| `0x0005` | `IMEM_WDATA_LO` | Instruction write data bits `[15:0]` |
| `0x0006` | `IMEM_WDATA_HI` | Instruction write data bits `[31:16]` |
| `0x0007` | `IMEM_RDATA_LO` | Instruction read data bits `[15:0]` |
| `0x0008` | `IMEM_RDATA_HI` | Instruction read data bits `[31:16]` |

DungV also exposes `0x0009` as a non-v0.1 debug convenience register containing
the current program counter in the low bits.

## Generating SPI Images

Run:

```sh
make examples
```

Each `examples/*.oas` program produces:

- `.build/examples/<name>.mem`: `$readmemb` instruction-memory image
- `.build/examples/<name>.dap16`: transport-neutral register-write script
- `.build/examples/<name>.spi16`: one SPI frame per line, encoded as hex

The `.spi16` files can be streamed line by line by a host controller. The first
frame asserts `HALT` and `RESET`, the body writes instruction memory with
`AUTO_INC`, and the final frames release reset/halt so the program starts.

## RTL Path

`rtl/dungv/programming/hard_spi_programmer.v` configures the iCE40 `SB_SPI`
hard block as an SPI slave and translates received bytes into OASIS programming
register accesses. `rtl/dungv/programming/spi_programmer.v` remains in-tree as
a soft-SPI reference implementation, but it is not used by the RPGA Feather
build.

`rtl/dungv/memory/instr_mem.v` provides a writable programming port alongside
the core fetch port. `CONTROL.HALT` pauses core state updates while instruction
memory is being programmed.

## Status Pins

The RPGA Feather wrapper exposes four status outputs:

| Signal | Meaning |
| ------ | ------- |
| `STATUS_ALU` | High while an ALU instruction executes |
| `STATUS_OP` | High while a normal non-ALU, non-memory instruction executes |
| `STATUS_MEM` | High while a memory instruction executes |
| `STATUS_RUN` | High while the core is running |

See [rpga-feather.md](rpga-feather.md) for the board-level bring-up flow.
