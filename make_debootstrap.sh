#! /usr/bin/env sh

#############
# VARIABLES #
#############

HOSTNAME=A10
PACKAGES="emacs23-nox"
LINUX_DIR=../linux-stable/

########
# MAIN #
########

mkdir -p chroot-armhf
cd chroot-armhf
sudo /usr/sbin/debootstrap --foreign --arch armhf wheezy .
#cp /usr/bin/qemu-arm-static usr/bin
sudo LC_ALL=C LANGUAGE=C LANG=C chroot . /debootstrap/debootstrap --second-stage
sudo LC_ALL=C LANGUAGE=C LANG=C chroot . dpkg --configure -a

# set root password
sudo chroot . passwd

# set hostname
echo "$HOSTNAME" > etc/hostname


cp /etc/resolv.conf etc

echo deb http://http.debian.net/debian/ wheezy main contrib non-free > etc/apt/sources.list
echo deb http://security.debian.org/ wheezy/updates main contrib non-free >> etc/apt/sources.list
sudo chroot . apt-get update
sudo chroot . apt-get upgrade
sudo chroot . apt-get install "$PACKAGES"

rm etc/resolv.conf


echo "T0:2345:respawn:/sbin/getty -L ttyS0 115200 vt100" >> etc/inittab
cp $LINUX_DIR/arch/arm/boot/uImage boot
make -C $LINUX_DIR INSTALL_MOD_PATH=`pwd` ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- modules_install
