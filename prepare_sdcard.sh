#! /usr/bin/env sh

SDCARD_DEVICE=

# copy boot binaries to the sdcard

if [ -n "$SDCARD_DEVICE" ]
then
    dd if=/dev/zero of=$SDCARD_DEVICE bs=1k count=1025

    cd u-boot-sunxi
    dd if=spl/sunxi-spl.bin of=$SDCARD_DEVICE bs=1024 seek=8
    dd if=u-boot.bin of=$SDCARD_DEVICE bs=1024 seek=32

# copy root_fs to the sdcard

    sudo mount "$SDCARD_DEVICE"1 /mnt
    cd chroot-armhf
    tar --exclude=qemu-arm-static -cf - . | tar -C /mnt -xvf -

fi
