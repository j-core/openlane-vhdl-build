#!/bin/sh

PREFIX=/opt/toolflows

echo clone magic

cd src
git clone https://github.com/RTimothyEdwards/magic.git

cd ../build

echo build magic

git clone ../src/magic

cd magic
#echo Updating to known working version...
#git checkout 9402b0dcddebcdc71af7043de3db5be8a3186e65

CFLAGS="-Wno-implicit-function-declaration -Wno-error" ./configure --prefix=$PREFIX
make -j8
make install

cd ..
