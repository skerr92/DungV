`default_nettype none
`include "oasis_defs.vh"

module spi_programmer(
    input wire clk,
    input wire reset,
    input wire spi_ss,
    input wire spi_sck,
    input wire spi_mosi,
    output wire spi_miso,
    input wire [`OASIS_PC_WIDTH-1:0] core_pc,
    output wire core_halt,
    output wire core_reset,
    output reg imem_prog_we,
    output reg [`OASIS_PC_WIDTH-1:0] imem_prog_addr,
    output reg [`OASIS_INSTR_WIDTH-1:0] imem_prog_wdata,
    input wire [`OASIS_INSTR_WIDTH-1:0] imem_prog_rdata
);

    localparam [7:0] CMD_WRITE = 8'h01;
    localparam [7:0] CMD_READ = 8'h02;

    localparam [15:0] REG_CONTROL       = 16'h0000;
    localparam [15:0] REG_STATUS        = 16'h0001;
    localparam [15:0] REG_CORE_ID       = 16'h0002;
    localparam [15:0] REG_OASIS_PROFILE = 16'h0003;
    localparam [15:0] REG_IMEM_ADDR     = 16'h0004;
    localparam [15:0] REG_IMEM_WDATA_LO = 16'h0005;
    localparam [15:0] REG_IMEM_WDATA_HI = 16'h0006;
    localparam [15:0] REG_IMEM_RDATA_LO = 16'h0007;
    localparam [15:0] REG_IMEM_RDATA_HI = 16'h0008;

    localparam integer CTRL_HALT       = 0;
    localparam integer CTRL_RESET      = 1;
    localparam integer CTRL_IMEM_WRITE = 2;
    localparam integer CTRL_IMEM_READ  = 3;
    localparam integer CTRL_AUTO_INC   = 4;

    reg [2:0] ss_sync;
    reg [2:0] sck_sync;
    reg [1:0] mosi_sync;
    reg [5:0] bit_count;
    reg [39:0] rx_shift;
    reg [15:0] tx_shift;
    reg miso_reg;

    reg [15:0] control;
    reg [15:0] imem_addr_reg;
    reg [15:0] imem_wdata_lo;
    reg [15:0] imem_wdata_hi;
    reg [15:0] imem_rdata_lo;
    reg [15:0] imem_rdata_hi;

    wire ss_active = !ss_sync[2];
    wire ss_start = ss_sync[2:1] == 2'b10;
    wire ss_end = ss_sync[2:1] == 2'b01;
    wire sck_rise = ss_active && sck_sync[2:1] == 2'b01;
    wire sck_fall = ss_active && sck_sync[2:1] == 2'b10;
    wire [39:0] next_rx_shift = {rx_shift[38:0], mosi_sync[1]};
    wire [7:0] frame_cmd = next_rx_shift[39:32];
    wire [15:0] frame_addr = next_rx_shift[31:16];
    wire [15:0] frame_data = next_rx_shift[15:0];
    wire [7:0] read_cmd = next_rx_shift[23:16];
    wire [15:0] read_addr = next_rx_shift[15:0];
    wire read_data_phase = bit_count >= 6'd24;

    assign spi_miso = miso_reg;
    assign core_halt = control[CTRL_HALT];
    assign core_reset = reset || control[CTRL_RESET];

    function [15:0] read_register;
        input [15:0] addr;
        begin
            case (addr)
                REG_CONTROL: read_register = control;
                REG_STATUS: read_register = {12'h000, 1'b0, 1'b0, core_reset, core_halt};
                REG_CORE_ID: read_register = 16'hd016;
                REG_OASIS_PROFILE: read_register = 16'h0001;
                REG_IMEM_ADDR: read_register = imem_addr_reg;
                REG_IMEM_WDATA_LO: read_register = imem_wdata_lo;
                REG_IMEM_WDATA_HI: read_register = imem_wdata_hi;
                REG_IMEM_RDATA_LO: read_register = imem_rdata_lo;
                REG_IMEM_RDATA_HI: read_register = imem_rdata_hi;
                16'h0009: read_register = {{(16-`OASIS_PC_WIDTH){1'b0}}, core_pc};
                default: read_register = 16'h0000;
            endcase
        end
    endfunction

    task write_register;
        input [15:0] addr;
        input [15:0] data;
        begin
            case (addr)
                REG_CONTROL: begin
                    control <= data & ~(16'h000c);
                    if (data[CTRL_IMEM_WRITE]) begin
                        imem_prog_addr <= imem_addr_reg[`OASIS_PC_WIDTH-1:0];
                        imem_prog_wdata <= {imem_wdata_hi, imem_wdata_lo};
                        imem_prog_we <= 1'b1;
                        if (data[CTRL_AUTO_INC]) begin
                            imem_addr_reg <= imem_addr_reg + 1'b1;
                        end
                    end
                    if (data[CTRL_IMEM_READ]) begin
                        imem_rdata_lo <= imem_prog_rdata[15:0];
                        imem_rdata_hi <= imem_prog_rdata[31:16];
                        if (data[CTRL_AUTO_INC]) begin
                            imem_addr_reg <= imem_addr_reg + 1'b1;
                        end
                    end
                end
                REG_IMEM_ADDR: imem_addr_reg <= data;
                REG_IMEM_WDATA_LO: imem_wdata_lo <= data;
                REG_IMEM_WDATA_HI: imem_wdata_hi <= data;
            endcase
        end
    endtask

    always @(posedge clk) begin
        if (reset) begin
            ss_sync <= 3'b111;
            sck_sync <= 3'b000;
            mosi_sync <= 2'b00;
        end else begin
            ss_sync <= {ss_sync[1:0], spi_ss};
            sck_sync <= {sck_sync[1:0], spi_sck};
            mosi_sync <= {mosi_sync[0], spi_mosi};
        end
    end

    always @(posedge clk) begin
        imem_prog_we <= 1'b0;

        if (reset) begin
            bit_count <= 6'd0;
            rx_shift <= 40'h0000000000;
            tx_shift <= 16'h0000;
            miso_reg <= 1'b0;
            control <= 16'h0000;
            imem_addr_reg <= 16'h0000;
            imem_wdata_lo <= 16'h0000;
            imem_wdata_hi <= 16'h0000;
            imem_rdata_lo <= 16'h0000;
            imem_rdata_hi <= 16'h0000;
            imem_prog_addr <= {`OASIS_PC_WIDTH{1'b0}};
            imem_prog_wdata <= {`OASIS_INSTR_WIDTH{1'b0}};
        end else if (ss_start) begin
            bit_count <= 6'd0;
            rx_shift <= 40'h0000000000;
            tx_shift <= 16'h0000;
            miso_reg <= 1'b0;
        end else if (ss_end) begin
            bit_count <= 6'd0;
            miso_reg <= 1'b0;
        end else begin
            if (sck_rise) begin
                rx_shift <= next_rx_shift;
                bit_count <= bit_count + 1'b1;

                if (bit_count == 6'd23 && read_cmd == CMD_READ) begin
                    tx_shift <= read_register(read_addr);
                end

                if (bit_count == 6'd39 && frame_cmd == CMD_WRITE) begin
                    write_register(frame_addr, frame_data);
                end
            end

            if (sck_fall && read_data_phase) begin
                miso_reg <= tx_shift[15];
                tx_shift <= {tx_shift[14:0], 1'b0};
            end
        end
    end

endmodule
