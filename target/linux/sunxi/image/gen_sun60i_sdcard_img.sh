#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-only
set -ex
[ $# -eq 7 ] || {
    echo "SYNTAX: $0 <file> <bootfs image> <rootfs image> <bootfs size> <rootfs size> <boot0> <boot_package>"
    exit 1
}

OUTPUT="$1"
BOOTFS="$2"
ROOTFS="$3"
BOOTFSSIZE="$4"
ROOTFSSIZE="$5"
BOOT0="$6"
BOOTPKG="$7"

head=4
sect=63

# Start partition 1 at 32MB (sector 65536) to leave room for boot_package.fex at 16.4MB
set $(ptgen -o $OUTPUT -h $head -s $sect -l 65536 -t c -p ${BOOTFSSIZE}M -t 83 -p ${ROOTFSSIZE}M)

BOOTOFFSET="$(($1 / 512))"
BOOTSIZE="$(($2 / 512))"
ROOTFSOFFSET="$(($3 / 512))"
ROOTFSSIZE="$(($4 / 512))"

# Write boot0_sdcard.fex at 8K (bs=8k seek=1)
dd bs=8k if="$BOOT0" of="$OUTPUT" seek=1 conv=notrunc status=none
# Write boot_package.fex at 16400K (bs=8k seek=2050)
dd bs=8k if="$BOOTPKG" of="$OUTPUT" seek=2050 conv=notrunc status=none
# Write FAT boot partition and rootfs partition
dd bs=512 if="$BOOTFS" of="$OUTPUT" seek="$BOOTOFFSET" conv=notrunc status=none
dd bs=512 if="$ROOTFS" of="$OUTPUT" seek="$ROOTFSOFFSET" conv=notrunc status=none
