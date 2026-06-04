`default_nettype none
`include "oasis_defs.vh"

module alu(
    input wire [`OASIS_XLEN-1:0] operand_a,
    input wire [`OASIS_XLEN-1:0] operand_b,
    input wire [3:0] oper,
    output reg [`OASIS_XLEN-1:0] result
);

    wire [3:0] shift_amount = operand_b[3:0];

    always @(*) begin
        case (oper)
            `OASIS_ALU_ADD: result = operand_a + operand_b;
            `OASIS_ALU_SUB: result = operand_a - operand_b;
            `OASIS_ALU_AND: result = operand_a & operand_b;
            `OASIS_ALU_OOR: result = operand_a | operand_b;
            `OASIS_ALU_XOR: result = operand_a ^ operand_b;
            `OASIS_ALU_SHR: result = operand_a >> shift_amount;
            `OASIS_ALU_SHL: result = operand_a << shift_amount;
            `OASIS_ALU_RTR: begin
                if (shift_amount == 4'h0) begin
                    result = operand_a;
                end else begin
                    result = (operand_a >> shift_amount) |
                             (operand_a << (`OASIS_XLEN - shift_amount));
                end
            end

            `OASIS_ALU_RTL: begin
                if (shift_amount == 4'h0) begin
                    result = operand_a;
                end else begin
                    result = (operand_a << shift_amount) |
                             (operand_a >> (`OASIS_XLEN - shift_amount));
                end
            end

            `OASIS_ALU_NOT: result = ~operand_a;
            `OASIS_ALU_MLT: result = operand_a * operand_b;
            default: result = {`OASIS_XLEN{1'b0}};
        endcase
    end

endmodule
