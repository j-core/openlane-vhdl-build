#!/bin/sh

: ${PREFIX:=/opt/toolflows}
export PREFIX

mkdir -p klayout "$PREFIX"/share/klayout &&
cd klayout &&

git clone https://github.com/KLayout/klayout.git &&
cd klayout &&
git checkout v0.28.7 &&
./build.sh -j$(nproc) -prefix "$PREFIX"/share/klayout &&
ln -s "$PREFIX"/share/klayout/klayout "$PREFIX"/bin || exit 1

echo Done.

