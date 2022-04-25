#!/bin/sh

export PREFIX=/opt/toolflows

echo making install dir $PREFIX

# mkdir $PREFIX

echo clone all the things...
if [ 1 -eq 1 ]; then
mkdir src; cd src

git clone https://github.com/YosysHQ/icestorm.git
git clone https://github.com/YosysHQ/yosys.git
git clone https://github.com/YosysHQ/nextpnr.git

git clone https://github.com/ghdl/ghdl.git
git clone https://github.com/ghdl/ghdl-yosys-plugin.git

cd ..
fi
echo clone done

echo making build area

mkdir build; cd build

echo build icestorm
if [ 1 -eq 1 ]; then

git clone ../src/icestorm
cd icestorm

patch -p1 <<EOF
--- a/config.mk
+++ b/config.mk
@@ -1,4 +1,4 @@
-PREFIX ?= /usr/local
+PREFIX ?= $PREFIX
 DEBUG ?= 0
 ICEPROG ?= 1
 PROGRAM_PREFIX ?=
EOF

make -j8
make install

cd ..
fi

echo build yosys
if [ 1 -eq 1 ]; then

git clone ../src/yosys
cd yosys

patch -p1 << EOF
diff --git a/Makefile b/Makefile
index 423edc07..51f13cb6 100644
--- a/Makefile
+++ b/Makefile
@@ -1,6 +1,6 @@

-CONFIG := clang
-# CONFIG := gcc
+# CONFIG := clang
+CONFIG := gcc
 # CONFIG := gcc-4.8
 # CONFIG := afl-gcc
 # CONFIG := emcc
@@ -53,7 +53,7 @@ SANITIZER =
 PROGRAM_PREFIX :=

 OS := \$(shell uname -s)
-PREFIX ?= /usr/local
+PREFIX ?= $PREFIX
 INSTALL_SUDO :=

 ifneq (\$(wildcard Makefile.conf),)
EOF

make -j8
make install

cd ..
fi

echo build nextpnr
if [ 1 -eq 1 ]; then

git clone ../src/nextpnr
cd nextpnr

# patch -p1 < ../../nextpnr.diff

cmake . -DARCH="ice40" -DCMAKE_INSTALL_PREFIX=$PREFIX -DICESTORM_INSTALL_PREFIX=$PREFIX -DBUILD_GUI=OFF -DBUILD_PYTHON=OFF -DSTATIC_BUILD=ON
make -j8
make install

cd ..
fi

echo build ghdl
if [ 1 -eq 1 ]; then

git clone ../src/ghdl
cd ghdl 

export PATH=/opt/gnat/bin:$PATH
./configure --prefix=$PREFIX

make -j8
make install

cd ..
fi

echo build ghdl-yosys-plugin
if [ 1 -eq 1 ]; then

git clone ../src/ghdl-yosys-plugin
cd ghdl-yosys-plugin

make clean;
export PATH=$PREFIX/bin:$PATH

make
make install
fi

cd ../../
echo Done.
