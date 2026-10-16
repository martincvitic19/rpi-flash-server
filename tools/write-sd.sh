#!/bin/bash
# tools/write-sd.sh [/dev/sdX] -- write output/images/sdcard.img to an SD card
set -e
IMG=$(cd "$(dirname "$0")/.." && pwd)/output/images/sdcard.img
DEV=$1
if [ -z "$DEV" ]; then
	echo "Removable disks:"; lsblk -d -o NAME,SIZE,TRAN,MODEL,RM | awk 'NR==1 || $NF==1'
	echo "usage: $0 /dev/sdX"; exit 1
fi
[ -b "$DEV" ] || { echo "$DEV is not a block device"; exit 1; }
[ "$(lsblk -dno RM "$DEV")" = 1 ] || [ "$(lsblk -dno TRAN "$DEV")" = usb ] || { echo "$DEV is not removable/USB, refusing"; exit 1; }
lsblk "$DEV"
read -r -p "Overwrite ALL data on $DEV? type yes: " a; [ "$a" = yes ] || exit 1
for p in $(lsblk -lno PATH "$DEV" | tail -n +2); do sudo umount "$p" 2>/dev/null || true; done
sudo dd if="$IMG" of="$DEV" bs=4M conv=fsync status=progress
sync; echo "Done. Put the card into the Raspberry Pi and power it on."
