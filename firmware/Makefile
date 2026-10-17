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

# <output name>:<BOARD_ macro in blinky.c>:<cpu>  ->  $(OUT)/<output name>_pwm_blinky.{elf,bin}
BOARDS = f4discovery:F407DISCO:cortex-m4 \
         f3discovery:F3DISCO:cortex-m4 \
         nucleol476rg:L4NUCLEO64:cortex-m4 \
         nucleol432kc:L4NUCLEO32:cortex-m4 \
         nucleoc031c6:C0NUCLEO:cortex-m0plus
field = $(word $(2),$(subst :, ,$(1)))
all: $(foreach b,$(BOARDS),$(OUT)/$(call field,$(b),1)_pwm_blinky.bin)

define board
$(OUT)/$(1)_pwm_blinky.elf: blinky.c link.ld
	@mkdir -p $(OUT)
	$(CC) -mcpu=$(3) -mthumb $(CFLAGS) -DBOARD_$(2) -o $$@ blinky.c -lgcc
endef
$(foreach b,$(BOARDS),$(eval $(call board,$(call field,$(b),1),$(call field,$(b),2),$(call field,$(b),3))))

$(OUT)/%.bin: $(OUT)/%.elf
	$(OBJCOPY) -O binary $< $@

clean:
	rm -rf out out-*
