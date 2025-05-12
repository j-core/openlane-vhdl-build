#!/bin/bash

PREFIX=/opt/toolflows
mkdir $PREFIX

export PATH=$PREFIX/bin:$PATH

prlimit -p $$ --nofile=65536:65536

echo clone pdk

git clone --recursive https://github.com/RTimothyEdwards/open_pdks.git

echo build pdk

cd open_pdks

./configure --prefix=$PREFIX --with-sky130-variants=A --enable-sky130-pdk

echo "make first time..."
make
echo "make 2nd time because https://github.com/RTimothyEdwards/open_pdks/issues/315"
make
make install

echo SOURCES timestamp
touch $PREFIX/share/pdk/sky130A/SOURCES

echo tlef link for DFFRAM
ln -s $PREFIX/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef \
      $PREFIX/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd.tlef

cd ..
