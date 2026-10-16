# STM32 parallel flasher — Raspberry Pi 4

A small Buildroot Linux image for the **Raspberry Pi 4 Model B** that flashes
several STM32 boards **at the same time** with one command, `flash-all`, using
**STM32CubeProgrammer** over **ST-LINK** and/or **SEGGER J-Link** probes.

As a demo it ships a "breathing LED" blinky for each supported board, so after
one `flash-all` every board's LED fades in and out with the same rhythm.

Tested with one board per USB port:

| Board | MCU | Device ID | LED | Binary |
|---|---|---|---|---|
| STM32F407G-DISC1 (F4 Discovery) | STM32F407VG | 0x413 | LD4 green, PD12 (TIM4_CH1) | `blinky_f407disco.bin` |
| STM32F3DISCOVERY | STM32F303VC | 0x422 | LD7 green, PE11 (TIM1_CH2) | `blinky_f3disco.bin` |
| NUCLEO-L476RG | STM32L476RG | 0x415 | LD2 green, PA5 (TIM2_CH1) | `blinky_l4nucleo64.bin` |
| NUCLEO-C031C6 | STM32C031C6 | 0x453 | LD4 green, PA5 (TIM3) | `blinky_c0nucleo.bin` |

`flash-all` also maps these, but they are untested:
- STM32L45x/L46x Nucleo-64 boards (0x462).
- L41x/L42x and L43x/L44x (0x464, 0x435), assuming a Nucleo-32 board with
  its LED on PB3.
- Other C0 parts (0x493, 0x44C, 0x44D).

---

## Contents

1. [Quick start (prebuilt image)](#1-quick-start-prebuilt-image)
2. [Using `flash-all`](#2-using-flash-all)
3. [Access and network](#3-access-and-network)
4. [What is in the image](#4-what-is-in-the-image)
5. [How flashing works](#5-how-flashing-works)
6. [The blinky firmware](#6-the-blinky-firmware)
7. [Building from source](#7-building-from-source)
8. [Making a release](#8-making-a-release)
9. [Repository layout](#9-repository-layout)
10. [Licenses](#10-licenses)
11. [Troubleshooting](#11-troubleshooting)

---

## 1. Quick start (prebuilt image)

1. Download `stm32flasher-rpi4-sdcard.img.xz` from the
   [Releases](../../releases) page. Optionally check it against `SHA256SUMS`.
2. Write it to a micro-SD card (≥ 2 GB):
   ```sh
   xz -dc stm32flasher-rpi4-sdcard.img.xz | sudo dd of=/dev/sdX bs=4M conv=fsync status=progress
   ```
   (or use Raspberry Pi Imager / balenaEtcher with the `.img.xz`).
3. Plug the boards' ST-LINK / J-Link USB ports into the Pi. Connect the Pi's
   Ethernet port to your PC (directly or through a USB-Ethernet adapter) and
   power it on.
4. Log in, either with an HDMI monitor + keyboard or over SSH:
   ```sh
   ssh root@192.168.8.1          # password: stm32
   ```
5. Run:
   ```sh
   flash-all
   ```

---

## 2. Using `flash-all`

```
flash-all              all probes (ST-LINK + J-Link)
flash-all -p stlink    only ST-LINK probes
flash-all -p jlink     only J-Link probes
flash-all -l           only list probes, detected MCUs and the binary that would be used
flash-all -b DIR       take the binaries from DIR
                       (/usr/share/stm32-blinky-2x = twice the blink frequency)
flash-all -h           help
```

Example run:

```
[stlink 066CFF494877514867173517] 0x422 STM32F303xB/C (F3 Discovery, LD7 green PE11) -> blinky_f3disco.bin
[stlink 066EFF35314B4E3043195329] 0x453 STM32C0 (Nucleo, LED PA5) -> blinky_c0nucleo.bin
[stlink 066BFF575377524867071643] 0x413 STM32F405/407 (F4 Discovery, LD4 green PD12) -> blinky_f407disco.bin
[stlink 066EFF3234584D3043012451] 0x415 STM32L47x/L48x (Nucleo-64, LD2 PA5) -> blinky_l4nucleo64.bin
Flashing 4 board(s) in parallel...
[f3disco] Memory Programming ...
[c0nucleo] Download verified successfully
...
===== summary =====
f407disco    stlink  066BFF575377524867071643   OK
f3disco      stlink  066CFF494877514867173517   OK
l4nucleo64   stlink  066EFF3234584D3043012451   OK
c0nucleo     stlink  066EFF35314B4E3043195329   OK
```

The exit code is non-zero if any board failed. Per-board logs of the last run
are in `/tmp/flash-all/<serial>.log`.

**Your own firmware:** put one `.bin` per board, named like the files in
`/usr/share/stm32-blinky/`, into a directory and run `flash-all -b <dir>`. To
flash a single board by hand:

```sh
STM32_Programmer_CLI -l                                     # list all probes
STM32_Programmer_CLI -c port=SWD sn=<ST-LINK SN> mode=UR -d app.bin 0x08000000 -v -rst
STM32_Programmer_CLI -c port=JLINK sn=<J-Link SN>        -d app.bin 0x08000000 -v -rst
```

Copy files to the Pi with `ssh` (the image has no `sftp-server`, so `scp` does not work):

```sh
tar cf - -C mybins . | ssh root@192.168.8.1 'mkdir -p /tmp/bins && tar xf - -C /tmp/bins'
ssh root@192.168.8.1 flash-all -b /tmp/bins
```

---

## 3. Access and network

| What | Value |
|---|---|
| Address | `192.168.8.1` on the Pi's Ethernet port |
| root | password `stm32` (SSH and HDMI console tty1) |
| user `stm32` | password `stm32`, may use the probes too |
| SSH keys | baked in only if you build the image yourself with `keys/authorized_keys` (see [§7](#7-building-from-source)) |

How the Pi configures `eth0` at boot:
- **Cabled straight to a PC:** the Pi uses `192.168.8.1/24` and runs a small
  DHCP server (192.168.8.100–150). The server hands out **no gateway and no
  DNS**, so the PC keeps its normal internet connection.
- **Plugged into a LAN with a DHCP server:** the Pi takes a lease from it and
  keeps `192.168.8.1` as a second address, without running its own DHCP server.

PC side (NetworkManager): you can simply use DHCP. A profile that can never
steal your default route or DNS, even if a different DHCP server shows up, is:

```sh
nmcli connection add type ethernet con-name rpi-link ifname <usb-eth-iface> \
  ipv4.method manual ipv4.addresses 192.168.8.2/24 ipv4.never-default yes \
  ipv4.ignore-auto-dns yes ipv6.method link-local
```

---

## 4. What is in the image

It is a normal (small) Linux system with a shell. The usual commands come from
BusyBox: `ls`, `cat`, `ps`, `top`, `vi`, `dmesg`, `lsusb`, `ip`, … After login
you get a prompt like `root@stm32flasher:~#` and a short command overview. The
home directory `/root` contains just this README.

| Part | Details |
|---|---|
| Boot | Raspberry Pi GPU firmware `start4.elf` / `fixup4.dat` (pinned commit), boots the kernel directly |
| Kernel | mainline Linux 6.12.94, arm64 `defconfig`, Pi 4 USB/PCIe/Ethernet built in |
| Userspace | glibc 2.42, BusyBox (init, mdev, shell), dropbear SSH |
| STM32CubeProgrammer | v2.23.0 Linux ARM64 **CLI** (`STM32_Programmer_CLI`) in `/opt/stm32cubeprog`. ST ships no GUI for ARM; the bundled Qt6 libraries are non-GUI modules the CLI uses internally |
| Probe support | ST-LINK/V2, V2-1, V3 (ST driver) and SEGGER J-Link (`libjlinkarm.so` from the ST package) |
| Binaries | `/usr/share/stm32-blinky/` (2 s breathing period), `/usr/share/stm32-blinky-2x/` (1 s) |
| Flash script | `/usr/bin/flash-all` |

---

## 5. How flashing works

`flash-all` (`br2-stm32flasher/board/rpi4/overlay/usr/bin/flash-all`, POSIX sh):

1. **Find probes.** `STM32_Programmer_CLI -l stlink-only` and `-l jlink-only`
   list every probe and its serial number.
2. **Identify each target.** For each probe it connects over SWD and reads the
   MCU **device ID**, e.g. `0x413` = STM32F407.
3. **Pick the binary** for that device ID. An unknown ID is skipped.
4. **Flash everything in parallel.** One STM32CubeProgrammer process per board
   writes the binary to `0x08000000`, verifies it and resets the MCU. Every
   process opens only its own probe (`sn=…`).
5. **Show progress live.** All logs are streamed with a `[board]` prefix, and a
   summary prints OK/FAILED per board.

Flashing four small binaries takes under 2 seconds.

---

## 6. The blinky firmware

`firmware/blinky.c` is one bare-metal source file for all boards, with no HAL.
The binaries are 250–640 bytes.

- PWM carrier: 1 kHz (timer clock 1 MHz, reload value 1000).
- A 1 ms SysTick moves the duty cycle up and down along a quadratic ramp, so
  the fade looks smooth. `PERIOD_MS` sets the full breathing cycle: 2000 by
  default, 1000 for the 2× set.
- Every board runs on its reset-default clock: HSI 16 MHz (F4), HSI 8 MHz (F3),
  MSI 4 MHz (L4), HSISYS 12 MHz (C0). SysTick and the prescaler are derived from
  that clock, so the timing is identical everywhere.
- F4, F3 and L4 drive the LED pin with hardware timer PWM (alternate function).
  On the C0 the timer generates the PWM, but the program toggles the pin from
  the timer's update/compare flags.

```sh
make firmware                                   # both sets
make -C firmware PERIOD_MS=500 OUT=out-4x       # any other period
```

To add a board: add a `BOARD_*` block in `blinky.c` (clock, GPIO, timer), an
entry in `firmware/Makefile`, and its device ID in `board_for_id()` in `flash-all`.

---

## 7. Building from source

### Requirements

- Linux x86-64 PC, ~15 GB free disk, a few GB RAM. The first build takes about
  1 h on 6 cores.
- Buildroot host packages. On Debian/Ubuntu:
  ```sh
  sudo apt install build-essential git rsync bc cpio unzip file wget curl python3 \
       libncurses-dev xz-utils gcc-arm-none-eabi
  ```
  `gcc-arm-none-eabi` builds the blinky firmware. If it is not installed,
  `make` runs `tools/build-arm-toolchain.sh` automatically. That builds a
  toolchain into `armgcc/` (about 15 min, once).
- **STM32CubeProgrammer 2.23.0 for Linux ARM64.** ST's download needs a free
  myST login, so it is not fetched automatically. Download *STM32CubeProgrammer
  — Linux ARM64* from
  <https://www.st.com/en/development-tools/stm32cubeprog.html> and save it as:
  ```
  dl/cubeprog/stm32cubeprogrammer_2.23.0_arm64.deb.zip
  ```
  Its SHA-256 is checked against `br2-stm32flasher/package/stm32cubeprog/stm32cubeprog.hash`.

### Build

```sh
git clone <this repo> stm32flasher && cd stm32flasher
mkdir -p dl/cubeprog && cp ~/Downloads/stm32cubeprogrammer_2.23.0_arm64.deb.zip dl/cubeprog/
# optional: SSH public keys for root and the stm32 user
mkdir -p keys && cat ~/.ssh/id_ed25519.pub > keys/authorized_keys
make
```

`make` downloads Buildroot (2026.02.3 LTS), builds the firmware and then the
image: `output/images/sdcard.img`.

| Target | What it does |
|---|---|
| `make` | firmware + image |
| `make firmware` | only the blinky binaries |
| `make menuconfig` | Buildroot configuration; then `make savedefconfig` to store it |
| `make release` | `release/stm32flasher-rpi4-sdcard.img.xz` + `SHA256SUMS` |
| `make clean` / `make distclean` | remove build output / also Buildroot and the local toolchain |

After changing only `flash-all`, the overlay or the firmware, `make` takes
about a minute. If `LD_LIBRARY_PATH` is set in your shell, the Makefile clears
it, because Buildroot refuses to run with it.

### Write the SD card

```sh
tools/write-sd.sh            # lists removable disks
tools/write-sd.sh /dev/sdX   # writes output/images/sdcard.img (asks for "yes" and sudo)
```

---

## 8. Making a release

1. Build without personal keys: move `keys/` away, so that the release image
   only has password login.
2. `make release`. It creates `release/stm32flasher-rpi4-sdcard.img.xz` and
   `release/SHA256SUMS`.
3. Tag and publish, e.g. with the GitHub CLI:
   ```sh
   git tag -a v1.0 -m "v1.0" && git push origin v1.0
   gh release create v1.0 release/stm32flasher-rpi4-sdcard.img.xz release/SHA256SUMS \
      --title "v1.0" --notes "Prebuilt Raspberry Pi 4 image, see README §1"
   ```
4. Read [§10](#10-licenses) first: the image contains STM32CubeProgrammer.

---

## 9. Repository layout

```
Makefile                       top-level build (download Buildroot, firmware, image, release)
br2-stm32flasher/              Buildroot BR2_EXTERNAL tree
  configs/rpi4_stm32flasher_defconfig
  board/rpi4/
    config.txt, cmdline.txt    Pi boot configuration
    genimage.cfg               SD card layout (FAT boot + ext4 root)
    linux.fragment             kernel options built in (PCIe, USB, Ethernet, ...)
    post-build.sh              installs binaries, README, optional SSH keys
    post-image.sh              assembles sdcard.img
    users.txt                  extra user "stm32"
    overlay/                   files copied into the root filesystem:
      usr/bin/flash-all          the flash script
      etc/init.d/S41eth0         network setup (static 192.168.8.1 + DHCP server)
      etc/udhcpd.conf, etc/mdev.conf, etc/profile.d/flasher.sh
  package/rpi4-bootfw/         Pi 4 GPU firmware, pinned commit + hashes
  package/stm32cubeprog/       installs ST's .deb into /opt/stm32cubeprog
firmware/                      blinky.c + Makefile
tools/
  build-arm-toolchain.sh       builds arm-none-eabi-gcc if none is installed
  write-sd.sh                  writes the image to an SD card
```

Not in git (`.gitignore`): `dl/`, `output/`, `buildroot-*/`, `armgcc/`,
`firmware/out*/`, `release/`, `keys/`.

---

## 10. Licenses

- The code in this repository (Buildroot external tree, scripts, firmware) is
  your project's license (add a `LICENSE` file).
- Buildroot, Linux, BusyBox, glibc and dropbear keep their own licenses.
  `make -C output legal-info` collects them.
- **STM32CubeProgrammer** is © STMicroelectronics under license **SLA0048**.
  Binary redistribution is allowed only under its conditions: reproduce the
  copyright notice and license, and use it only with ST devices. It also
  bundles third-party parts such as the SEGGER J-Link library, with their own
  terms. The `.deb` itself is not committed to this repository. If you publish
  a prebuilt image, include SLA0048 with the release (it is in
  `/opt/stm32cubeprog/bin/doc/` in the image) and check the terms yourself.
- The Raspberry Pi boot firmware is Broadcom's redistributable binary.

---

## 11. Troubleshooting

| Symptom | Fix |
|---|---|
| `ssh: No route to host` | wait ~20 s after power-on; give the PC an address in 192.168.8.0/24 (DHCP or static) |
| `Host key verification failed` | the card was re-flashed: `ssh-keygen -R 192.168.8.1` |
| a board shows `unknown or unreachable target` | check USB cable and jumpers (Nucleo: both CN2 jumpers on), then `flash-all -l` |
| a board is found but its LED does nothing | device ID not mapped to the right board/LED: see §6 "To add a board" |
| `No ST-LINK/J-Link probes found` | `lsusb` on the Pi must show `0483:374x` (ST-LINK) or `1366:xxxx` (J-Link) |
| Buildroot: "current working directory in LD_LIBRARY_PATH" | use the top-level `make`, which clears it |
