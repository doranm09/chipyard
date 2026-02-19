BOARD:=$(patsubst rocket-fpga-%,%,$(PLATFORM))
ifneq ($(filter $(BOARD), zcu104),)
	DRAM_BASE:=0x40000000
	SUFFIX:=zynqmp
else ifneq ($(filter $(BOARD), zybo),)
	DRAM_BASE:=0x10000000
	SUFFIX:=zynq
else
    $(error unknown target $(PLATFORM))
endif

GCC=riscv64-unknown-elf-gcc
OBJCOPY=riscv64-unknown-elf-objcopy

all: bootrom_$(SUFFIX).img

%.img: %.bin
	dd if=$< of=$@ bs=128 count=1

%.bin: %.elf
	$(OBJCOPY) -O binary $< $@

%.elf: bootrom.S linker.ld
	$(GCC) -Tlinker.ld $< -nostdlib -static -Wl,--no-gc-sections -DDRAM_BASE=$(DRAM_BASE) -o $@

clean:
	-rm *.img