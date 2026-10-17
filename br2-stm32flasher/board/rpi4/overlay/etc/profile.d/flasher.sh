export PATH=$PATH:/opt/stm32cubeprog/bin
export PS1='\u@\h:\w\$ '
cat <<'MSG'

  STM32 flasher (Raspberry Pi 4) - BusyBox shell: ls, cat, ps, top, vi, dmesg, lsusb, ...

    STM32_Programmer_CLI -l                                           list probes + serials
    STM32_Programmer_CLI -c port=SWD sn=<SN> mode=UR                  connect, show MCU
    STM32_Programmer_CLI -c port=SWD sn=<SN> mode=UR -d fw/app.bin 0x08000000 -v -rst
    STM32_Programmer_CLI -c port=SWD sn=<SN> mode=UR -d fw/app.elf -v -rst

    flash-all                  flash every attached board in parallel from ~/fw (<board>.bin, <serial>.elf, ...)
    flash-all -l               list probes, MCUs and the image each would get
    flash-all -h               all options

  Upload from a PC: scp -O app.bin root@192.168.8.1:fw/      Docs: ~/README.md

MSG
