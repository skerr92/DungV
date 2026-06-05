`default_nettype none
`include "oasis_defs.vh"

module register_file(
    input wire clk,
    input wire reset,
    input wire wr_en,
    input wire [`OASIS_REG_ADDR_WIDTH-1:0] wr_addr,
    input wire [`OASIS_XLEN-1:0] wr_data,
    input wire [`OASIS_REG_ADDR_WIDTH-1:0] rd_addr_a,
    input wire [`OASIS_REG_ADDR_WIDTH-1:0] rd_addr_b,
    output reg [`OASIS_XLEN-1:0] rd_data_a,
    output reg [`OASIS_XLEN-1:0] rd_data_b
);

    reg [`OASIS_XLEN-1:0] registers_a [0:`OASIS_REG_COUNT-1];
    reg [`OASIS_XLEN-1:0] registers_b [0:`OASIS_REG_COUNT-1];
    integer i;

    initial begin
        for (i = 0; i < `OASIS_REG_COUNT; i = i + 1) begin
            registers_a[i] = {`OASIS_XLEN{1'b0}};
            registers_b[i] = {`OASIS_XLEN{1'b0}};
        end
    end

    always @(posedge clk) begin
        rd_data_a <= registers_a[rd_addr_a];
        rd_data_b <= registers_b[rd_addr_b];

        if (!reset && wr_en) begin
            registers_a[wr_addr] <= wr_data;
            registers_b[wr_addr] <= wr_data;
        end
    end

endmodule
