export PATH=$PATH:/opt/stm32cubeprog/bin
export PS1='\u@\h:\w\$ '
cat <<'MSG'

  STM32 parallel flasher (Raspberry Pi 4) - normal Linux shell (BusyBox: ls, cat, ps, top, vi, dmesg, lsusb, ...)

    flash-all                                 flash every attached board in parallel (ST-LINK + J-Link)
    flash-all -p stlink | -p jlink            only one probe type
    flash-all -b /usr/share/stm32-blinky-2x   twice the blink frequency
    flash-all -l                              only list probes and detected MCUs
    flash-all -b ~/fw                         your own images uploaded to ~/fw (<board>.elf|hex|bin)
    flash-all -f app.elf -t f407disco         one file on every board of a type (or -s SERIAL)
    flash-all -h                              all options; boards: f407disco f3disco l4nucleo64 l4nucleo32 c0nucleo
    STM32_Programmer_CLI -l                   list probes manually

  Binaries: /usr/share/stm32-blinky*/   Docs: ~/README.md   Logs of last run: /tmp/flash-all-<uid>/
  Upload from a PC: scp app.elf stm32flasher:fw/f407disco.elf   (or tools/flash-remote.sh in the repo)

MSG
