#!/bin/sh
# Put config.txt/cmdline.txt next to the kernel and boot firmware, assemble sdcard.img
set -e
BOARD_DIR="$(dirname "$0")"
cp "$BOARD_DIR/config.txt" "$BOARD_DIR/cmdline.txt" "$BINARIES_DIR/"
support/scripts/genimage.sh -c "$BOARD_DIR/genimage.cfg"
# block map, so bmaptool writes only the used blocks to the SD card
"$HOST_DIR/bin/bmaptool" create -o "$BINARIES_DIR/sdcard.img.bmap" "$BINARIES_DIR/sdcard.img"
