#! /usr/bin/env sh

# Copyright (c) 2013-2014, Sylvain Leroy <sylvain@unmondelibre.fr>
#                    2014, Jean-Marc Lacroix <jeanmarc.lacroix@free.fr>
#                    2014, Philippe Thierry <phil@reseau-libre.net>

# This file is part of CBoard.

# CBoard is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# CBoard is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with CBoard.  If not, see <http://www.gnu.org/licenses/>.

#set -x
set -e

#############
# VARIABLES #
#############

# Including users defined variables
. ./makefile.vars

############
# FUNCTION #
############

do_debootstrap()
{
    set -x

    sudo http_proxy="$HTTP_PROXY" /usr/sbin/debootstrap --foreign --arch "$DEB_ARCH" "$DEB_SUITE" . "$DEBOOTSTRAP_MIRROR"
# --variant=minbase


# that command is usefull to run target host binaries (ARM) on the build host  (x86)
    sudo cp /usr/bin/qemu-arm-static usr/bin

# if you use grsecurity on build host, you should uncomment that line
#sudo /sbin/paxctl -cm usr/bin/qemu-arm-static
#sudo /sbin/paxctl -cpexrms usr/bin/qemu-arm-static

# debootstrap second stage and packages configuration
    sudo LC_ALL=C LANGUAGE=C LANG=C chroot . /debootstrap/debootstrap --second-stage
    sudo LC_ALL=C LANGUAGE=C LANG=C chroot . dpkg --configure -a

    set +x
}

##########

configure_system()
{
# set root password
    echo "Please enter the root password: "

    if [ -z "$ROOT_PASSWORD" ]; then
    # hiding the root password when typed could be a good idea... (stty)
	read ROOT_PASSWORD
    fi
    sudo bash -c "echo -e root:$ROOT_PASSWORD | chroot . chpasswd"

# this set -x does not appear before previous sudo, not to show the root password on the output.
    set -x

# set hostname
    echo "Please enter the hostname of the host: "

    if [ -z "$HOSTNAME" ]; then
	read HOSTNAME
    fi
    sudo bash -c "echo $HOSTNAME > etc/hostname"

# check if a serial console already exist in the inittab file
# we remove the error check to let grep output an error if the file does not have the line we look for
    set +e
    grep 'T0:2345:respawn:/sbin/getty -L ttyS0 115200 vt100' etc/inittab
    RET_VALUE=$?
    set -e

    if [ 0 -ne "$RET_VALUE" ]; then
# add serial console to connect to the system
    sudo bash -c 'echo "T0:2345:respawn:/sbin/getty -L ttyS0 115200 vt100" >> etc/inittab'
    fi

# disable some local consoles
# sed -i 's/^\([3-6]:.* tty[3-6]\)/#\1/' /etc/inittab

# copy basic templates of configuration files
    sudo cp ../fstab.base etc/fstab
    sudo cp ../interfaces.base etc/network/interfaces

    set +x
}

##########

update_system_and_custom_packages()
{
    set -x

# tmp stuff
    sudo cp /etc/resolv.conf etc

# updating root_fs
    sudo bash -c "echo deb http://http.debian.net/debian/ $DEB_SUITE main contrib non-free > etc/apt/sources.list"
    sudo bash -c "echo deb http://security.debian.org/ $DEB_SUITE/updates main contrib non-free >> etc/apt/sources.list"
    sudo mkdir -p etc/apt/apt.conf.d

    # Configure http proxy for APT
    if [ -n "$HTTP_PROXY" ]
    then
        sudo bash -c "echo -e \"Acquire::http::Proxy \\\"$HTTP_PROXY\\\";\" > etc/apt/apt.conf.d/99proxy"
    fi

    # Update to be able to install lastest packages
    sudo chroot . apt-get update

    # Install brcmfmac firmware for Cubietruck (wifi/BT)
    if [ x"$BOARD_NAME" = "xCubietruck" ]; then
        sudo chroot . apt-get install --yes firmware-brcm80211
        if [ ! -d lib/firmware/brcm ]; then
            echo "*** Failed to install firmware" 1>&2
            exit 1
        else
            sudo cp ../resources/brcmfmac43362-sdio.txt lib/firmware/brcm/
        fi
    fi

# install additionnals packages
### Here $PACKAGES MUST be without double quotes or apt-get won't understand the list of packages
    sudo chroot . apt-get install --yes $PACKAGES

# removing tmp stuff
    sudo chroot . apt-get clean
    sudo chroot . apt-get autoclean
    sudo rm etc/resolv.conf

    if [ -e etc/apt/apt.conf.d/99proxy ]
    then
        sudo rm etc/apt/apt.conf.d/99proxy
    fi

    set +x
}

##########

install_kernel()
{
    set -x
# copy linux image to the root_fs
    sudo cp ../$LINUX_DIR/arch/arm/boot/uImage boot
    sudo cp ../$LINUX_DIR/arch/arm/boot/dts/${DTB} boot
    sudo make -C ../$LINUX_DIR INSTALL_MOD_PATH=`pwd` ARCH=arm CROSS_COMPILE="$GCC_PREFIX" modules_install

# add some kernel boot args
    mkimage -C none -A arm -T script -d ../boot.cmd ../boot.scr
    sudo mv ../boot.scr boot/
    sudo chown root:root boot/boot.scr
    set +x
}

##########

board_script()
{
    set -x

    # grab template fex file for cubieboard

    # case "$BOARD_NAME" in
	# Cubieboard)
	#     cp ../sunxi-boards/sys_config/a10/cubieboard.fex ../script.fex
	#     ;;
	# Cubieboard2)
	#     cp ../sunxi-boards/sys_config/a20/cubieboard2.fex ../script.fex
	#     ;;
	# *)
	#     echo "Unknown Cubieboard version. Leaving..."
	#     exit 1
	#     ;;
    # esac

    # Set Ethernet MAC addr
    # echo "" >> ../script.fex
    # echo "[dynamic]" >> ../script.fex
    # echo "MAC = \"$MACADDR\"" >> ../script.fex

    # Change the LEDs behavior
    #grep leds_trigger ../script.fex

    # created the binary version of the fex file
    # ../sunxi-tools/fex2bin  ../script.fex ../script.bin
    # sudo chown root:root ../script.bin
    # sudo mv ../script.bin boot/
    # rm ../script.fex

    # Adding fex manipulation binary to change Ethernet MAC addr at boot time using u-boot
    # sudo cp ../sunxi-tools/fexc root/
    # sudo chown root:root root/fexc

    set +x
}

########
# MAIN #
########

# create the chroot if it doesn't exist
mkdir -p $CHROOT_DIR
cd $CHROOT_DIR

case "$1" in
    all)
	do_debootstrap
	configure_system
	update_system_and_custom_packages
	install_kernel
	board_script
	;;
    debootstrap)
	do_debootstrap
	;;
    config)
	configure_system
	;;
    custom)
	update_system_and_custom_packages
	;;
    kernel)
	install_kernel
	;;
    board_script)
	board_script
	;;
    *)
	echo "Usage: make_debootstrap.sh {all|debootstrap|config|custom|kernel|board_script}"
	exit 1
esac

exit 0

##########

# Local Variables:
# mode:sh
# tab-width: 4
# indent-tabs-mode: nil
# End:
# vim: filetype=sh:expandtab:shiftwidth=4:tabstop=4:softtabstop=4
