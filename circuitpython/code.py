import board
import busio
import digitalio
import time
import oakdevtech_icepython



BITSTREAM = "top.bin"


spi = busio.SPI(clock=board.F_SCK, MOSI=board.F_MOSI, MISO=board.F_MISO)

iceprog = oakdevtech_icepython.Oakdevtech_icepython(
    spi,
    board.F_CSN,
    board.F_RST,
    BITSTREAM,
)

timestamp = time.monotonic()
iceprog.program_fpga()
endstamp = time.monotonic()

print("programmed FPGA from", BITSTREAM, "in", endstamp - timestamp, "seconds")

sideband_clk = digitalio.DigitalInOut(board.F2)
sideband_enable = digitalio.DigitalInOut(board.F3)
sideband_data = digitalio.DigitalInOut(board.F4)
sideband_debug_data = digitalio.DigitalInOut(board.F6)
sideband_clk.switch_to_input()
sideband_enable.switch_to_output(value=False)
sideband_data.switch_to_output(value=False)
sideband_debug_data.switch_to_input()

cs = digitalio.DigitalInOut(board.F_CSN)



# ---------------------------------------------------------------------------
# DungV OASIS SPI16 programming
# ---------------------------------------------------------------------------

DUNGV_PROGRAM_IMAGE = "v0_1_full_sweep.spi16"
DUNGV_SPI_BAUDRATE = 250_000


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
    cs.value = True

    with open(path, "r") as image:
        for raw_line in image:
            line = raw_line.strip()
            if not line or line.startswith("#"):
                continue

            dungv_spi_exchange(bytearray.fromhex(line))
            frames += 1

            if frames % 64 == 0:
                print("DungV programmed", frames, "SPI16 frames")

    print("DungV programmed", frames, "SPI16 frames from", path)


try:
    dungv_program_spi16(DUNGV_PROGRAM_IMAGE)
except OSError as exc:
    print("DungV program image not found:", DUNGV_PROGRAM_IMAGE, exc)
    print("copy .build/examples/v0_1_full_sweep.spi16 to CIRCUITPY as", DUNGV_PROGRAM_IMAGE)


# ---------------------------------------------------------------------------
# DungV serial debug reader
# ---------------------------------------------------------------------------

DEBUG_READ_TIMEOUT = 1.0


def wait_for_debug_rising_edge(timeout=DEBUG_READ_TIMEOUT):
    deadline = time.monotonic() + timeout

    while sideband_clk.value:
        if time.monotonic() >= deadline:
            return False

    while not sideband_clk.value:
        if time.monotonic() >= deadline:
            return False

    return True


def read_debug_byte():
    value = 0

    for _ in range(8):
        if not wait_for_debug_rising_edge():
            return None
        value = (value << 1) | int(sideband_debug_data.value)

    return value


debug_bytes = []
print("reading DungV serial debug stream on F2/F6")
print("debug frame: sync=0xa5 pc_low=<program counter low byte> out=<latest debug_out value>")

while True:
    next_byte = read_debug_byte()
    if next_byte is None:
        if debug_bytes:
            print("debug partial:", " ".join("%02x" % byte for byte in debug_bytes))
            debug_bytes = []
        print("waiting for DungV serial debug clock")
        continue

    debug_bytes.append(next_byte)

    if len(debug_bytes) == 4:
        sync = debug_bytes[0]
        pc_low = debug_bytes[1]
        debug_out = (debug_bytes[2] << 8) | debug_bytes[3]
        sync_note = "ok" if sync == 0xA5 else "resync?"
        print(
            "debug frame: sync=0x%02x(%s) pc_low=0x%02x out=0x%04x out_dec=%d"
            % (sync, sync_note, pc_low, debug_out, debug_out)
        )
        debug_bytes = []
