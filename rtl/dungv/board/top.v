`default_nettype none
`include "oasis_defs.vh"

// Board wrapper for the RPGA Feather iCE5LP4K.
module top(
    output wire clk,
    input wire enable,
    input wire data,
    output wire data_out,
    input wire SPI_SS,
    input wire SPI_SCK,
    input wire SPI_MOSI,
    output wire SPI_MISO,
    output wire STATUS_ALU,
    output wire STATUS_OP,
    output wire STATUS_MEM,
    output wire STATUS_RUN,
    output wire HEARTBEAT
);

    wire core_clk;
    wire [`OASIS_PC_WIDTH-1:0] pc;
    wire [`OASIS_XLEN-1:0] out;
    wire core_halt;
    wire core_reset;
    wire status_alu;
    wire status_op;
    wire status_mem;
    wire status_run;
    wire imem_prog_we;
    wire [`OASIS_PC_WIDTH-1:0] imem_prog_addr;
    wire [`OASIS_INSTR_WIDTH-1:0] imem_prog_wdata;
    wire [`OASIS_INSTR_WIDTH-1:0] imem_prog_rdata;
    wire debug_clk;
    wire debug_data;
    reg [31:0] counter;

    assign STATUS_ALU = status_alu;
    assign STATUS_OP = status_op;
    assign STATUS_MEM = status_mem;
    assign STATUS_RUN = status_run;
    assign HEARTBEAT = counter[23];
    assign clk = debug_clk;
    assign data_out = debug_data;

    SB_HFOSC SB_HFOSC_inst(
        .CLKHFEN(1'b1),
        .CLKHFPU(1'b1),
        .CLKHF(core_clk)
    );
    defparam SB_HFOSC_inst.CLKHF_DIV = "0b01";

    hard_spi_programmer hard_spi_programmer_inst(
        .clk(core_clk),
        .reset(!enable),
        .spi_ss(SPI_SS),
        .spi_sck(SPI_SCK),
        .spi_mosi(SPI_MOSI),
        .spi_miso(SPI_MISO),
        .core_pc(pc),
        .core_halt(core_halt),
        .core_reset(core_reset),
        .imem_prog_we(imem_prog_we),
        .imem_prog_addr(imem_prog_addr),
        .imem_prog_wdata(imem_prog_wdata),
        .imem_prog_rdata(imem_prog_rdata)
    );

    oasis_core #(.PROGRAM_FILE("")) oasis_core_inst(
        .clk(core_clk),
        .reset(core_reset),
        .halt(core_halt),
        .imem_prog_we(imem_prog_we),
        .imem_prog_addr(imem_prog_addr),
        .imem_prog_wdata(imem_prog_wdata),
        .imem_prog_rdata(imem_prog_rdata),
        .pc_value(pc),
        .debug_out(out),
        .status_alu(status_alu),
        .status_op(status_op),
        .status_mem(status_mem),
        .status_run(status_run)
    );

    serial_debug_out serial_debug_out_inst(
        .clk(core_clk),
        .reset(core_reset),
        .pc(pc),
        .out_value(out),
        .debug_clk(debug_clk),
        .debug_data(debug_data)
    );

    initial begin
        counter = 32'h00000000;
    end

    always @(posedge core_clk) begin
        if (core_reset) begin
            counter <= 32'h00000000;
        end else begin
            counter <= counter + 1'b1;
        end
    end

endmodule
