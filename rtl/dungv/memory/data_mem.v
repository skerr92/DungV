`default_nettype none
`include "oasis_defs.vh"

module data_mem(
    input wire clk,
    input wire wr_en,
    input wire [`OASIS_DATA_ADDR_WIDTH-1:0] addr,
    input wire [`OASIS_XLEN-1:0] data_in,
    output wire [`OASIS_XLEN-1:0] data_out
);

    reg [`OASIS_XLEN-1:0] memory [0:`OASIS_DATA_WORDS-1];
    integer i;

    initial begin
        for (i = 0; i < `OASIS_DATA_WORDS; i = i + 1) begin
            memory[i] = {`OASIS_XLEN{1'b0}};
        end
    end

    assign data_out = memory[addr];

    always @(posedge clk) begin
        if (wr_en) begin
            memory[addr] <= data_in;
        end
    end

endmodule
