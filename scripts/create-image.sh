#!/bin/bash
set -e

truncate -s 8G /output/pi-image.img

# This setting helps guestfish run reliably in containers
export LIBGUESTFS_BACKEND=direct

# Use guestfish to partition, format, and copy files into the image
guestfish --add /output/pi-image.img <<_EOF_
run
part-init /dev/sda mbr
part-add /dev/sda primary fat32 2048 526335
part-add /dev/sda primary ext4 526336 -1
part-set-bootable /dev/sda 1
mkfs vfat /dev/sda1 label:boot
mkfs ext4 /dev/sda2 label:root
mount /dev/sda2 /
tar-in /rootfs.tar / compress:gzip
mount /dev/sda1 /boot
tar-in /bootfs.tar /boot compress:gzip
_EOF_

echo "Image creation complete with guestfish!"