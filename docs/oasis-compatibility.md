# OASIS Compatibility

DungV targets the OASIS Base-16 v1.0 release candidate pinned in the `OASIS/`
submodule. This is an intentional compatibility break from the earlier v0.1
implementation and the v0.2 toolchain draft. The local `spec/oasis-v0.1.md`
snapshot remains historical context; the submodule is authoritative for ISA
definitions, assembler tooling, and compliance inputs.

## Target

| Item | Value |
| ---- | ----- |
| ISA profile | `oasis-base16-v1.0` |
| OASIS source | `OASIS/` at `251f2a3` (`v1.0.0-rc.1`) |
| Local spec snapshot | `spec/oasis-v0.1.md` |
| DungV status | Base-16 v1.0 MMIO hardware verified; broader integration in progress |
| Data width | 16 bits |
| Instruction width | 32 bits |
| Register count | 64 |
| Program counter | 8-bit instruction index |

## Compliance Inputs

Run the current Base-16 v1.0 compliance-image generation flow with:

```sh
make compliance
```

This filters `OASIS/tests/compliance/` to `oasis-base16-v1.0` and emits
DungV-readable `.oas` and `.mem` files under
`.build/compliance/base16-v1.0/`.

The historical image-generation check remains available as
`make compliance-base16-v0.1`, but it is not the default conformance target.
Base-16T and optional OASIS-16P compliance remain separate until DungV
implements their class `00` instructions and system behavior.

## v1.0 Compatibility Boundary

The first integration milestone decodes `MVF`, `MVT`, and `MSI` using the v1.0
`{mmio, addr11}` fields and expands ordinary data memory to 2048 words. MMIO
operations cannot write or read back ordinary data memory, so identical low
addresses no longer alias.

The second milestone provides a request/completion/error interface and stalls
the core until each MMIO operation completes. A two-bit routed GPIO target uses
`io:[0x000]`/`io:[0x001]`; a three-channel RGB PWM target occupies
`io:[0x010]`–`io:[0x014]`; an 8-N-1 UART uses `io:[0x020]`–`io:[0x022]`.
An open-drain I2C master uses `io:[0x030]`–`io:[0x034]`. Invalid operations
complete with an error.
OASIS-16P precise fault conversion remains open.

## MMIO Verification Status

| Capability | RTL verification | RPGA hardware verification |
| ---------- | ---------------- | -------------------------- |
| Core request/ready stalling | Peripheral unit tests | UART echo and I2C byte transactions complete correctly |
| GPIO | Read/write and error-path test | Routed output transitions observed |
| RGB PWM | Exact 8-bit duty-count test | R→G→B rainbow fade observed |
| UART | Accelerated-divisor loopback test | Repeated 115200-baud echo passed |
| I2C | START, ACKed write, byte read, and STOP test | BMA530 `0x18` returned CHIP_ID `0xC2` |

This establishes DungV as a concrete hardware implementation of the Base-16
v1.0 MMIO encoding and variable-latency transaction semantics. It does not yet
claim Base-16T or OASIS-16P conformance.

## Instruction Status

| Instruction | Specified | Implemented | Tested |
| ----------- | --------- | ----------- | ------ |
| `ADD` | Yes | Yes | Compliance image generated |
| `SUB` | Yes | Yes | Compliance image generated |
| `AND` | Yes | Yes | Compliance image generated |
| `OOR` | Yes | Yes | Compliance image generated |
| `XOR` | Yes | Yes | Compliance image generated |
| `SHR` | Yes | Yes | Compliance image generated |
| `SHL` | Yes | Yes | Compliance image generated |
| `RTR` | Yes | Yes | Compliance image generated |
| `RTL` | Yes | Yes | Compliance image generated |
| `NOT` | Yes | Yes | Compliance image generated |
| `MLT` | Yes | Yes | Compliance image generated |
| `JEQ` | Yes | Yes | Compliance image generated |
| `JNE` | Yes | Yes | Compliance image generated |
| `JMP` | Yes | Yes | Compliance image generated |
| `NOP` | Yes | Yes | Compliance image generated |
| `MVV` | Yes | Yes | Compliance image generated |
| `MVI` | Yes | Yes | Compliance image generated |
| `MVF` | Yes | Yes: RAM and MMIO bus | Decoder/peripheral tests and UART/I2C hardware |
| `MVT` | Yes | Yes: RAM and MMIO bus | Decoder/peripheral tests and GPIO/UART/I2C hardware |
| `MSI` | Yes | Yes: RAM and MMIO bus | Decoder/peripheral tests and GPIO/PWM/I2C hardware |

## Remaining v1.0 Work

- Execute the Base-16 v1.0 compliance expectations, not only generate images.
- Implement `MCP` and the `sap`/`sdata` scratch ABI for Base-16T.
- Implement and report optional OASIS-16P separately from Base-16.

## Implementation-Defined Behavior

- Whether `r0` remains writable or becomes hardwired zero
- Whether reset values for registers and memory are architectural
- Whether invalid or reserved instructions remain no-ops
