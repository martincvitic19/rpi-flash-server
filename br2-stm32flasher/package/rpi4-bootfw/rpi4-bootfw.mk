################################################################################
#
# rpi4-bootfw
#
################################################################################

# Only the two files the Pi 4 needs, instead of the whole (large) firmware repo
RPI4_BOOTFW_VERSION = 12eeaa12865869b07db760f4bbb7507ec6f1976c
RPI4_BOOTFW_SITE = https://raw.githubusercontent.com/raspberrypi/firmware/$(RPI4_BOOTFW_VERSION)/boot
RPI4_BOOTFW_SOURCE = start4.elf
RPI4_BOOTFW_EXTRA_DOWNLOADS = fixup4.dat
RPI4_BOOTFW_LICENSE = BSD-3-Clause (Broadcom redistributable binary)
RPI4_BOOTFW_INSTALL_TARGET = NO
RPI4_BOOTFW_INSTALL_IMAGES = YES

define RPI4_BOOTFW_EXTRACT_CMDS
	cp $(RPI4_BOOTFW_DL_DIR)/start4.elf $(RPI4_BOOTFW_DL_DIR)/fixup4.dat $(@D)/
endef

define RPI4_BOOTFW_INSTALL_IMAGES_CMDS
	$(INSTALL) -D -m 0644 $(@D)/start4.elf $(BINARIES_DIR)/start4.elf
	$(INSTALL) -D -m 0644 $(@D)/fixup4.dat $(BINARIES_DIR)/fixup4.dat
endef

$(eval $(generic-package))
