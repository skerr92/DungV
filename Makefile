OASIS_DIR ?= OASIS
BUILD_DIR ?= .build
OASIS_ASM := python3 $(OASIS_DIR)/tools/oasis_asm.py
OASIS_PROGRAM_IMAGE := python3 $(OASIS_DIR)/tools/oasis_program_image.py
OASIS_CC := $(OASIS_DIR)/bin/oasis-cc
OASIS_ELF2IMG := $(OASIS_DIR)/bin/oasis-elf2img

ASM_SOURCES := $(wildcard examples/*.oas)
ASM_IMAGES := $(patsubst examples/%.oas,$(BUILD_DIR)/examples/%.mem,$(ASM_SOURCES))
ASM_DAP_IMAGES := $(patsubst examples/%.oas,$(BUILD_DIR)/examples/%.dap16,$(ASM_SOURCES))
ASM_SPI_IMAGES := $(patsubst examples/%.oas,$(BUILD_DIR)/examples/%.spi16,$(ASM_SOURCES))
C_SOURCES := $(wildcard examples/*.c)
C_ELFS := $(patsubst examples/%.c,$(BUILD_DIR)/examples/%.elf,$(C_SOURCES))
C_IMAGES := $(patsubst examples/%.c,$(BUILD_DIR)/examples/%.dap16,$(C_SOURCES))

.PHONY: examples examples-asm examples-c compliance compliance-base16 check clean

examples: examples-asm examples-programming

examples-asm: $(ASM_IMAGES)

examples-programming: $(ASM_DAP_IMAGES) $(ASM_SPI_IMAGES)

examples-c: $(C_IMAGES)

compliance: compliance-base16

compliance-base16:
	python3 tools/generate_compliance_programs.py \
		--source-dir $(OASIS_DIR)/tests/compliance \
		--out-dir $(BUILD_DIR)/compliance/base16-v0.1 \
		--profile oasis-base16-v0.1-draft \
		--assembler $(OASIS_DIR)/tools/oasis_asm.py

check:
	$(MAKE) -C $(OASIS_DIR) check
	$(MAKE) -C rtl/dungv test
	$(MAKE) compliance

clean:
	$(MAKE) -C rtl/dungv clean
	rm -rf $(BUILD_DIR)

$(BUILD_DIR)/examples/%.mem: examples/%.oas
	mkdir -p $(BUILD_DIR)/examples
	$(OASIS_ASM) $< -o $@

$(BUILD_DIR)/examples/%.dap16: examples/%.oas
	mkdir -p $(BUILD_DIR)/examples
	$(OASIS_PROGRAM_IMAGE) $< -o $@

$(BUILD_DIR)/examples/%.spi16: examples/%.oas
	mkdir -p $(BUILD_DIR)/examples
	$(OASIS_PROGRAM_IMAGE) $< --format spi16-hex -o $@

$(BUILD_DIR)/examples/%.elf: examples/%.c
	mkdir -p $(BUILD_DIR)/examples
	$(OASIS_CC) -ffreestanding -nostdlib \
		-I $(OASIS_DIR)/toolchain/runtime/include \
		-T $(OASIS_DIR)/toolchain/runtime/linker/oasis16.ld \
		$(OASIS_DIR)/toolchain/runtime/crt0.S $< -o $@

$(BUILD_DIR)/examples/%.dap16: $(BUILD_DIR)/examples/%.elf
	$(OASIS_ELF2IMG) $< -o $@
