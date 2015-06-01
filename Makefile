# Copyright (c) 2013-2014, Sylvain Leroy <sylvain@unmondelibre.fr>
#                    2014, Jean-Marc Lacroix <jeanmarc.lacroix@free.fr>

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

SED := sed

export

include makefile.vars

help:
	@echo "What you can do:"
	@echo ""
	@echo "all:			Will do all the job for you."
	@echo ""
	@echo "  -- git submodule management --"
	@echo "initsm:			git submodule init"
	@echo "updatesm:		git submodule update"
	@echo ""
	@echo "  -- grsecurity patch management --"
	@echo "patch_grsecurity:	make ARCH=arm CROSS_COMPILE=$(GCC_PREFIX)"
	@echo "prepare_grsecurity:	make ARCH=arm CROSS_COMPILE=$(GCC_PREFIX)"
	@echo ""
	@echo "  -- kernel configuration --"
	@echo "kernel_menuconfig:	make menuconfig in LINUX_DIR"
	@echo "kernel_gconfig:		make gconfig in LINUX_DIR"
	@echo ""
	@echo "  -- kernel compilation --"
	@echo "kernel_defconfig:	Write the default kernel configuration for cubieboard or cubieboard2"
	@echo "kernel_compile:		make ARCH=arm CROSS_COMPILE=$(GCC_PREFIX) uImage modules"
	@echo "with_grsecurity:	make ARCH=arm CROSS_COMPILE=$(GCC_PREFIX) uImage modules"
	@echo "with_lesser_grsecurity:	make ARCH=arm CROSS_COMPILE=$(GCC_PREFIX) DISABLE_PAX_PLUGINS=y uImage modules"
	@echo ""
	@echo "  -- u-boot compilation --"
	@echo "u-boot:			make CROSS_COMPILE=$(GCC_PREFIX) $(CUBIEBOARD_NAME)_config"
	@echo ""
	@echo "  -- root_fs & sdcard partitionning --"
	@echo "debootstrap:		create the root_fs (need testing)"
	@echo "prepare_sdcard:		install u-boot and the root_fs to the sdcard"
	@echo ""
	@echo "  -- checking targets --"
	@echo "check:			Use qemu to check the generated image"
	@echo "			$(QEMU_SYSTEM_ARM) -machine cubieboard -m $(QEMU_MEMORY_SIZE) -nographic -serial stdio -kernel $(LINUX_DIR)/arch/arm/boot/uImage -append \"root=/dev/mmcblk0p1 rootwait panic=10\""
	@echo ""
	@echo "  -- cleaning targets --"
	@echo "kernel_clean:		"
	@echo "kernel_distclean:	"
	@echo "clean:			clean the compiled files (not done yet)"
	@echo "distclean:		clean the compilet files and the root_fs"
	@echo ""
	@echo "  -- Environnement variables --"
	@echo "	LINUX_DIR		=	$(LINUX_DIR)"
	@echo "	UBOOT_DIR		=	$(UBOOT_DIR)"
	@echo "	CHROOT_DIR		=	$(CHROOT_DIR)"
	@echo "	GCC_PREFIX		=	$(GCC_PREFIX)"
	@echo "	JOBS			=	$(JOBS)"
	@echo "	HOSTNAME		=	$(HOSTNAME)"
	@echo "	PACKAGES		=	$(PACKAGES)"
	@echo "	CUBIEBOARD_NAME		=	$(CUBIEBOARD_NAME)"
	@echo "	FORMAT_SDCARD		=	$(FORMAT_SDCARD)"
	@echo "	SDCARD_DEVICE		=	$(SDCARD_DEVICE)"
	@echo ""
	@echo "	You can and MUST configure these variables from the file : makefile.vars"
	@echo ""

all:  u-boot kernel_defconfig kernel_compile debootstrap prepare_sdcard
	@echo "Done. You can now use your $(CUBIEBOARD_NAME) :)"

# repositories update

initsm:
	git submodule init

updatesm:
	git submodule update

# grsecurity patch management

patch_grsecurity:
	cd $(LINUX_DIR) && git checkout -b 3.2.42
	cd $(LINUX_DIR) && patch -p1 < ../grsecurity/grsecurity-2.9.1-3.2.42-201304061343.patch

prepare_grsecurity:
	cp conf/config_cubieboard_3.2.42_grsec linux-stable/.config

# Kernel compile

kernel_defconfig:
ifeq ($(findstring .config,$(wildcard $(LINUX_DIR)/.config)), ) # check if .config can be erased, else do not erase it
ifeq ($(CUBIEBOARD_NAME), Cubieboard)
	cd $(LINUX_DIR) && make ARCH=arm CROSS_COMPILE=$(GCC_PREFIX) sun4i_defconfig
endif
ifeq ($(CUBIEBOARD_NAME), Cubieboard2)
	cd $(LINUX_DIR) && make ARCH=arm CROSS_COMPILE=$(GCC_PREFIX) sun7i_defconfig
endif
ifeq ($(CUBIEBOARD_NAME), Cubietruck)
	cd $(LINUX_DIR) && make ARCH=arm CROSS_COMPILE=$(GCC_PREFIX) sun7i_defconfig
endif
else
	@echo "File .config already exists."
endif

kernel_menuconfig:
	cd $(LINUX_DIR) && make ARCH=arm CROSS_COMPILE=$(GCC_PREFIX) menuconfig

kernel_gconfig:
	cd $(LINUX_DIR) && make ARCH=arm CROSS_COMPILE=$(GCC_PREFIX) gconfig

kernel_compile: $(LINUX_DIR)/arch/arm/boot/uImage $(LINUX_DIR)/arch/arm/boot/dts/sun7i-a20-cubieboard2.dtb

$(LINUX_DIR)/arch/arm/boot/uImage: $(LINUX_DIR)/.config
# extract current SHA1 from git linux kernel version source
# and append this version to the kernel version in order to have this SHA1
# matched in command : uname -a command and SNMP MIB
	cd $(LINUX_DIR) && make \
	EXTRAVERSION=-`git rev-parse --short HEAD` \
	ARCH=arm \
	CROSS_COMPILE=$(GCC_PREFIX) \
	-j $(JOBS) \
	uImage modules LOADADDR=0x40008000

$(LINUX_DIR)/arch/arm/boot/dts/sun7i-a20-cubieboard2.dtb: $(LINUX_DIR)/arch/arm/boot/dts/sun7i-a20-cubieboard2.dts $(LINUX_DIR)/.config
	cd $(LINUX_DIR) && make \
	EXTRAVERSION=-`git rev-parse --short HEAD` \
	ARCH=arm \
	CROSS_COMPILE=$(GCC_PREFIX) \
	-j $(JOBS) \
	dtbs LOADADDR=0x40008000

# with_grsecurity:
# 	cd $(LINUX_DIR) && make ARCH=arm CROSS_COMPILE=$(GCC_PREFIX) -j $(JOBS) uImage modules

# with_lesser_grsecurity:
# 	cd $(LINUX_DIR) && make ARCH=arm CROSS_COMPILE=$(GCC_PREFIX) DISABLE_PAX_PLUGINS=y -j $(JOBS) uImage modules

kernel_clean:
	cd $(LINUX_DIR) && make CROSS_COMPILE=$(GCC_PREFIX) clean

kernel_distclean:
	cd $(LINUX_DIR) && make CROSS_COMPILE=$(GCC_PREFIX) mrproper


# bootloader u-boot compile

u-boot: $(UBOOT_DIR)/u-boot-sunxi-with-spl.bin

$(UBOOT_DIR)/u-boot-sunxi-with-spl.bin:
	cd $(UBOOT_DIR) && make CROSS_COMPILE=$(GCC_PREFIX) -j $(JOBS) $(CUBIEBOARD_NAME)_config
	cd $(UBOOT_DIR) && make CROSS_COMPILE=$(GCC_PREFIX) -j $(JOBS)

u-boot_clean:
	cd $(UBOOT_DIR) && make CROSS_COMPILE=$(GCC_PREFIX) clean

u-boot_distclean:
	cd $(UBOOT_DIR) && make CROSS_COMPILE=$(GCC_PREFIX) distclean

# Debootstrap

boot.cmd: boot.cmd.in makefile.vars
	$(SED) 's/@DTB@/$(DTB)/g' $< > $@

debootstrap: boot.cmd
	./make_debootstrap.sh all

prepare_sdcard:
	./prepare_sdcard.sh all

# Check

check: $(LINUX_DIR)/arch/arm/boot/uImage
	$(QEMU_SYSTEM_ARM) -machine cubieboard -m $(QEMU_MEMORY_SIZE) -nographic -serial stdio -kernel $(LINUX_DIR)/arch/arm/boot/uImage -append "root=/dev/mmcblk0p1 rootwait panic=10"

# Cleaning stuff

clean: u-boot_clean kernel_clean


distclean: u-boot_distclean kernel_distclean
	sudo rm -rf chroot-armhf/
