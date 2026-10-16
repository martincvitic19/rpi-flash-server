#!/bin/sh
# Install the blinky binaries and (optionally) SSH public keys into the target
set -e
BOARD_DIR="$(dirname "$0")"
TOP="$BOARD_DIR/../../.."

for set in "" "-2x"; do
	src="$TOP/firmware/out$set"
	ls "$src"/*.bin >/dev/null 2>&1 || { echo "post-build: no binaries in $src, run 'make firmware' first" >&2; exit 1; }
	mkdir -p "$TARGET_DIR/usr/share/stm32-blinky$set"
	cp "$src"/*.bin "$TARGET_DIR/usr/share/stm32-blinky$set/"
done

# keys/authorized_keys is not in git; without it only password login works
rm -rf "$TARGET_DIR/root/.ssh" "$TARGET_DIR/home/stm32/.ssh"
if [ -f "$TOP/keys/authorized_keys" ]; then
	for home in root home/stm32; do
		install -D -m 0600 "$TOP/keys/authorized_keys" "$TARGET_DIR/$home/.ssh/authorized_keys"
		chmod 700 "$TARGET_DIR/$home/.ssh"
	done
fi

install -D -m 0644 "$TOP/README.md" "$TARGET_DIR/root/README.md"
