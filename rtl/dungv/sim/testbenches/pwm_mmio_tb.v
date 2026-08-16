`default_nettype none
`include "oasis_defs.vh"

module pwm_mmio_tb;
    reg clk;
    reg reset;
    reg valid;
    reg write;
    reg [`OASIS_DATA_ADDR_WIDTH-1:0] addr;
    reg [`OASIS_XLEN-1:0] wdata;
    wire [`OASIS_XLEN-1:0] rdata;
    wire ready;
    wire error;
    wire [2:0] pwm_out;
    integer red_high;
    integer green_high;
    integer blue_high;
    integer cycle;

    pwm_mmio dut(
        .clk(clk),
        .reset(reset),
        .valid(valid),
        .write(write),
        .addr(addr),
        .wdata(wdata),
        .rdata(rdata),
        .ready(ready),
        .error(error),
        .pwm_out(pwm_out)
    );

    always #5 clk = ~clk;

    task bus_write;
        input [`OASIS_DATA_ADDR_WIDTH-1:0] write_addr;
        input [`OASIS_XLEN-1:0] write_data;
        begin
            @(negedge clk);
            valid = 1'b1;
            write = 1'b1;
            addr = write_addr;
            wdata = write_data;
            #1;
            if (!ready || error) begin
                $display("FAIL bus_write addr=%03x", write_addr);
                $finish;
            end
            @(posedge clk);
            #1;
            valid = 1'b0;
            write = 1'b0;
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        valid = 1'b0;
        write = 1'b0;
        addr = 11'h000;
        wdata = 16'h0000;
        red_high = 0;
        green_high = 0;
        blue_high = 0;
        #12;
        reset = 1'b0;

        bus_write(11'h011, 16'h0040);
        bus_write(11'h012, 16'h0080);
        bus_write(11'h013, 16'h00ff);
        if (pwm_out !== 3'b000) begin
            $display("FAIL shadow_write_changed_outputs");
            $finish;
        end

        bus_write(11'h014, 16'h0001);
        bus_write(11'h010, 16'h0001);

        for (cycle = 0; cycle < 256; cycle = cycle + 1) begin
            @(posedge clk);
            #1;
            if (pwm_out[0]) red_high = red_high + 1;
            if (pwm_out[1]) green_high = green_high + 1;
            if (pwm_out[2]) blue_high = blue_high + 1;
        end

        if (red_high != 64 || green_high != 128 || blue_high != 255) begin
            $display("FAIL duty_counts red=%0d green=%0d blue=%0d",
                     red_high, green_high, blue_high);
            $finish;
        end

        valid = 1'b1;
        write = 1'b0;
        addr = 11'h014;
        #1;
        if (!ready || !error) begin
            $display("FAIL commit_read_error");
            $finish;
        end

        $display("PASS pwm_mmio_tb");
        $finish;
    end
endmodule
