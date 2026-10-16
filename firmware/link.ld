MEMORY { FLASH (rx) : ORIGIN = 0x08000000, LENGTH = 16K  RAM (rwx) : ORIGIN = 0x20000000, LENGTH = 6K }
_estack = ORIGIN(RAM) + LENGTH(RAM);
SECTIONS {
  .text : { KEEP(*(.isr_vector)) *(.text*) *(.rodata*) } > FLASH
  .bss (NOLOAD) : { _sbss = .; *(.bss*) *(COMMON) . = ALIGN(4); _ebss = .; } > RAM
}
