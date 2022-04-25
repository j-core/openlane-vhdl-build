#!/bin/sh

# This script needs to be run from the directory where you've just build musl cross make

echo clone musl-cross-make

git clone https://github.com/richfelker/musl-cross-make.git
cd musl-cross-make

echo config

echo "OUTPUT = /opt/toolchains" > config.mak
cat presets/j2-fdpic >> config.mak

echo building sh2-fdpic linux toolchain

make -j8

echo install linux toolchain

make install
cd ..

echo building a bare sh2-elf binutils

mkdir bare-binutils
cd bare-binutils

../musl-cross-make/build/local/sh2eb-linux-muslfdpic/src_binutils/configure --prefix=/opt/toolchains  --enable-deterministic-archives --target=sh2-elf --disable-separate-code --disable-werror
make -j8

echo install bare metal binutils
make install

echo building a bare sh2-elf gcc for C language
mkdir ../bare-gcc
cd ../bare-gcc

#ln -s ../musl-cross-make/gmp-6.1.2 gmp
#ln -s ../musl-cross-make/mpfr-4.0.2 mpfr
#ln -s ../musl-cross-make/mpc-1.1.0 mpc

../musl-cross-make/build/local/sh2eb-linux-muslfdpic/src_gcc/configure --prefix=/opt/toolchains  --target=sh2-elf --disable-bootstrap --disable-assembly --disable-werror --disable-libmudflap --disable-libsanitizer --disable-gnu-indirect-function --disable-libmpx --disable-libmudflap --disable-libstdcxx-pch --disable-ssp --disable-libssp --enable-languages=c --with-newlib --without-headers
make -j8

echo install bare metal compiler
make install

cd ..
