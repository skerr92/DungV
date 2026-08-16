`timescale 1ns/1ps
`default_nettype none

module i2c_master_mmio_tb;
    reg clk = 0;
    reg reset = 1;
    reg valid = 0;
    reg write = 0;
    reg [10:0] addr = 0;
    reg [15:0] wdata = 0;
    wire [15:0] rdata;
    wire ready;
    wire error;
    wire scl_drive_low;
    wire sda_drive_low;
    reg slave_sda_low = 0;
    wire scl = scl_drive_low ? 1'b0 : 1'b1;
    wire sda = (sda_drive_low || slave_sda_low) ? 1'b0 : 1'b1;
    integer failures = 0;

    i2c_master_mmio #(.RESET_DIVISOR(16'd2)) dut(
        .clk(clk), .reset(reset), .valid(valid), .write(write),
        .addr(addr), .wdata(wdata), .rdata(rdata), .ready(ready),
        .error(error), .scl_in(scl), .sda_in(sda),
        .scl_drive_low(scl_drive_low), .sda_drive_low(sda_drive_low)
    );

    always #5 clk = !clk;

    // ACK writes and supply 0xc4 during read data phases.
    always @(*) begin
        slave_sda_low = 0;
        if (dut.state == 4'd9) slave_sda_low = 1;
        if ((dut.state == 4'd11 || dut.state == 4'd12) &&
            (((8'hc4 >> dut.bit_index) & 1'b1) == 0)) slave_sda_low = 1;
    end

    task mmio_write(input [10:0] a, input [15:0] d);
        begin
            @(negedge clk); addr = a; wdata = d; write = 1; valid = 1;
            while (!ready) @(negedge clk);
            @(negedge clk); valid = 0; write = 0;
        end
    endtask

    task wait_idle;
        begin
            while (dut.state != 0) @(negedge clk);
        end
    endtask

    initial begin
        repeat (3) @(negedge clk);
        reset = 0;

        mmio_write(11'h030, 16'h0001); wait_idle();
        if (scl !== 0 || sda !== 0) begin $display("FAIL START"); failures = failures + 1; end

        mmio_write(11'h031, 16'h00a5);
        mmio_write(11'h030, 16'h0004); wait_idle();
        if (dut.nack_seen) begin $display("FAIL write ACK"); failures = failures + 1; end

        mmio_write(11'h030, 16'h0018); wait_idle();
        if (dut.rxdata !== 8'hc4) begin $display("FAIL read: %02x", dut.rxdata); failures = failures + 1; end

        mmio_write(11'h030, 16'h0002); wait_idle();
        if (scl !== 1 || sda !== 1) begin $display("FAIL STOP"); failures = failures + 1; end

        if (failures == 0) $display("PASS i2c_master_mmio_tb");
        else $fatal(1, "%0d failures", failures);
        $finish;
    end
endmodule

`default_nettype wire
