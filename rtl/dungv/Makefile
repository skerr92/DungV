filename = top
pcf_file = ../../common/io.pcf
sim_build_dir = sim/build
sources = board/top.v \
	core/oasis_core.v \
	decode/instr_decode.v \
	execute/alu.v \
	memory/instr_mem.v \
	memory/data_mem.v \
	registers/register_file.v

build:
	yosys -Iinclude -p "synth_ice40 -abc2 -dsp -top top -json $(filename).json" $(sources)
	nextpnr-ice40 --u4k --package sg48 --json $(filename).json --pcf $(pcf_file) --asc $(filename).asc
	icepack $(filename).asc $(filename).bin

test:
	mkdir -p $(sim_build_dir)
	iverilog -g2012 -Iinclude -o $(sim_build_dir)/alu_tb execute/alu.v sim/testbenches/alu_tb.v
	vvp $(sim_build_dir)/alu_tb
	iverilog -g2012 -Iinclude -o $(sim_build_dir)/decode_tb decode/instr_decode.v sim/testbenches/decode_tb.v
	vvp $(sim_build_dir)/decode_tb

prog: #for sram
	iceprog -S $(filename).bin

prog_flash:
	iceprog $(filename).bin

clean:
	rm -rf $(filename).blif $(filename).asc $(filename).bin $(filename).json $(sim_build_dir)
