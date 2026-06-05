`default_nettype none
`include "oasis_defs.vh"

module serial_debug_out(
    input wire clk,
    input wire reset,
    input wire [`OASIS_PC_WIDTH-1:0] pc,
    input wire [`OASIS_XLEN-1:0] out_value,
    output reg debug_clk,
    output reg debug_data
);

    localparam [7:0] SYNC_BYTE = 8'ha5;
    localparam integer DIVIDER_WIDTH = 14;

    reg [DIVIDER_WIDTH-1:0] divider;
    reg [4:0] bit_index;
    reg [31:0] frame;

    wire tick = divider == {DIVIDER_WIDTH{1'b0}};

    initial begin
        divider = {DIVIDER_WIDTH{1'b0}};
        bit_index = 5'd0;
        frame = 32'h00000000;
        debug_clk = 1'b0;
        debug_data = 1'b0;
    end

    always @(posedge clk) begin
        if (reset) begin
            divider <= {DIVIDER_WIDTH{1'b0}};
            bit_index <= 5'd0;
            frame <= 32'h00000000;
            debug_clk <= 1'b0;
            debug_data <= 1'b0;
        end else begin
            divider <= divider + 1'b1;

            if (tick) begin
                debug_clk <= !debug_clk;

                if (debug_clk) begin
                    if (bit_index == 5'd0) begin
                        frame <= {
                            SYNC_BYTE,
                            pc[7:0],
                            out_value
                        };
                        debug_data <= SYNC_BYTE[7];
                    end else begin
                        debug_data <= frame[31 - bit_index];
                    end

                    bit_index <= bit_index + 1'b1;
                end
            end
        end
    end

endmodule
