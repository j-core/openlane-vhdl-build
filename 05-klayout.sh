#!/bin/sh

mkdir klayout
mkdir /opt/toolflows/share/klayout

cd klayout

git clone https://github.com/KLayout/klayout.git &&
cd klayout &&
git checkout v0.30.2 || exit 1

./build.sh -j12 -prefix /opt/toolflows/share/klayout

ln -s /opt/toolflows/share/klayout/klayout /opt/toolflows/bin

echo Done.

