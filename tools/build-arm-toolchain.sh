#!/bin/bash
# Build a minimal bare-metal arm-none-eabi toolchain (C only + libgcc, Cortex-M
# multilibs) into armgcc/install. Only needed if no arm-none-eabi-gcc is
# installed (Debian/Ubuntu: apt install gcc-arm-none-eabi).
set -e
TOP=$(cd "$(dirname "$0")/.." && pwd)
SRC=$TOP/armgcc/src
PREFIX=$TOP/armgcc/install
GNU=https://ftpmirror.gnu.org
mkdir -p "$SRC" && cd "$SRC"

fetch() { [ -f "$(basename "$1")" ] || curl -fL --retry 5 -O "$1"; }
fetch $GNU/binutils/binutils-2.44.tar.xz
fetch $GNU/gcc/gcc-14.3.0/gcc-14.3.0.tar.xz
fetch $GNU/gmp/gmp-6.3.0.tar.xz
fetch $GNU/mpfr/mpfr-4.2.2.tar.xz
fetch $GNU/mpc/mpc-1.3.1.tar.gz

[ -d binutils-2.44 ] || tar xf binutils-2.44.tar.xz
if [ ! -d gcc-14.3.0 ]; then
	tar xf gcc-14.3.0.tar.xz
	tar xf gmp-6.3.0.tar.xz  && mv gmp-6.3.0  gcc-14.3.0/gmp
	tar xf mpfr-4.2.2.tar.xz && mv mpfr-4.2.2 gcc-14.3.0/mpfr
	tar xf mpc-1.3.1.tar.gz  && mv mpc-1.3.1  gcc-14.3.0/mpc
fi

mkdir -p b-binutils b-gcc
cd b-binutils
../binutils-2.44/configure --target=arm-none-eabi --prefix="$PREFIX" --disable-nls --disable-werror --disable-gdb --disable-sim --disable-gprofng
make -j"$(nproc)" && make install
cd ../b-gcc
export PATH=$PREFIX/bin:$PATH
../gcc-14.3.0/configure --target=arm-none-eabi --prefix="$PREFIX" --enable-languages=c --without-headers \
	--with-multilib-list=rmprofile --disable-nls --disable-shared --disable-threads --disable-libssp \
	--disable-libquadmath --disable-libgomp --disable-libatomic --with-newlib --disable-libstdcxx
make -j"$(nproc)" all-gcc all-target-libgcc && make install-gcc install-target-libgcc
"$PREFIX/bin/arm-none-eabi-gcc" --version | head -1
