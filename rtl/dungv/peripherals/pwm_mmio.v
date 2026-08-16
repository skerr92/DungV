`default_nettype none
`include "oasis_defs.vh"

// Three-channel, 8-bit PWM peripheral with atomic duty-cycle commit.
//   io:[0x010] CONTROL, bit 0 enables all channels
//   io:[0x011] RED shadow duty
//   io:[0x012] GREEN shadow duty
//   io:[0x013] BLUE shadow duty
//   io:[0x014] COMMIT, any write copies all shadow duties to active duties
module pwm_mmio(
    input wire clk,
    input wire reset,
    input wire valid,
    input wire write,
    input wire [`OASIS_DATA_ADDR_WIDTH-1:0] addr,
    input wire [`OASIS_XLEN-1:0] wdata,
    output reg [`OASIS_XLEN-1:0] rdata,
    output reg ready,
    output reg error,
    output wire [2:0] pwm_out
);

    localparam [`OASIS_DATA_ADDR_WIDTH-1:0] CONTROL_ADDR = 11'h010;
    localparam [`OASIS_DATA_ADDR_WIDTH-1:0] RED_ADDR     = 11'h011;
    localparam [`OASIS_DATA_ADDR_WIDTH-1:0] GREEN_ADDR   = 11'h012;
    localparam [`OASIS_DATA_ADDR_WIDTH-1:0] BLUE_ADDR    = 11'h013;
    localparam [`OASIS_DATA_ADDR_WIDTH-1:0] COMMIT_ADDR  = 11'h014;

    reg enabled;
    reg [7:0] counter;
    reg [7:0] red_shadow;
    reg [7:0] green_shadow;
    reg [7:0] blue_shadow;
    reg [7:0] red_active;
    reg [7:0] green_active;
    reg [7:0] blue_active;

    assign pwm_out[0] = enabled && counter < red_active;
    assign pwm_out[1] = enabled && counter < green_active;
    assign pwm_out[2] = enabled && counter < blue_active;

    always @(*) begin
        rdata = {`OASIS_XLEN{1'b0}};
        ready = valid;
        error = 1'b0;

        if (valid) begin
            case (addr)
                CONTROL_ADDR: rdata[0] = enabled;
                RED_ADDR: rdata[7:0] = red_shadow;
                GREEN_ADDR: rdata[7:0] = green_shadow;
                BLUE_ADDR: rdata[7:0] = blue_shadow;
                COMMIT_ADDR: begin
                    error = !write;
                end
                default: error = 1'b1;
            endcase
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            enabled <= 1'b0;
            counter <= 8'h00;
            red_shadow <= 8'h00;
            green_shadow <= 8'h00;
            blue_shadow <= 8'h00;
            red_active <= 8'h00;
            green_active <= 8'h00;
            blue_active <= 8'h00;
        end else begin
            counter <= counter + 1'b1;

            if (valid && ready && write && !error) begin
                case (addr)
                    CONTROL_ADDR: enabled <= wdata[0];
                    RED_ADDR: red_shadow <= wdata[7:0];
                    GREEN_ADDR: green_shadow <= wdata[7:0];
                    BLUE_ADDR: blue_shadow <= wdata[7:0];
                    COMMIT_ADDR: begin
                        red_active <= red_shadow;
                        green_active <= green_shadow;
                        blue_active <= blue_shadow;
                    end
                endcase
            end
        end
    end

endmodule
