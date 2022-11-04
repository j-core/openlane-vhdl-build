sudo env -i USER=root TERM=linux SHELL=/bin/bash LANG=$LANG PATH=/bin:/sbin:/usr/bin:/usr/sbin unshare -Cimpuf chroot newroot /init
