#!/bin/sh

export PREFIX=/opt/toolflows

cd src
git clone https://github.com/RTimothyEdwards/irsim.git

cd ../build

git clone ../src/irsim
cd irsim
./configure --prefix=$PREFIX

make -j8

make install

cd ../..

echo Done.
