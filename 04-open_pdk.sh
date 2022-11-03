#!/bin/bash

PREFIX=/opt/toolflows

export PATH=$PATH:$PREFIX/bin

echo clone pdk

git clone https://github.com/RTimothyEdwards/open_pdks.git

echo build pdk

cd open_pdks

ulimit -Hn 65536
ulimit  -n 65536
./configure --prefix=$PREFIX --with-sky130-variants=A --enable-sky130-pdk

make
make install

echo SOURCES timestamp
touch /opt/toolflows/share/pdk/sky130A/SOURCES

echo tlef link for DFFRAM
ln -s /opt/toolflows/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef \
      /opt/toolflows/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd.tlef

cd ..
