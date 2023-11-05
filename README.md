# Welcome to DungV
An experimental open source CPU with instruction decoder, ALU (add, sub, and, or, not, xor, rotL,rotR), multiplier, and other features

The core is under development still and is the first core to be designed under an experimental ISA called OASIS.

OASIS seeks to make a newer RISC type instruction set which can be more broadly modified or adapted for use on multiple platform specific
applications.

### The Instruction Set ###

The DungV as mentioned is part of the OASIS instruction set which for a 16 bit system, which requires a 32 bit wide instruction.

There are three primary instruction flags which are set to determine the remaining operations and fields filled into the instruction.

### Key Terms ###

| Instruction| Description                 |
|------------|-----------------------------|
| SHR        | Shift Right by 6b value     |
| SHL        | Shift Left by 6b value      |
| RTR        | Rotate Right by 6b value    |
| RTL        | Rotate Left by 6b value     |
| MLT        | Multiply Instruction        |
| Jxx        | Jump instructions with 8 bit PC value |
| MVV        | Move value at reg B to reg A |
| MVI        | Move intermediate into reg A |
| MVF        | Move from memory to reg A |
| MVT        | Move to memory from reg A |
| MSI        | Move to store intermediate in memory |


### Instruction Set List ###

| 00-gpio ops|            |                  |              |               |
| 2 bits     | 1 bit      | 2 bits           | 8 bits       | 8 bits        |
| 00-gpio ops| gpio bank  | gpio reg         | gpio reg val | gpio pin mask |
| 00-gpio ops| 0 - bank 1 | 00 enable reg    | 8b val       | 8b mask       |
| 00-gpio ops| 0 - bank 1 | 01 direction reg | 8b val       | 8b mask       |
| 00-gpio ops| 0 - bank 1 | 10 data reg      | 8b val       | 8b mask       |
| 00-gpio ops| 0 - bank 1 | 11 reg transfer  | 6b val       | 8b mask       |
| 00-gpio ops| 1 - bank 2 | 00 enable reg    | 8b val       | 8b mask       |
| 00-gpio ops| 1 - bank 2 | 01 direction reg | 8b val       | 8b mask       |
| 00-gpio ops| 1 - bank 2 | 10 data reg      | 8b val       | 8b mask       |
| 00-gpio ops| 1 - bank 2 | 11 reg transfer  | 6b val       | 8b mask       |

For GPIO operations, the


| 01-ins ops|---------|---------|---------|---------|---------|---------|
|-----------|---------|---------|---------|---------|---------|---------|
| 2 bits    | 4 bits  | 6 bits  |6 bits   | Intermediate support soon   | 
|-----------|---------|---------|---------|---------|---------|---------|
| flag      | oper    | reg A   | reg B   | intermed| mem op  |use intrm|
|-----------|---------|---------|---------|---------|---------|---------|
| 01-ins ops|0001 ADD | 6b addr | 6b addr |16h'XXXX | 13'bXX  |   0/1   |
| 01-ins ops|0010 SUB | 6b addr | 6b addr |16h'XXXX | 13'bXX  |   0/1   |
| 01-ins ops|0011 AND | 6b addr | 6b addr |16h'XXXX | 13'bXX  |   0/1   |
| 01-ins ops|0100 OOR | 6b addr | 6b addr |16h'XXXX | 13'bXX  |   0/1   |
| 01-ins ops|0101 XOR | 6b addr | 6b addr |16h'XXXX | 13'bXX  |   0/1   |
| 01-ins ops|0110 SHR | 6b addr | 6b val  |16h'XXXX | 13'bXX  |   0/1   |
| 01-ins ops|0111 SHL | 6b addr | 6b val  |16h'XXXX | 13'bXX  |   0/1   |
| 01-ins ops|1000 RTR | 6b addr | 6b val  |16h'XXXX | 13'bXX  |   0/1   |
| 01-ins ops|1001 RTL | 6b addr | 6b val  |16h'XXXX | 13'bXX  |   0/1   |
| 01-ins ops|1010 NOT | 6b addr | 6'hXX   |16h'XXXX | 13'bXX  |   0/1   |
| 01-ins ops|1011 MLT | 6b addr | 6b addr |16h'XXXX | 13'bXX  |   0/1   |
| 01-ins ops|1100 JEQ | 6b addr | 6b addr | 8b val  | 13'bXX  |   0/1   |
| 01-ins ops|1101 JNE | 6b addr | 6b addr | 8b val  | 13'bXX  |   0/1   |
| 01-ins ops|1110 JMP | 6b addr | 6b addr | 8b val  | 13'bXX  |   0/1   |
| 01-ins ops|1111 NOP | 6'hXX   | 6'hXX   |16h'XXXX | 13'bXX  |   0/1   |


| 10-reg ops|---------|---------|---------|---------|---------|
|-----------|---------|---------|---------|---------|---------|
| 2 bits    | 2 bits  | 6 bits  | 6 bits  | 16 bits |         |
|-----------|---------|---------|---------|---------|---------|
| flag      | oper    | reg A   | reg B   | intermed| pad     |
|-----------|---------|---------|---------|---------|---------|
| 10-reg ops|10 MVV   | 6b addr | 6b addr |16h'XXXX |  0 pad  |
| 10-reg ops|11 MVI   | 6b addr | 000000  | 16b val |  0 pad  |



| 11-mem ops|---------|---------|---------|---------|
|-----------|---------|---------|---------|---------|
| 2 bits    | 2 bits  | 6-9 bits| 9 bits  | 16 bits |
|-----------|---------|---------|---------|---------|
| flag      | oper    | reg A   | memaddr | intermed|
|-----------|---------|---------|---------|---------|
| 11-mem ops| 01 MVF  | 6b addr | 9b addr |         |
| 11-mem ops| 10 MVT  | 6b addr | 9b addr |         |
| 11-mem ops| 11 MSI  | 9b addr |         |16b intermed|

