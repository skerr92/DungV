`default_nettype none
`include "oasis_defs.vh"

// Open-drain, single-master I2C byte engine. Software composes transactions
// from START, WRITE, READ, and STOP commands.
module i2c_master_mmio #(
    parameter [15:0] RESET_DIVISOR = 16'd80
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
    input wire scl_in,
    input wire sda_in,
    output reg scl_drive_low,
    output reg sda_drive_low
);
    localparam [`OASIS_DATA_ADDR_WIDTH-1:0] COMMAND_ADDR = 11'h030;
    localparam [`OASIS_DATA_ADDR_WIDTH-1:0] TXDATA_ADDR  = 11'h031;
    localparam [`OASIS_DATA_ADDR_WIDTH-1:0] RXDATA_ADDR  = 11'h032;
    localparam [`OASIS_DATA_ADDR_WIDTH-1:0] STATUS_ADDR  = 11'h033;
    localparam [`OASIS_DATA_ADDR_WIDTH-1:0] DIV_ADDR     = 11'h034;

    localparam [3:0] ST_IDLE = 0, ST_START_A = 1, ST_START_B = 2,
        ST_STOP_A = 3, ST_STOP_B = 4, ST_STOP_C = 5,
        ST_WRITE_SET = 6, ST_WRITE_HIGH = 7, ST_WRITE_LOW = 8,
        ST_WRITE_ACK_HIGH = 9, ST_WRITE_ACK_LOW = 10,
        ST_READ_HIGH = 11, ST_READ_LOW = 12,
        ST_READ_ACK_HIGH = 13, ST_READ_ACK_LOW = 14, ST_START_C = 15;

    reg [15:0] divisor;
    reg [15:0] tick_count;
    reg [3:0] state;
    reg [7:0] txdata;
    reg [7:0] rxdata;
    reg [2:0] bit_index;
    reg read_nack;
    reg nack_seen;

    wire busy = state != ST_IDLE;
    wire tick = tick_count == 0;

    always @(*) begin
        rdata = {`OASIS_XLEN{1'b0}};
        // Stall every MMIO access while a command is active. In particular,
        // this makes an RXDATA read immediately following READ wait for the
        // sampled byte instead of returning the previous value.
        // A state can return to IDLE on a phase edge while tick_count still
        // holds the required low/bus-free interval. Do not accept the next
        // software command until that interval expires; otherwise back-to-back
        // MMIO instructions can create sub-cycle I2C low times.
        ready = valid && !busy && tick_count == 0;
        error = 1'b0;
        if (valid) begin
            case (addr)
                COMMAND_ADDR: begin
                    rdata[0] = busy;
                end
                TXDATA_ADDR: rdata[7:0] = txdata;
                RXDATA_ADDR: rdata[7:0] = rxdata;
                STATUS_ADDR: begin
                    rdata[0] = busy;
                    rdata[1] = nack_seen;
                    rdata[2] = scl_in;
                    rdata[3] = sda_in;
                end
                DIV_ADDR: rdata = divisor;
                default: error = 1'b1;
            endcase
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            divisor <= RESET_DIVISOR;
            tick_count <= 0;
            state <= ST_IDLE;
            txdata <= 0;
            rxdata <= 0;
            bit_index <= 0;
            read_nack <= 1'b1;
            nack_seen <= 1'b0;
            scl_drive_low <= 1'b0;
            sda_drive_low <= 1'b0;
        end else begin
            if (tick_count != 0) tick_count <= tick_count - 1'b1;

            if (valid && ready && write && !error) begin
                case (addr)
                    TXDATA_ADDR: txdata <= wdata[7:0];
                    STATUS_ADDR: if (wdata[1]) nack_seen <= 1'b0;
                    DIV_ADDR: if (wdata != 0) divisor <= wdata;
                    COMMAND_ADDR: begin
                        tick_count <= divisor - 1'b1;
                        if (wdata[0]) state <= ST_START_A;
                        else if (wdata[1]) state <= ST_STOP_A;
                        else if (wdata[2]) begin
                            state <= ST_WRITE_SET;
                            bit_index <= 3'd7;
                        end else if (wdata[3]) begin
                            state <= ST_READ_HIGH;
                            bit_index <= 3'd7;
                            read_nack <= wdata[4];
                            rxdata <= 0;
                            sda_drive_low <= 1'b0;
                        end
                    end
                endcase
            end

            if (busy && tick) begin
                tick_count <= divisor - 1'b1;
                case (state)
                    ST_START_A: begin scl_drive_low <= 0; sda_drive_low <= 0; state <= ST_START_B; end
                    ST_START_B: begin sda_drive_low <= 1; state <= ST_START_C; end
                    ST_START_C: begin scl_drive_low <= 1; state <= ST_IDLE; end
                    ST_STOP_A: begin scl_drive_low <= 1; sda_drive_low <= 1; state <= ST_STOP_B; end
                    ST_STOP_B: begin scl_drive_low <= 0; state <= ST_STOP_C; end
                    ST_STOP_C: begin sda_drive_low <= 0; state <= ST_IDLE; end
                    ST_WRITE_SET: begin
                        scl_drive_low <= 1;
                        sda_drive_low <= !txdata[bit_index];
                        state <= ST_WRITE_HIGH;
                    end
                    ST_WRITE_HIGH: begin scl_drive_low <= 0; state <= ST_WRITE_LOW; end
                    ST_WRITE_LOW: begin
                        scl_drive_low <= 1;
                        if (state == ST_WRITE_LOW && bit_index != 0) begin
                            bit_index <= bit_index - 1'b1; state <= ST_WRITE_SET;
                        end else begin sda_drive_low <= 0; state <= ST_WRITE_ACK_HIGH; end
                    end
                    ST_WRITE_ACK_HIGH: begin
                        scl_drive_low <= 0;
                        if (sda_in) nack_seen <= 1;
                        state <= ST_WRITE_ACK_LOW;
                    end
                    ST_WRITE_ACK_LOW: begin scl_drive_low <= 1; state <= ST_IDLE; end
                    ST_READ_HIGH: begin scl_drive_low <= 0; state <= ST_READ_LOW; end
                    ST_READ_LOW: begin
                        rxdata[bit_index] <= sda_in;
                        scl_drive_low <= 1;
                        if (bit_index != 0) begin bit_index <= bit_index - 1'b1; state <= ST_READ_HIGH; end
                        else begin sda_drive_low <= !read_nack; state <= ST_READ_ACK_HIGH; end
                    end
                    ST_READ_ACK_HIGH: begin scl_drive_low <= 0; state <= ST_READ_ACK_LOW; end
                    ST_READ_ACK_LOW: begin scl_drive_low <= 1; sda_drive_low <= 0; state <= ST_IDLE; end
                    default: state <= ST_IDLE;
                endcase
            end
        end
    end
endmodule
