`default_nettype none
`include "oasis_defs.vh"

module instr_mem(
    input wire clk,
    input wire [`OASIS_PC_WIDTH-1:0] pc,
    input wire prog_we,
    input wire [`OASIS_PC_WIDTH-1:0] prog_addr,
    input wire [`OASIS_INSTR_WIDTH-1:0] prog_wdata,
    output wire [`OASIS_INSTR_WIDTH-1:0] prog_rdata,
    output wire [`OASIS_INSTR_WIDTH-1:0] instruction
);

    parameter INIT_FILE = "";

    reg [`OASIS_INSTR_WIDTH-1:0] instruction_mem [0:`OASIS_INSTR_COUNT-1];
    integer i;

    initial begin
        for (i = 0; i < `OASIS_INSTR_COUNT; i = i + 1) begin
            instruction_mem[i] = {`OASIS_CLASS_ALU, `OASIS_ALU_NOP, 26'h0000000};
        end

        if (INIT_FILE != "") begin
            $readmemb(INIT_FILE, instruction_mem);
        end
    end

    assign instruction = instruction_mem[pc];
    assign prog_rdata = instruction_mem[prog_addr];

    always @(posedge clk) begin
        if (prog_we) begin
            instruction_mem[prog_addr] <= prog_wdata;
        end
    end

endmodule
