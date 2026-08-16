import board
import busio
import digitalio
import time
import oakdevtech_icepython


BITSTREAM = "top.bin"
DUNGV_PROGRAM_IMAGE = "bma530_rgb_tilt.spi16"
DUNGV_SPI_BAUDRATE = 250_000

spi = busio.SPI(clock=board.F_SCK, MOSI=board.F_MOSI, MISO=board.F_MISO)
iceprog = oakdevtech_icepython.Oakdevtech_icepython(
    spi, board.F_CSN, board.F_RST, BITSTREAM
)

started = time.monotonic()
iceprog.program_fpga()
print("programmed FPGA from", BITSTREAM, "in", time.monotonic() - started, "seconds")

# Allow FPGA configuration and hard-SPI initialization to settle.
time.sleep(0.05)
cs = digitalio.DigitalInOut(board.F_CSN)
sideband_enable = digitalio.DigitalInOut(board.F3)
sideband_enable.switch_to_output(value=False)


def dungv_spi_exchange(frame):
    while not spi.try_lock():
        pass
    try:
        spi.configure(baudrate=DUNGV_SPI_BAUDRATE, phase=0, polarity=0)
        readback = bytearray(len(frame))
        cs.value = False
        spi.write_readinto(frame, readback)
        return readback
    finally:
        cs.value = True
        spi.unlock()


def dungv_program_spi16(path):
    frames = 0
    cs.switch_to_output(value=True)
    sideband_enable.value = True
    time.sleep(0.01)
    with open(path, "r") as image:
        for raw_line in image:
            line = raw_line.strip()
            if not line or line.startswith("#"):
                continue
            dungv_spi_exchange(bytearray.fromhex(line))
            frames += 1
    print("DungV programmed", frames, "SPI16 frames from", path)


try:
    dungv_program_spi16(DUNGV_PROGRAM_IMAGE)
except OSError as exc:
    print("DungV program image not found:", DUNGV_PROGRAM_IMAGE, exc)
    print("copy .build/examples/bma530_rgb_tilt.spi16 to CIRCUITPY")
    raise

# F13/F20 now belong exclusively to the FPGA's open-drain I2C bus. Observe
# the CPU result through the independent F2/F6 synchronous debug link.
debug_clk = digitalio.DigitalInOut(board.F2)
debug_clk.switch_to_input()
debug_data = digitalio.DigitalInOut(board.F6)
debug_data.switch_to_input()


def debug_bit():
    while debug_clk.value:
        pass
    while not debug_clk.value:
        pass
    return 1 if debug_data.value else 0


def debug_byte():
    value = 0
    for _ in range(8):
        value = (value << 1) | debug_bit()
    return value


def debug_frame():
    # Search bit-by-bit so startup in the middle of a frame cannot leave the
    # reader permanently byte-misaligned.
    sync = 0
    while sync != 0xA5:
        sync = ((sync << 1) | debug_bit()) & 0xFF
    pc_low = debug_byte()
    value = (debug_byte() << 8) | debug_byte()
    return pc_low, value


mapped_x = None
mapped_y = None
mapped_z = None
print("waiting for BMA530 XYZ-magnitude-to-RGB diagnostics")

while True:
    pc_low, value = debug_frame()
    if value == 0xDE01:
        print("BMA530 RGB FAIL", "CHIP_ID mismatch")
    elif value == 0xDE02:
        print("BMA530 RGB FAIL", "health status")
    elif value == 0xDE03:
        print("BMA530 RGB FAIL", "runtime I2C NACK")
    elif (value & 0xFF00) == 0xA100:
        mapped_x = value & 0xFF
    elif (value & 0xFF00) == 0xA200:
        mapped_y = value & 0xFF
    elif (value & 0xFF00) == 0xA300:
        mapped_z = value & 0xFF
        if mapped_x is not None and mapped_y is not None:
            print("BMA530 |XYZ|->RGB", mapped_x, mapped_y, mapped_z)
    elif (value & 0xFF00) == 0xE000:
        status = value & 0xFF
        print("I2C STATUS", hex(status), "nack=", bool(status & 0x02),
              "scl=", bool(status & 0x04), "sda=", bool(status & 0x08))
    else:
        print("debug frame", "pc_low=", hex(pc_low), "out=", hex(value))
