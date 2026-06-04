// OASIS instruction decoder.
`default_nettype none
`include "oasis_defs.vh"

module instr_decode(
    input wire [`OASIS_INSTR_WIDTH-1:0] instruction,
    output reg [`OASIS_REG_ADDR_WIDTH-1:0] rega,
    output reg [`OASIS_REG_ADDR_WIDTH-1:0] regb,
    output reg [`OASIS_IMM_WIDTH-1:0] intermed,
    output reg [1:0] instr_class,
    output reg [3:0] oper,
    output reg [1:0] mem_op,
    output reg [`OASIS_DATA_ADDR_WIDTH-1:0] mem_addr
);

    always @(*) begin
        instr_class = instruction[31:30];
        oper = 4'h0;
        rega = {`OASIS_REG_ADDR_WIDTH{1'b0}};
        regb = {`OASIS_REG_ADDR_WIDTH{1'b0}};
        intermed = {`OASIS_IMM_WIDTH{1'b0}};
        mem_op = 2'b00;
        mem_addr = {`OASIS_DATA_ADDR_WIDTH{1'b0}};

        case (instr_class)
            `OASIS_CLASS_ALU: begin
                oper = instruction[29:26];
                rega = instruction[25:20];
                regb = instruction[19:14];

                if (instruction[29:26] >= `OASIS_ALU_JEQ &&
                    instruction[29:26] <= `OASIS_ALU_JMP) begin
                    intermed = {8'h00, instruction[13:6]};
                end
            end

            `OASIS_CLASS_REG: begin
                oper = {2'b00, instruction[29:28]};
                rega = instruction[27:22];
                regb = instruction[21:16];
                intermed = instruction[15:0];
            end

            `OASIS_CLASS_MEM: begin
                mem_op = instruction[29:28];

                if (instruction[29:28] == `OASIS_MEM_MVF ||
                    instruction[29:28] == `OASIS_MEM_MVT) begin
                    rega = instruction[27:22];
                    mem_addr = instruction[21:13];
                end else if (instruction[29:28] == `OASIS_MEM_MSI) begin
                    mem_addr = instruction[27:19];
                    intermed = instruction[15:0];
                end
            end
        endcase
    end

endmodule
