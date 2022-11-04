#!/bin/sh

echo Building J-Core toolchains
./01-toolchains.sh || exit 1

echo Building Synthesis tools
./02-ygni.sh &&
./03-magic.sh || exit 1

echo Building Sky130 Open PDK
./04-open_pdk.sh || exit 1

#(cd / ; tar -jxvf /root/server/sky130_pdk-20220428.tar.bz2 )

echo Building KLayout
./05-klayout.sh || exit 1

echo Building OpenROAD and OpenLane
./10-openroad.sh &&
./11-openlane.sh || exit 1

echo Building simulator tools
./12-ngspice.sh &&
./13-irsim.sh &&
./14-iverilog.sh || exit 1

echo Done.
