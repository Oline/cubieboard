#! /usr/bin/env sh

set -x
set -e

#############
# VARIABLES #
#############

HOSTNAME=A10
PACKAGES="emacs23-nox"
LINUX_DIR=../linux-stable/

########
# MAIN #
########

# create the chroot
mkdir -p chroot-armhf
cd chroot-armhf
#sudo /usr/sbin/debootstrap --foreign --arch armhf wheezy .

# that command is usefull to run target host binaries (ARM) on the build host  (x86)
sudo cp /usr/bin/qemu-arm-static usr/bin

# if you use grsecurity on build host, you should uncomment that line
#sudo /sbin/paxctl -cm usr/bin/qemu-arm-static
#sudo /sbin/paxctl -cpexrms usr/bin/qemu-arm-static

# debootstrap second stage and packages configuration
#sudo LC_ALL=C LANGUAGE=C LANG=C chroot . /debootstrap/debootstrap --second-stage
sudo LC_ALL=C LANGUAGE=C LANG=C chroot . dpkg --configure -a

# set root password
echo -n "Please enter the root password: "
sudo chroot . passwd

# set hostname
echo -n "Please enter the hostname of the host: "
read HOSTNAME
echo $HOSTNAME > etc/hostname | sudo bash

# tmp stuff
sudo cp /etc/resolv.conf etc

# updating root_fs
sudo bash -c "echo deb http://http.debian.net/debian/ wheezy main contrib non-free > etc/apt/sources.list"
sudo bash -c "echo deb http://security.debian.org/ wheezy/updates main contrib non-free >> etc/apt/sources.list"
sudo chroot . apt-get update
sudo chroot . apt-get upgrade

# install additionnals packages
sudo chroot . apt-get install "$PACKAGES"

# removing tmp stuff
sudo rm etc/resolv.conf

# add serial console to connect to the system
sudo bash -c 'echo "T0:2345:respawn:/sbin/getty -L ttyS0 115200 vt100" >> etc/inittab'

# copy linux image to the root_fs
sudo cp $LINUX_DIR/arch/arm/boot/uImage boot
make -C $LINUX_DIR INSTALL_MOD_PATH=`pwd` ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- modules_install
