`default_nettype none
`include "oasis_defs.vh"

module uart_mmio_tb;
    reg clk;
    reg reset;
    reg valid;
    reg write;
    reg [`OASIS_DATA_ADDR_WIDTH-1:0] addr;
    reg [`OASIS_XLEN-1:0] wdata;
    wire [`OASIS_XLEN-1:0] rdata;
    wire ready;
    wire error;
    wire uart_tx;
    integer timeout;

    uart_mmio #(.RESET_DIVISOR(16'd8)) dut(
        .clk(clk), .reset(reset), .valid(valid), .write(write), .addr(addr),
        .wdata(wdata), .rdata(rdata), .ready(ready), .error(error),
        .uart_rx(uart_tx), .uart_tx(uart_tx)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; reset = 1; valid = 0; write = 0; addr = 0; wdata = 0;
        #20; reset = 0;

        @(negedge clk);
        valid = 1; write = 1; addr = 11'h020; wdata = 16'h00a5;
        #1;
        if (!ready || error) begin $display("FAIL tx_accept"); $finish; end
        @(posedge clk); #1; valid = 0; write = 0;

        timeout = 0;
        while (!dut.rx_valid && timeout < 200) begin
            @(posedge clk); timeout = timeout + 1;
        end
        if (!dut.rx_valid || dut.rx_data != 8'ha5 || dut.frame_error) begin
            $display("FAIL loopback data=%02x frame_error=%b", dut.rx_data, dut.frame_error);
            $finish;
        end

        @(negedge clk);
        valid = 1; write = 0; addr = 11'h020; #1;
        if (!ready || rdata != 16'h00a5) begin $display("FAIL rx_read"); $finish; end
        @(posedge clk); #1; valid = 0;
        if (dut.rx_valid) begin $display("FAIL rx_clear"); $finish; end

        $display("PASS uart_mmio_tb");
        $finish;
    end
endmodule
