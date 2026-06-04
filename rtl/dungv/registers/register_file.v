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
    output wire [`OASIS_XLEN-1:0] rd_data_a,
    output wire [`OASIS_XLEN-1:0] rd_data_b
);

    reg [`OASIS_XLEN-1:0] registers [0:`OASIS_REG_COUNT-1];
    integer i;

    assign rd_data_a = registers[rd_addr_a];
    assign rd_data_b = registers[rd_addr_b];

    initial begin
        for (i = 0; i < `OASIS_REG_COUNT; i = i + 1) begin
            registers[i] = {`OASIS_XLEN{1'b0}};
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < `OASIS_REG_COUNT; i = i + 1) begin
                registers[i] <= {`OASIS_XLEN{1'b0}};
            end
        end else if (wr_en) begin
            registers[wr_addr] <= wr_data;
        end
    end

endmodule
