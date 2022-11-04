#!/bin/bash

[ $UID -ne 0 ] && { echo not root >&2; exit 1; }

debootstrap chimaera newroot http://pkgmaster.devuan.org/merged &&
cat > newroot/init << 'EOF' &&
#!/bin/sh

export HOME=/home PATH=/bin:/sbin:/usr/bin:/usr/sbin

if ! mountpoint -q dev; then
  mount -t devtmpfs dev dev
  mkdir -p dev/shm
  chmod +t /dev/shm
fi
mountpoint -q dev/pts || { mkdir -p dev/pts && mount -t devpts dev/pts dev/pts;}
mountpoint -q proc || mount -t proc proc proc
mountpoint -q sys || mount -t sysfs sys sys
echo 0 99999 > /proc/sys/net/ipv4/ping_group_range

/bin/bash
EOF
chmod +x newroot/init
