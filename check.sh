#! /usr/bin/env bash

#set -x
set -e

MISSING=0

function check_command
{
    for i in $1
    do
	echo -n "	$i : "
	if command -v "$i" >/dev/null 2>&1
	then
	    echo -e "\e[32mOK\e[39m"
	else
	    echo -e "\e[31mKO\e[39m"
	    MISSING=1
	fi
    done
}

echo "Checking binary availability:"

echo "--- Builder ---"
check_command "make dd kpartx debootstrap chroot bash kill parted mkfs mount sudo gz bz2 xz md5sum sha1sum sha256sum"

echo "--- U-Boot & Linux ---"
check_command "mkimage bc dtc"

exit $MISSING
