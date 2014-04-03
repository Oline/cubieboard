#! /usr/bin/env sh

#set -x
set -e

#############
# VARIABLES #
#############

# internal values
BUILD_SERIAL=`date "+%Y%m%d%H%M"`
TMP_VAL=$$
LOOP_DEV=/dev/mapper/loop0"$TMP_VAL"

# Including users defined variables
. ./makefile.vars

# user defined values
IMG_SIZE=2048
CONF_SIZE=50
PARTITION_SIZE=$((($IMG_SIZE - $CONF_SIZE) / 2))
FS_TYPE=ext2
IMG_NAME=cubieboard2-"$BUILD_SERIAL"-"$IMG_SIZE".img

############
# FUNCTION #
############

build_image()
{
set -e

if [ ! -e "$IMG_NAME" ]; then
    dd if=/dev/zero of="$IMG_NAME" bs=1M count="$IMG_SIZE"
fi
/sbin/parted -s "$IMG_NAME" mklabel msdos
/sbin/parted -s -a opt "$IMG_NAME" mkpart primary 1 $(($PARTITION_SIZE + 1))
/sbin/parted -s -a opt "$IMG_NAME" mkpart primary $(($PARTITION_SIZE + 2)) $((($PARTITION_SIZE * 2) + 1))
/sbin/parted -s -a opt "$IMG_NAME" mkpart primary $((($PARTITION_SIZE * 2) + 2)) $IMG_SIZE

set +e
sudo /sbin/kpartx -a -v -p "$TMP_VAL" "$IMG_NAME"

if [ -b "$LOOP_DEV"1 ]; then
    /sbin/mkfs."$FS_TYPE" "$LOOP_DEV"1
fi
if [ -b "$LOOP_DEV"2 ]; then
    /sbin/mkfs."$FS_TYPE" "$LOOP_DEV"2
fi
if [ -b "$LOOP_DEV"3 ]; then
    /sbin/mkfs."$FS_TYPE" "$LOOP_DEV"3
fi

sudo /sbin/kpartx -d -p "$TMP_VAL" "$IMG_NAME"
set -e

/sbin/parted "$IMG_NAME" print
}

########

copyboot2image()
{
# copy boot binaries to the image
    # Should match a device regexp or something like that.
    if [ -n "$IMG_NAME" ] ;then
	if [ -f "$IMG_NAME" ]
	then
	    # cd u-boot-sunxi
	    if [ -f u-boot-sunxi/spl/sunxi-spl.bin ]; then
		sudo dd if=u-boot-sunxi/spl/sunxi-spl.bin of="$IMG_NAME" bs=1024 seek=8 conv=nocreat,notrunc
	    else
		echo "You need to build u-boot first"
	    fi
	    if [ -f u-boot-sunxi/u-boot.bin ]; then
		sudo dd if=u-boot-sunxi/u-boot.bin of="$IMG_NAME" bs=1024 seek=32 conv=nocreat,notrunc
	    else
		echo "You need to build u-boot first"
	    fi
	    # cd ..
	else
	    echo "$IMG_NAME does not seem to be a regular image file..."
	fi
    else
	echo "The variable IMG_NAME does not seem to exist..."
    fi
}

########

copyrootfs2image()
{
# copy root_fs to the image
    # Should match a device regexp or something like that.
    set +e
    sudo /sbin/kpartx -a -v -p "$TMP_VAL" "$IMG_NAME"
    if [ -n "$LOOP_DEV"1 ] ;then
	if [ -b "$LOOP_DEV"1 ]
	then
	    sudo mount "$LOOP_DEV"1 /mnt
	    cd "$CHROOT_DIR"
	    sudo bash -c "tar --exclude=qemu-arm-static -cf - . | tar -C /mnt -xvf -"
	    cd ..
	    sudo umount /mnt
	else
	    echo $LOOP_DEV"1 does not seem to be a block device..."
	fi
    else
	echo "The variable LOOP_DEV does not seem to exist..."
    fi
    sudo /sbin/kpartx -d -p "$TMP_VAL" "$IMG_NAME"
    set -e
}

########
# MAIN #
########

case "$1" in
    all)
	build_image
	copyboot2image
	copyrootfs2image
	;;
    build_image)
	build_image
	;;
    copyboot2image)
	copyboot2image
	;;
    copyrootfs2image)
	copyrootfs2image
	;;
    *)
	echo "Usage: prepare_sdcard.sh {all|build_image|copyboot2image|copyrootfs2image}"
	exit 1
esac

exit 0

########
