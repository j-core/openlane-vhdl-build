#!/bin/sh

export PREFIX=/opt/toolflows

cd src
git clone https://git.code.sf.net/p/ngspice/ngspice
( cd ngspice ; ./autogen.sh )

cd ../build
mkdir ../build/ngspice
cd ../build/ngspice

../../src/ngspice/configure --with-x --enable-xspice --enable-cider --with-readline=yes --disable-openmp --disable-debug --prefix=$PREFIX

make -j8

make install

cd ../..

echo Done.
