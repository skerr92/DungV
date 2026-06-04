# OASIS v0.1

OASIS is a small, readable, implementation-friendly ISA for learning, FPGA soft
cores, microcontrollers, and custom chip experiments. This document is the v0.1
ISA contract. DungV is the minimal reference implementation.

## Architectural State

| Item | Definition |
| ---- | ---------- |
| Data width | 16 bits |
| Instruction width | 32 bits |
| Registers | 64 general purpose registers, `r0` through `r63` |
| `r0` behavior | `r0` is a normal writable register |
| Program counter | 8-bit instruction index |
| Program memory | 256 instructions |
| Data memory | 512 words, 16 bits per word |
| Addressing unit | Instruction memory is addressed by instruction index; data memory is addressed by 16-bit word index |
| Endianness | Not architecturally visible in v0.1 because accesses are word-sized |
| Status flags | None |
| Exceptions | None |
| Reset state | `pc = 0`; register and data memory reset values are implementation-defined |

## Encoding Rules

OASIS instructions are 32 bits wide. Multi-bit fields are encoded most-significant
bit first: the `class` field occupies bits `[31:30]`.

Reserved fields must be encoded as zero. Reserved classes and operations execute
as no-ops in DungV.

## Instruction Classes

| Class | Group |
| ----- | ----- |
| `00` | Reserved |
| `01` | ALU and jump operations |
| `10` | Register move operations |
| `11` | Memory operations |

## ALU And Jump Encoding

| Bits | Field |
| ---- | ----- |
| `[31:30]` | `01` class |
| `[29:26]` | 4-bit opcode |
| `[25:20]` | destination/source register `ra` |
| `[19:14]` | source register `rb` or 6-bit shift/rotate amount |
| `[13:6]` | 8-bit jump target for `JEQ`, `JNE`, and `JMP` |
| `[5:0]` | reserved |

| Opcode | Mnemonic | Syntax | Operation |
| ------ | -------- | ------ | --------- |
| `0001` | `ADD` | `ADD ra, rb` | `ra = ra + rb` |
| `0010` | `SUB` | `SUB ra, rb` | `ra = ra - rb` |
| `0011` | `AND` | `AND ra, rb` | `ra = ra & rb` |
| `0100` | `OOR` | `OOR ra, rb` | `ra = ra | rb` |
| `0101` | `XOR` | `XOR ra, rb` | `ra = ra ^ rb` |
| `0110` | `SHR` | `SHR ra, imm6` | `ra = ra >> imm6` |
| `0111` | `SHL` | `SHL ra, imm6` | `ra = ra << imm6` |
| `1000` | `RTR` | `RTR ra, imm6` | `ra = rotate_right(ra, imm6)` |
| `1001` | `RTL` | `RTL ra, imm6` | `ra = rotate_left(ra, imm6)` |
| `1010` | `NOT` | `NOT ra` | `ra = ~ra` |
| `1011` | `MLT` | `MLT ra, rb` | `ra = ra * rb` |
| `1100` | `JEQ` | `JEQ ra, rb, target8` | `pc = target8` when `ra == rb` |
| `1101` | `JNE` | `JNE ra, rb, target8` | `pc = target8` when `ra != rb` |
| `1110` | `JMP` | `JMP target8` | `pc = target8` |
| `1111` | `NOP` | `NOP` | No operation |

Arithmetic wraps modulo 16 bits. `MLT` keeps the low 16 bits of the product.
Shift and rotate amounts are reduced to the low 4 bits in DungV because the data
path is 16 bits wide.

## Register Operation Encoding

| Bits | Field |
| ---- | ----- |
| `[31:30]` | `10` class |
| `[29:28]` | 2-bit opcode |
| `[27:22]` | destination register `ra` |
| `[21:16]` | source register `rb` for `MVV` |
| `[15:0]` | immediate value for `MVI` |

| Opcode | Mnemonic | Syntax | Operation |
| ------ | -------- | ------ | --------- |
| `10` | `MVV` | `MVV ra, rb` | `ra = rb` |
| `11` | `MVI` | `MVI ra, imm16` | `ra = imm16` |

Opcodes `00` and `01` are reserved.

## Memory Operation Encoding

Format for `MVF` and `MVT`:

| Bits | Field |
| ---- | ----- |
| `[31:30]` | `11` class |
| `[29:28]` | 2-bit opcode |
| `[27:22]` | register `ra` |
| `[21:13]` | 9-bit memory address |
| `[12:0]` | reserved |

Format for `MSI`:

| Bits | Field |
| ---- | ----- |
| `[31:30]` | `11` class |
| `[29:28]` | `11` opcode |
| `[27:19]` | 9-bit memory address |
| `[18:16]` | reserved |
| `[15:0]` | immediate value |

| Opcode | Mnemonic | Syntax | Operation |
| ------ | -------- | ------ | --------- |
| `01` | `MVF` | `MVF ra, [addr9]` | `ra = memory[addr9]` |
| `10` | `MVT` | `MVT ra, [addr9]` | `memory[addr9] = ra` |
| `11` | `MSI` | `MSI [addr9], imm16` | `memory[addr9] = imm16` |

Opcode `00` is reserved.

## Assembler Syntax

OASIS assembly is line-oriented. Registers are written as `r0` through `r63`.
Immediates may be decimal, binary with `0b`, or hexadecimal with `0x`. Labels
resolve to 8-bit instruction indexes for jumps.

Example:

```asm
MVI r1, 10
MVI r2, 20
ADD r1, r2
MVT r1, [0x001]
JMP done
done:
NOP
```

See [instructions/README.md](instructions/README.md) for the per-instruction
reference pages.

## Calling Convention

No calling convention is defined in v0.1.

## Extension Roadmap

Future OASIS versions may define:

- A hardwired zero register or named register aliases
- Byte addressing and explicit endianness
- Status flags or compare instructions
- Load/store through register addresses
- A subroutine call and return convention
- Privileged execution modes
