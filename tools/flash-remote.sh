#!/bin/sh
# Upload firmware images from this PC to the flasher and flash them.
#
#   tools/flash-remote.sh [-H HOST] IMAGE... [-- FLASH-ALL OPTIONS]
#
# IMAGE is BOARD=PATH (stored on the Pi as ~/fw/BOARD.<ext>) or just PATH
# (kept under its own name, e.g. a file already called f3disco.hex or
# <serial>.bin). Formats: .elf .hex .srec .bin. ~/fw on the Pi is replaced on
# every upload, so only the boards you give an image for get flashed.
#
#   tools/flash-remote.sh f407disco=build/app.elf l4nucleo64=nucleo/app.bin
#   tools/flash-remote.sh f3disco=app.hex -- -p jlink
#   tools/flash-remote.sh -H stm32@192.168.8.1 066DFF555185754867064043=app.elf
#
# Boards: f407disco f3disco l4nucleo64 l4nucleo32 c0nucleo
set -e
HOST=stm32flasher
[ "$1" = -H ] && { HOST=$2; shift 2; }
[ $# -gt 0 ] && [ "$1" != -h ] || { sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }

STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT
while [ $# -gt 0 ] && [ "$1" != -- ]; do
	case $1 in
	*=*) name=${1%%=*}; path=${1#*=} ;;
	*)   name=; path=$1 ;;
	esac
	[ -f "$path" ] || { echo "no such file: $path" >&2; exit 1; }
	ext=${path##*.}
	case $ext in elf|hex|srec|bin) ;; *) echo "$path: need .elf, .hex, .srec or .bin" >&2; exit 1 ;; esac
	if [ -n "$name" ]; then cp "$path" "$STAGE/$name.$ext"; else cp "$path" "$STAGE/"; fi
	shift
done
[ "$1" = -- ] && shift

# the Pi has no RTC or network time; give it the PC clock (needs root)
ssh "$HOST" "[ \$(id -u) = 0 ] && date -s @$(date +%s) >/dev/null" || true
echo "uploading to $HOST:~/fw/: $(ls "$STAGE" | tr '\n' ' ')"
tar -C "$STAGE" -cf - . | ssh "$HOST" 'rm -rf ~/fw && mkdir -p ~/fw && tar -xf - -C ~/fw'
ssh -t "$HOST" flash-all -b fw "$@"
