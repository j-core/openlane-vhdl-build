#!/bin/sh

cd /root/build

/root/server/01-toolchains.sh
/root/server/02-ygni.sh
/root/server/03-magic.sh
/root/server/04-open_pdk.sh

#(cd / ; tar -jxvf /root/server/sky130_pdk-20220428.tar.bz2 )

/root/server/05-klayout.sh
/root/server/10-openroad.sh
/root/server/11-openlane.sh
/root/server/14-iverilog.sh
