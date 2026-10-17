#!/bin/sh
# Install (optional) SSH public keys and the README into the target
set -e
BOARD_DIR="$(dirname "$0")"
TOP="$BOARD_DIR/../../.."

# keys/authorized_keys is not in git; without it only password login works
rm -rf "$TARGET_DIR/root/.ssh" "$TARGET_DIR/home/stm32/.ssh"
if [ -f "$TOP/keys/authorized_keys" ]; then
	for home in root home/stm32; do
		install -D -m 0600 "$TOP/keys/authorized_keys" "$TARGET_DIR/$home/.ssh/authorized_keys"
		chmod 700 "$TARGET_DIR/$home/.ssh"
	done
fi

install -D -m 0644 "$TOP/README.md" "$TARGET_DIR/root/README.md"
