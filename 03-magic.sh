#!/bin/sh

PREFIX=/opt/toolflows

echo clone magic

cd src
git clone https://github.com/RTimothyEdwards/magic.git

cd ../build

echo build magic

git clone ../src/magic

cd magic
CFLAGS="-Wno-implicit-function-declaration -Wno-error" ./configure --prefix=$PREFIX
make -j8
make install

cd ..
