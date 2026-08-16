`default_nettype none
`include "oasis_defs.vh"

// 8-N-1 UART. DATA reads/writes apply bus backpressure until RX data or TX
// capacity is available. The default 12 MHz / 104 divisor gives 115384 baud.
module uart_mmio #(
    parameter [15:0] RESET_DIVISOR = 16'd104
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
    input wire uart_rx,
    output wire uart_tx
);
    localparam [`OASIS_DATA_ADDR_WIDTH-1:0] DATA_ADDR   = 11'h020;
    localparam [`OASIS_DATA_ADDR_WIDTH-1:0] STATUS_ADDR = 11'h021;
    localparam [`OASIS_DATA_ADDR_WIDTH-1:0] DIV_ADDR    = 11'h022;

    reg [15:0] divisor;
    reg rx_meta;
    reg rx_sync;
    reg rx_busy;
    reg [15:0] rx_count;
    reg [3:0] rx_bit;
    reg [7:0] rx_shift;
    reg [7:0] rx_data;
    reg rx_valid;
    reg rx_overrun;
    reg frame_error;
    reg tx_busy;
    reg [15:0] tx_count;
    reg [3:0] tx_bit;
    reg [9:0] tx_shift;

    assign uart_tx = tx_busy ? tx_shift[0] : 1'b1;

    always @(*) begin
        rdata = {`OASIS_XLEN{1'b0}};
        ready = valid;
        error = 1'b0;
        if (valid) begin
            case (addr)
                DATA_ADDR: begin
                    ready = write ? !tx_busy : rx_valid;
                    rdata[7:0] = rx_data;
                end
                STATUS_ADDR: begin
                    rdata[0] = rx_valid;
                    rdata[1] = rx_overrun;
                    rdata[2] = !tx_busy;
                    rdata[3] = frame_error;
                end
                DIV_ADDR: rdata = divisor;
                default: error = 1'b1;
            endcase
        end
    end

    always @(posedge clk) begin
        rx_meta <= uart_rx;
        rx_sync <= rx_meta;

        if (reset) begin
            divisor <= RESET_DIVISOR;
            rx_meta <= 1'b1;
            rx_sync <= 1'b1;
            rx_busy <= 1'b0;
            rx_count <= 16'h0000;
            rx_bit <= 4'd0;
            rx_shift <= 8'h00;
            rx_data <= 8'h00;
            rx_valid <= 1'b0;
            rx_overrun <= 1'b0;
            frame_error <= 1'b0;
            tx_busy <= 1'b0;
            tx_count <= 16'h0000;
            tx_bit <= 4'd0;
            tx_shift <= 10'h3ff;
        end else begin
            if (valid && ready && !error) begin
                if (addr == DATA_ADDR && write) begin
                    tx_busy <= 1'b1;
                    tx_count <= divisor - 1'b1;
                    tx_bit <= 4'd0;
                    tx_shift <= {1'b1, wdata[7:0], 1'b0};
                end else if (addr == DATA_ADDR && !write) begin
                    rx_valid <= 1'b0;
                end else if (addr == STATUS_ADDR && write) begin
                    if (wdata[1]) rx_overrun <= 1'b0;
                    if (wdata[3]) frame_error <= 1'b0;
                end else if (addr == DIV_ADDR && write && wdata != 0) begin
                    divisor <= wdata;
                end
            end

            if (tx_busy) begin
                if (tx_count == 0) begin
                    tx_count <= divisor - 1'b1;
                    tx_shift <= {1'b1, tx_shift[9:1]};
                    if (tx_bit == 4'd9) begin
                        tx_busy <= 1'b0;
                    end else begin
                        tx_bit <= tx_bit + 1'b1;
                    end
                end else begin
                    tx_count <= tx_count - 1'b1;
                end
            end

            if (!rx_busy) begin
                if (!rx_sync) begin
                    rx_busy <= 1'b1;
                    rx_count <= divisor >> 1;
                    rx_bit <= 4'd0;
                end
            end else if (rx_count == 0) begin
                if (rx_bit == 0) begin
                    if (rx_sync) rx_busy <= 1'b0;
                    else begin
                        rx_bit <= 4'd1;
                        rx_count <= divisor - 1'b1;
                    end
                end else if (rx_bit <= 8) begin
                    rx_shift[rx_bit - 1'b1] <= rx_sync;
                    rx_bit <= rx_bit + 1'b1;
                    rx_count <= divisor - 1'b1;
                end else begin
                    rx_busy <= 1'b0;
                    if (!rx_sync) frame_error <= 1'b1;
                    else begin
                        if (rx_valid) rx_overrun <= 1'b1;
                        rx_data <= rx_shift;
                        rx_valid <= 1'b1;
                    end
                end
            end else begin
                rx_count <= rx_count - 1'b1;
            end
        end
    end
endmodule
