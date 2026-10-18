# Top-level build for the STM32 parallel flasher image (Raspberry Pi 4).
#
#   make            Buildroot image -> output/images/sdcard.img (+ .bmap)
#   make menuconfig Buildroot menuconfig on the project config
#   make release    compressed image + bmap + checksums in release/
#   make clean      remove Buildroot output and release/

BR_VERSION   := 2026.02.3
BR_DIR       := buildroot-$(BR_VERSION)
BR_TARBALL   := dl/buildroot-$(BR_VERSION).tar.xz
CUBEPROG_ZIP := dl/cubeprog/stm32cubeprogrammer_2.23.0_arm64.deb.zip
CUBEPROG_HASH := br2-stm32flasher/package/stm32cubeprog/stm32cubeprog.hash
DEFCONFIG    := rpi4_stm32flasher_defconfig

# Buildroot refuses to run with a LD_LIBRARY_PATH containing "." or an empty entry
BR_MAKE := env -u LD_LIBRARY_PATH $(MAKE) -C $(CURDIR)/output

.PHONY: all image check-cubeprog menuconfig savedefconfig release clean distclean

all: image

$(BR_TARBALL):
	mkdir -p dl
	curl -fL --retry 5 -o $@ https://buildroot.org/downloads/buildroot-$(BR_VERSION).tar.xz

$(BR_DIR)/Makefile: $(BR_TARBALL)
	tar xf $<
	touch $@

$(CUBEPROG_ZIP):
	@echo "Missing $@"
	@echo "Download 'STM32CubeProgrammer 2.23.0 - Linux ARM64' from"
	@echo "https://www.st.com/en/development-tools/stm32cubeprog.html (needs a free myST login)"
	@echo "and save it as $@"
	@false

# Same hash Buildroot checks, but before an hour of building instead of after
check-cubeprog: $(CUBEPROG_ZIP)
	@want=$$(awk '$$1 == "sha256" { print $$2 }' $(CUBEPROG_HASH)); \
	got=$$(sha256sum $< | cut -d' ' -f1); \
	[ "$$want" = "$$got" ] || { \
		echo "$< has the wrong SHA-256 ($$(stat -c %s $<) bytes):"; \
		echo "  expected $$want"; \
		echo "  got      $$got"; \
		echo "Incomplete download or another version; download it again from ST."; \
		false; }

output/.config: $(BR_DIR)/Makefile br2-stm32flasher/configs/$(DEFCONFIG)
	env -u LD_LIBRARY_PATH $(MAKE) -C $(BR_DIR) BR2_EXTERNAL=$(CURDIR)/br2-stm32flasher O=$(CURDIR)/output $(DEFCONFIG)

image: check-cubeprog output/.config
	$(BR_MAKE)
	@echo; echo "Image: output/images/sdcard.img (+ .bmap), write it with: sudo bmaptool copy output/images/sdcard.img /dev/sdX"

menuconfig: output/.config
	$(BR_MAKE) menuconfig

savedefconfig: output/.config
	$(BR_MAKE) savedefconfig BR2_DEFCONFIG=$(CURDIR)/br2-stm32flasher/configs/$(DEFCONFIG)

release: image
	mkdir -p release
	xz -T0 -9 -k -c output/images/sdcard.img > release/stm32flasher-rpi4-sdcard.img.xz
	cp output/images/sdcard.img.bmap release/stm32flasher-rpi4-sdcard.img.bmap
	cd release && sha256sum stm32flasher-rpi4-sdcard.img.xz stm32flasher-rpi4-sdcard.img.bmap > SHA256SUMS
	@ls -la release

clean:
	rm -rf output release

distclean: clean
	rm -rf $(BR_DIR)
