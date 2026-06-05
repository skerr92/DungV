`default_nettype none
`include "oasis_defs.vh"

module hard_spi_programmer(
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

    localparam [7:0] SPI_ADDR_SPICR0  = 8'h08;
    localparam [7:0] SPI_ADDR_SPICR1  = 8'h09;
    localparam [7:0] SPI_ADDR_SPICR2  = 8'h0a;
    localparam [7:0] SPI_ADDR_SPIBR   = 8'h0b;
    localparam [7:0] SPI_ADDR_SPISR   = 8'h0c;
    localparam [7:0] SPI_ADDR_SPITXDR = 8'h0d;
    localparam [7:0] SPI_ADDR_SPIRXDR = 8'h0e;
    localparam [7:0] SPI_ADDR_SPICSR  = 8'h0f;

    localparam [4:0] ST_INIT_CR0       = 5'd0;
    localparam [4:0] ST_INIT_CR1       = 5'd1;
    localparam [4:0] ST_INIT_CR2       = 5'd2;
    localparam [4:0] ST_INIT_BR        = 5'd3;
    localparam [4:0] ST_INIT_CSR       = 5'd4;
    localparam [4:0] ST_POLL_RX        = 5'd5;
    localparam [4:0] ST_READ_RX        = 5'd6;
    localparam [4:0] ST_WAIT_TX_READY  = 5'd7;
    localparam [4:0] ST_WRITE_TX       = 5'd8;

    reg spi_stb;
    reg spi_rw;
    reg [7:0] spi_adr;
    reg [7:0] spi_dati;
    wire [7:0] spi_dato;
    wire spi_ack;

    reg [4:0] state;
    reg [2:0] frame_index;
    reg [7:0] frame_cmd;
    reg [15:0] frame_addr;
    reg [15:0] frame_data;
    reg [15:0] read_value;
    reg [7:0] tx_next;

    reg [15:0] control;
    reg [15:0] imem_addr_reg;
    reg [15:0] imem_wdata_lo;
    reg [15:0] imem_wdata_hi;
    reg [15:0] imem_rdata_lo;
    reg [15:0] imem_rdata_hi;
    wire [15:0] rx_read_value;

    assign core_halt = control[CTRL_HALT];
    assign core_reset = reset || control[CTRL_RESET];
    assign rx_read_value = read_register({frame_addr[15:8], spi_dato});

    SB_SPI SB_SPI_inst(
        .SBCLKI(clk),
        .SBSTBI(spi_stb),
        .SBRWI(spi_rw),
        .SBADRI0(spi_adr[0]),
        .SBADRI1(spi_adr[1]),
        .SBADRI2(spi_adr[2]),
        .SBADRI3(spi_adr[3]),
        .SBADRI4(spi_adr[4]),
        .SBADRI5(spi_adr[5]),
        .SBADRI6(spi_adr[6]),
        .SBADRI7(spi_adr[7]),
        .SBDATI0(spi_dati[0]),
        .SBDATI1(spi_dati[1]),
        .SBDATI2(spi_dati[2]),
        .SBDATI3(spi_dati[3]),
        .SBDATI4(spi_dati[4]),
        .SBDATI5(spi_dati[5]),
        .SBDATI6(spi_dati[6]),
        .SBDATI7(spi_dati[7]),
        .SBDATO0(spi_dato[0]),
        .SBDATO1(spi_dato[1]),
        .SBDATO2(spi_dato[2]),
        .SBDATO3(spi_dato[3]),
        .SBDATO4(spi_dato[4]),
        .SBDATO5(spi_dato[5]),
        .SBDATO6(spi_dato[6]),
        .SBDATO7(spi_dato[7]),
        .SBACKO(spi_ack),
        .MI(1'b0),
        .SI(spi_mosi),
        .SCKI(spi_sck),
        .SCSNI(spi_ss),
        .SO(spi_miso),
        .SOE(),
        .MO(),
        .MOE(),
        .SCKO(),
        .SCKOE(),
        .MCSNO3(),
        .MCSNO2(),
        .MCSNO1(),
        .MCSNO0(),
        .MCSNOE3(),
        .MCSNOE2(),
        .MCSNOE1(),
        .MCSNOE0(),
        .SPIIRQ(),
        .SPIWKUP()
    );

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

    task init_write;
        input [7:0] addr;
        input [7:0] data;
        input [4:0] next_state;
        begin
            spi_adr <= addr;
            spi_dati <= data;
            spi_rw <= 1'b1;
            spi_stb <= 1'b1;
            if (spi_ack) begin
                spi_stb <= 1'b0;
                state <= next_state;
            end
        end
    endtask

    always @(posedge clk) begin
        imem_prog_we <= 1'b0;
        spi_stb <= 1'b0;

        if (reset) begin
            state <= ST_INIT_CR0;
            frame_index <= 3'd0;
            frame_cmd <= 8'h00;
            frame_addr <= 16'h0000;
            frame_data <= 16'h0000;
            read_value <= 16'h0000;
            tx_next <= 8'h00;
            spi_rw <= 1'b0;
            spi_adr <= 8'h00;
            spi_dati <= 8'h00;
            control <= 16'h0000;
            imem_addr_reg <= 16'h0000;
            imem_wdata_lo <= 16'h0000;
            imem_wdata_hi <= 16'h0000;
            imem_rdata_lo <= 16'h0000;
            imem_rdata_hi <= 16'h0000;
            imem_prog_addr <= {`OASIS_PC_WIDTH{1'b0}};
            imem_prog_wdata <= {`OASIS_INSTR_WIDTH{1'b0}};
        end else begin
            case (state)
                ST_INIT_CR0: init_write(SPI_ADDR_SPICR0, 8'h00, ST_INIT_CR1);
                ST_INIT_CR1: init_write(SPI_ADDR_SPICR1, 8'h80, ST_INIT_CR2);
                ST_INIT_CR2: init_write(SPI_ADDR_SPICR2, 8'h00, ST_INIT_BR);
                ST_INIT_BR: init_write(SPI_ADDR_SPIBR, 8'h00, ST_INIT_CSR);
                ST_INIT_CSR: begin
                    frame_index <= 3'd0;
                    init_write(SPI_ADDR_SPICSR, 8'h00, ST_POLL_RX);
                end

                ST_POLL_RX: begin
                    spi_adr <= SPI_ADDR_SPISR;
                    spi_rw <= 1'b0;
                    spi_stb <= 1'b1;
                    if (spi_ack) begin
                        spi_stb <= 1'b0;
                        if (spi_dato[3]) begin
                            state <= ST_READ_RX;
                        end
                    end
                end

                ST_READ_RX: begin
                    spi_adr <= SPI_ADDR_SPIRXDR;
                    spi_rw <= 1'b0;
                    spi_stb <= 1'b1;
                    if (spi_ack) begin
                        spi_stb <= 1'b0;
                        tx_next <= 8'h00;

                        case (frame_index)
                            3'd0: begin
                                frame_cmd <= spi_dato;
                                frame_index <= 3'd1;
                            end

                            3'd1: begin
                                frame_addr[15:8] <= spi_dato;
                                frame_index <= 3'd2;
                            end

                            3'd2: begin
                                frame_addr[7:0] <= spi_dato;
                                read_value <= rx_read_value;
                                if (frame_cmd == CMD_READ) begin
                                    tx_next <= rx_read_value[15:8];
                                end
                                frame_index <= 3'd3;
                            end

                            3'd3: begin
                                frame_data[15:8] <= spi_dato;
                                if (frame_cmd == CMD_READ) begin
                                    tx_next <= read_value[7:0];
                                end
                                frame_index <= 3'd4;
                            end

                            default: begin
                                frame_data[7:0] <= spi_dato;
                                if (frame_cmd == CMD_WRITE) begin
                                    write_register(frame_addr, {frame_data[15:8], spi_dato});
                                end
                                frame_index <= 3'd0;
                            end
                        endcase

                        state <= ST_WAIT_TX_READY;
                    end
                end

                ST_WAIT_TX_READY: begin
                    spi_adr <= SPI_ADDR_SPISR;
                    spi_rw <= 1'b0;
                    spi_stb <= 1'b1;
                    if (spi_ack) begin
                        spi_stb <= 1'b0;
                        if (spi_dato[4]) begin
                            state <= ST_WRITE_TX;
                        end
                    end
                end

                ST_WRITE_TX: begin
                    spi_adr <= SPI_ADDR_SPITXDR;
                    spi_dati <= tx_next;
                    spi_rw <= 1'b1;
                    spi_stb <= 1'b1;
                    if (spi_ack) begin
                        spi_stb <= 1'b0;
                        state <= ST_POLL_RX;
                    end
                end

                default: state <= ST_INIT_CR0;
            endcase
        end
    end

endmodule
