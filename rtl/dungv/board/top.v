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
    inout wire I2C_SCL,
    inout wire I2C_SDA,
    output wire RGB0,
    output wire RGB1,
    output wire RGB2
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
    wire mmio_valid;
    wire mmio_write;
    wire [`OASIS_DATA_ADDR_WIDTH-1:0] mmio_addr;
    wire [`OASIS_XLEN-1:0] mmio_wdata;
    wire [`OASIS_XLEN-1:0] mmio_rdata;
    wire mmio_ready;
    wire mmio_error;
    wire gpio_select;
    wire [`OASIS_XLEN-1:0] gpio_rdata;
    wire gpio_ready;
    wire gpio_error;
    wire pwm_select;
    wire [`OASIS_XLEN-1:0] pwm_rdata;
    wire pwm_ready;
    wire pwm_error;
    wire [1:0] gpio_out;
    wire [2:0] pwm_rgb;
    wire uart_select;
    wire [`OASIS_XLEN-1:0] uart_rdata;
    wire uart_ready;
    wire uart_error;
    wire uart_tx_unused;
    wire i2c_select;
    wire [`OASIS_XLEN-1:0] i2c_rdata;
    wire i2c_ready;
    wire i2c_error;
    wire i2c_scl_drive_low;
    wire i2c_sda_drive_low;
    wire rgb_current;

    assign clk = debug_clk;
    assign data_out = debug_data;
    assign I2C_SCL = i2c_scl_drive_low ? 1'b0 : 1'bz;
    assign I2C_SDA = i2c_sda_drive_low ? 1'b0 : 1'bz;

    // F39/F40/F41 use the iCE5LP4K split current/RGB driver primitives. Their
    // PWM inputs retain the active-high GPIO_OUT semantics used by software.
    SB_LED_DRV_CUR rgb_current_inst (
        .EN(1'b1),
        .LEDPU(rgb_current)
    );

    SB_RGB_DRV #(
        .CURRENT_MODE("0b1"),
        .RGB0_CURRENT("0b000111"),
        .RGB1_CURRENT("0b000111"),
        .RGB2_CURRENT("0b000111")
    ) rgb_driver_inst (
        .RGBLEDEN(1'b1),
        .RGB0PWM(pwm_rgb[0]),
        .RGB1PWM(pwm_rgb[1]),
        .RGB2PWM(pwm_rgb[2]),
        .RGBPU(rgb_current),
        .RGB0(RGB0),
        .RGB1(RGB1),
        .RGB2(RGB2)
    );

    SB_HFOSC SB_HFOSC_inst(
        .CLKHFEN(1'b1),
        .CLKHFPU(1'b1),
        .CLKHF(core_clk)
    );
    defparam SB_HFOSC_inst.CLKHF_DIV = "0b10";

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
        .mmio_valid(mmio_valid),
        .mmio_write(mmio_write),
        .mmio_addr(mmio_addr),
        .mmio_wdata(mmio_wdata),
        .mmio_rdata(mmio_rdata),
        .mmio_ready(mmio_ready),
        .mmio_error(mmio_error),
        .status_alu(status_alu),
        .status_op(status_op),
        .status_mem(status_mem),
        .status_run(status_run)
    );

    assign gpio_select = mmio_addr <= 11'h001;
    assign pwm_select = mmio_addr >= 11'h010 && mmio_addr <= 11'h014;
    assign uart_select = mmio_addr >= 11'h020 && mmio_addr <= 11'h022;
    assign i2c_select = mmio_addr >= 11'h030 && mmio_addr <= 11'h034;
    assign mmio_rdata = gpio_select ? gpio_rdata :
                        pwm_select ? pwm_rdata :
                        uart_select ? uart_rdata :
                        i2c_select ? i2c_rdata : {`OASIS_XLEN{1'b0}};
    assign mmio_ready = mmio_valid &&
                        ((gpio_select && gpio_ready) ||
                         (pwm_select && pwm_ready) ||
                         (uart_select && uart_ready) ||
                         (i2c_select && i2c_ready) ||
                         (!gpio_select && !pwm_select && !uart_select && !i2c_select));
    assign mmio_error = mmio_valid &&
                        ((gpio_select && gpio_error) ||
                         (pwm_select && pwm_error) ||
                         (uart_select && uart_error) ||
                         (i2c_select && i2c_error) ||
                         (!gpio_select && !pwm_select && !uart_select && !i2c_select));

    gpio_mmio #(.GPIO_WIDTH(2)) gpio_mmio_inst(
        .clk(core_clk),
        .reset(core_reset),
        .valid(mmio_valid && gpio_select),
        .write(mmio_write),
        .addr(mmio_addr),
        .wdata(mmio_wdata),
        .rdata(gpio_rdata),
        .ready(gpio_ready),
        .error(gpio_error),
        .gpio_in({1'b0, data}),
        .gpio_out(gpio_out)
    );

    pwm_mmio pwm_mmio_inst(
        .clk(core_clk),
        .reset(core_reset),
        .valid(mmio_valid && pwm_select),
        .write(mmio_write),
        .addr(mmio_addr),
        .wdata(mmio_wdata),
        .rdata(pwm_rdata),
        .ready(pwm_ready),
        .error(pwm_error),
        .pwm_out(pwm_rgb)
    );

    uart_mmio uart_mmio_inst(
        .clk(core_clk),
        .reset(core_reset),
        .valid(mmio_valid && uart_select),
        .write(mmio_write),
        .addr(mmio_addr),
        .wdata(mmio_wdata),
        .rdata(uart_rdata),
        .ready(uart_ready),
        .error(uart_error),
        .uart_rx(1'b1),
        .uart_tx(uart_tx_unused)
    );

    i2c_master_mmio i2c_master_mmio_inst(
        .clk(core_clk),
        .reset(core_reset),
        .valid(mmio_valid && i2c_select),
        .write(mmio_write),
        .addr(mmio_addr),
        .wdata(mmio_wdata),
        .rdata(i2c_rdata),
        .ready(i2c_ready),
        .error(i2c_error),
        .scl_in(I2C_SCL),
        .sda_in(I2C_SDA),
        .scl_drive_low(i2c_scl_drive_low),
        .sda_drive_low(i2c_sda_drive_low)
    );

    serial_debug_out serial_debug_out_inst(
        .clk(core_clk),
        .reset(core_reset),
        .pc(pc),
        .out_value(out),
        .debug_clk(debug_clk),
        .debug_data(debug_data)
    );

endmodule
