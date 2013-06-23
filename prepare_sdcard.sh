#! /usr/bin/env sh

set -x
set -e

#############
# VARIABLES #
#############

# Including users defined variables
. ./makefile.vars

############
# FUNCTION #
############

format_sdcard()
{
    if [ -n "$SDCARD_DEVICE" ]
    then
	dd if=/dev/zero of=$SDCARD_DEVICE bs=1k count=1025
    fi
# MUST use something like fdisk to format the SDCARD
    # sfdisk
}

########

copy2sdcard()
{
# copy boot binaries to the sdcard
    if [ -n "$SDCARD_DEVICE" ] # Should match a device regexp or something like that.
    then
	cd u-boot-sunxi
	sudo dd if=spl/sunxi-spl.bin of=$SDCARD_DEVICE bs=1024 seek=8
	sudo dd if=u-boot.bin of=$SDCARD_DEVICE bs=1024 seek=32
	cd ..

# copy root_fs to the sdcard
	sudo mount "$SDCARD_DEVICE"1 /mnt
	cd chroot-armhf
	sudo bash -c "tar --exclude=qemu-arm-static -cf - . | tar -C /mnt -xvf -"
	cd ..
	sudo umount /mnt

    fi
}

########
# MAIN #
########

case "$1" in
    all)
	format_sdcard
	copy2sdcard
	;;
    format)
	format_sdcard
	;;
    copy2sdcard)
	copy2sdcard
	;;
    *)
	echo "Usage: prepare_sdcard.sh {all|format|copy2sdcard}"
	exit 1
esac

exit 0

########
