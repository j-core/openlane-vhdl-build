#!/bin/sh

: ${PREFIX:=/opt/toolflows}
export PREFIX

echo clone magic

cd src &&
git clone https://github.com/RTimothyEdwards/magic.git &&

cd ../build &&

echo build magic &&

git clone ../src/magic &&

cd magic &&
echo Updating to known working version... &&
git checkout 6b9efefc02ff3194b9d2ae30d28eaf700ed46af4 || exit 1

CFLAGS="-Wno-implicit-function-declaration -Wno-error -std=c11" ./configure --prefix=$PREFIX &&
make -j$(nproc) &&
make install &&

cd .. || exit 1
