`default_nettype none
`include "oasis_defs.vh"

module gpio_mmio_tb;
    reg clk;
    reg reset;
    reg valid;
    reg write;
    reg [`OASIS_DATA_ADDR_WIDTH-1:0] addr;
    reg [`OASIS_XLEN-1:0] wdata;
    reg [3:0] gpio_in;
    wire [`OASIS_XLEN-1:0] rdata;
    wire ready;
    wire error;
    wire [3:0] gpio_out;

    gpio_mmio dut(
        .clk(clk),
        .reset(reset),
        .valid(valid),
        .write(write),
        .addr(addr),
        .wdata(wdata),
        .rdata(rdata),
        .ready(ready),
        .error(error),
        .gpio_in(gpio_in),
        .gpio_out(gpio_out)
    );

    always #5 clk = ~clk;

    task expect_gpio;
        input expected_ready;
        input expected_error;
        input [`OASIS_XLEN-1:0] expected_rdata;
        input [3:0] expected_gpio_out;
        input [127:0] name;
        begin
            #1;
            if (ready !== expected_ready || error !== expected_error ||
                rdata !== expected_rdata || gpio_out !== expected_gpio_out) begin
                $display("FAIL %0s", name);
                $finish;
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        valid = 1'b0;
        write = 1'b0;
        addr = 11'h000;
        wdata = 16'h0000;
        gpio_in = 4'ha;
        #10;
        reset = 1'b0;
        expect_gpio(1'b0, 1'b0, 16'h0000, 4'h0, "idle_after_reset");

        valid = 1'b1;
        write = 1'b1;
        wdata = 16'h0005;
        expect_gpio(1'b1, 1'b0, 16'h0000, 4'h0, "output_write_request");
        #9;
        write = 1'b0;
        expect_gpio(1'b1, 1'b0, 16'h0005, 4'h5, "output_readback");

        addr = 11'h001;
        expect_gpio(1'b1, 1'b0, 16'h000a, 4'h5, "input_read");
        write = 1'b1;
        expect_gpio(1'b1, 1'b1, 16'h000a, 4'h5, "input_write_error");

        write = 1'b0;
        addr = 11'h002;
        expect_gpio(1'b1, 1'b1, 16'h0000, 4'h5, "unmapped_error");

        $display("PASS gpio_mmio_tb");
        $finish;
    end
endmodule
