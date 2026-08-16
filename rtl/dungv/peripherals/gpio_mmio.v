`default_nettype none
`include "oasis_defs.vh"

// Width-parameterized OASIS v1.0 MMIO GPIO peripheral.
//   io:[0x000] GPIO_OUT, read/write, low GPIO_WIDTH bits implemented
//   io:[0x001] GPIO_IN,  read-only, low GPIO_WIDTH bits implemented
module gpio_mmio #(
    parameter GPIO_WIDTH = 4
)(
    input wire clk,
    input wire reset,
    input wire valid,
    input wire write,
    input wire [`OASIS_DATA_ADDR_WIDTH-1:0] addr,
    input wire [`OASIS_XLEN-1:0] wdata,
    output reg [`OASIS_XLEN-1:0] rdata,
    output reg ready,
    output reg error,
    input wire [GPIO_WIDTH-1:0] gpio_in,
    output reg [GPIO_WIDTH-1:0] gpio_out
);

    localparam [`OASIS_DATA_ADDR_WIDTH-1:0] GPIO_OUT_ADDR = 11'h000;
    localparam [`OASIS_DATA_ADDR_WIDTH-1:0] GPIO_IN_ADDR  = 11'h001;

    always @(*) begin
        rdata = {`OASIS_XLEN{1'b0}};
        ready = valid;
        error = 1'b0;

        if (valid) begin
            case (addr)
                GPIO_OUT_ADDR: begin
                    rdata[GPIO_WIDTH-1:0] = gpio_out;
                end

                GPIO_IN_ADDR: begin
                    rdata[GPIO_WIDTH-1:0] = gpio_in;
                    error = write;
                end

                default: begin
                    error = 1'b1;
                end
            endcase
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            gpio_out <= {GPIO_WIDTH{1'b0}};
        end else if (valid && ready && write && !error && addr == GPIO_OUT_ADDR) begin
            gpio_out <= wdata[GPIO_WIDTH-1:0];
        end
    end

endmodule
