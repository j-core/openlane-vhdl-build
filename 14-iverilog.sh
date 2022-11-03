#!/bin/sh

export PREFIX=/opt/toolflows

cd src
git clone https://github.com/steveicarus/iverilog.git

cd ../build

git clone ../src/iverilog
cd iverilog
sh autoconf.sh
./configure --prefix=$PREFIX

make -j8

make install

cd ../..

echo Done.
