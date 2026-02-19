# Root setup
ROOT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
BUILD_DIR := $(ROOT_DIR)/build

# RISCV toolchain
CC      := $(RISCV)/bin/riscv64-unknown-elf-gcc
OBJCOPY := $(RISCV)/bin/riscv64-unknown-elf-objcopy
OBJDUMP := $(RISCV)/bin/riscv64-unknown-elf-objdump

# Compile flags
CFLAGS  := -march=rv64ima_zicsr_zifencei -mcmodel=medany -mabi=lp64 -O2 -g -Wall -std=gnu11 -nostartfiles
CFLAGS  += -fno-common -DENTROPY=0 -DNONSMP_HART=0
CFLAGS  += -I$(ROOT_DIR)/include -I.

# Link flags
LDSCRIPT := $(ROOT_DIR)/linker/flat.lds
LFLAGS   := -T $(LDSCRIPT) -nostdlib -static

# Default clock (can be overridden)
PBUS_CLK ?= 1000000
CFLAGS   += -DTL_CLK="$(PBUS_CLK)UL"

# Targets
ELF  := $(BUILD_DIR)/hello.elf
BIN  := $(BUILD_DIR)/hello.bin
DUMP := $(BUILD_DIR)/hello.dump

# Source files
SRC := hello_world.c kprintf.c

default: bin

# Build ELF
$(ELF): $(SRC)
	mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) $(LFLAGS) -o $@ $(SRC)

.PHONY: elf
elf: $(ELF)

# Create raw binary
$(BIN): $(ELF)
	$(OBJCOPY) -O binary $< $@

.PHONY: bin
bin: $(BIN)

# Optional disassembly
$(DUMP): $(ELF)
	$(OBJDUMP) -D -S $< > $@

.PHONY: dump
dump: $(DUMP)

# Clean up
.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)
