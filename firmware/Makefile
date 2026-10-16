# Builds one breathing-LED binary per supported board into $(OUT)/
# make PERIOD_MS=1000 OUT=out-2x  -> twice the breathing frequency
PERIOD_MS ?= 2000
OUT ?= out
# arm-none-eabi-gcc from PATH (e.g. Debian/Ubuntu "gcc-arm-none-eabi"), or the
# one built by tools/build-arm-toolchain.sh if it exists
LOCAL_TC := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/../armgcc/install/bin)
CROSS_COMPILE ?= $(if $(wildcard $(LOCAL_TC)/arm-none-eabi-gcc),$(LOCAL_TC)/)arm-none-eabi-
CC = $(CROSS_COMPILE)gcc
OBJCOPY = $(CROSS_COMPILE)objcopy
CFLAGS = -DPERIOD_MS=$(PERIOD_MS)u -Os -ffreestanding -nostdlib -Wall -Wextra -Wno-main -T link.ld -Wl,--gc-sections

BOARDS = f407disco:cortex-m4 f3disco:cortex-m4 l4nucleo64:cortex-m4 l4nucleo32:cortex-m4 c0nucleo:cortex-m0plus
all: $(foreach b,$(BOARDS),$(OUT)/blinky_$(firstword $(subst :, ,$(b))).bin)

define board
$(OUT)/blinky_$(1).elf: blinky.c link.ld
	@mkdir -p $(OUT)
	$(CC) -mcpu=$(2) -mthumb $(CFLAGS) -DBOARD_$(shell echo $(1) | tr a-z A-Z) -o $$@ blinky.c -lgcc
endef
$(foreach b,$(BOARDS),$(eval $(call board,$(firstword $(subst :, ,$(b))),$(lastword $(subst :, ,$(b))))))

$(OUT)/%.bin: $(OUT)/%.elf
	$(OBJCOPY) -O binary $< $@

clean:
	rm -rf out out-*
