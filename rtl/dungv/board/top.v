`default_nettype none
`include "oasis_defs.vh"

// Board wrapper for the IcyBlue FPGA.
module top(
    input wire P4,
    output wire LED_R,
    output wire LED_G,
    output wire LED_B,
    output wire P6,
    output wire P9,
    output wire P10,
    output wire P11,
    output wire P12,
    output wire P13,
    output wire P18,
    output wire P19,
    output wire P20,
    output wire P21,
    output wire P23,
    output wire P25,
    output wire P37,
    output wire P38,
    output wire P42,
    output wire P43
);

    wire clk;
    wire [`OASIS_PC_WIDTH-1:0] pc;
    wire [`OASIS_XLEN-1:0] out;
    reg [31:0] counter;

    assign LED_R = ~counter[25];
    assign LED_G = ~counter[24];
    assign LED_B = ~counter[23];
    assign {P6, P9, P10, P11, P12, P13, P18, P19,
            P20, P21, P23, P25, P37, P38, P42, P43} = out;

    SB_HFOSC SB_HFOSC_inst(
        .CLKHFEN(1'b1),
        .CLKHFPU(1'b1),
        .CLKHF(clk)
    );
    defparam SB_HFOSC_inst.CLKHF_DIV = "0b01";

    oasis_core #(.PROGRAM_FILE("")) oasis_core_inst(
        .clk(clk),
        .reset(P4),
        .pc_value(pc),
        .debug_out(out)
    );

    initial begin
        counter = 32'h00000000;
    end

    always @(posedge clk) begin
        if (P4) begin
            counter <= 32'h00000000;
        end else begin
            counter <= counter + 1'b1;
        end
    end

endmodule
