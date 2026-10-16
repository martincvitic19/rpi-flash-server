################################################################################
#
# stm32cubeprog
#
################################################################################

# The download needs a myST login, so the zip from st.com is taken from a
# local directory (STM32CUBEPROG_SITE) instead of being fetched.
STM32CUBEPROG_VERSION = 2.23.0
STM32CUBEPROG_SOURCE = stm32cubeprogrammer_$(STM32CUBEPROG_VERSION)_arm64.deb.zip
STM32CUBEPROG_SITE = $(BR2_EXTERNAL_STM32FLASHER_PATH)/../dl/cubeprog
STM32CUBEPROG_SITE_METHOD = file
STM32CUBEPROG_LICENSE = SLA0048
STM32CUBEPROG_REDISTRIBUTE = NO
STM32CUBEPROG_DEPENDENCIES = libusb host-zstd
# FlashLoader/ExternalLoader *.stldr are Cortex-M images loaded into the target
STM32CUBEPROG_BIN_ARCH_EXCLUDE = /opt/stm32cubeprog/bin/FlashLoader /opt/stm32cubeprog/bin/ExternalLoader

define STM32CUBEPROG_EXTRACT_CMDS
	cd $(@D) && unzip -o -q $(STM32CUBEPROG_DL_DIR)/$(STM32CUBEPROG_SOURCE) \
		&& ar x stm32cubeprogrammer_$(STM32CUBEPROG_VERSION)_arm64.deb data.tar.zst \
		&& mkdir -p data && $(HOST_DIR)/bin/zstd -dc data.tar.zst | tar -x -C data
endef

# The bundled libusb-1.0.so needs libudev and is not used anyway: the CLI
# links against libusb-1.0.so.0, which comes from the libusb package.
define STM32CUBEPROG_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/opt/stm32cubeprog
	cp -a $(@D)/data/usr/bin $(@D)/data/usr/lib $(@D)/data/usr/Data_Base $(TARGET_DIR)/opt/stm32cubeprog/
	rm -f $(TARGET_DIR)/opt/stm32cubeprog/lib/libusb-1.0.so
	ln -sf /opt/stm32cubeprog/bin/STM32_Programmer_CLI $(TARGET_DIR)/usr/bin/STM32_Programmer_CLI
endef

$(eval $(generic-package))
