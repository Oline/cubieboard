
include makefile.vars

all:
	@echo "What you can do:"
	@echo ""
	@echo "  -- git submodule management --"
	@echo "initsm:			git submodule init"
	@echo "updatesm:		git submodule update"
	@echo ""
	@echo "  -- grsecurity patch management --"
	@echo "patch_grsecurity:	make ARCH=arm CROSS_COMPILE=$(GCC_PREFIX)"
	@echo "prepare_grsecurity:	make ARCH=arm CROSS_COMPILE=$(GCC_PREFIX)"
	@echo ""
	@echo "  -- kernel compilation --"
	@echo "compile:		make ARCH=arm CROSS_COMPILE=$(GCC_PREFIX) uImage modules"
	@echo "with_grsecurity:	make ARCH=arm CROSS_COMPILE=$(GCC_PREFIX) uImage modules"
	@echo "with_lesser_grsecurity:	make ARCH=arm CROSS_COMPILE=$(GCC_PREFIX) DISABLE_PAX_PLUGINS=y uImage modules"
	@echo ""
	@echo "  -- u-boot compilation --"
	@echo "u-boot:			make cubieboard_config"
	@echo ""
	@echo "  -- root_fs & sdcard partitionning --"
	@echo "debootstrap:		create the root_fs (need testing)"
	@echo "prepare_sdcard:		install the root_fs to the sdcard (not yet tested)"
	@echo ""
	@echo "  -- cleaning targets --"
	@echo "clean:			clean the compiled files (not done yet)"
	@echo "distclean:		clean the compilet files and the root_fs"
	@echo ""
	@echo "  -- Environnement variables --"
	@echo "	LINUX_DIR	=	$(LINUX_DIR)"
	@echo "	UBOOT_DIR	=	$(UBOOT_DIR)"
	@echo "	GCC_PREFIX	=	$(GCC_PREFIX)"
	@echo "	JOBS		=	$(JOBS)"
	@echo "	SDCARD_DEVICE	=	$(SDCARD_DEVICE)"

# repositories update

initsm:
	git submodule init

updatesm:
	git submodule update

# Kernel compile

patch_grsecurity:
	cd $(LINUX_DIR) && git checkout -b 3.2.42
	cd $(LINUX_DIR) && patch -p1 < ../grsecurity/grsecurity-2.9.1-3.2.42-201304061343.patch

prepare_grsecurity:
	cp conf/config_cubieboard_3.2.42_grsec linux-stable/.config

compile:
	cd $(LINUX_DIR) && make ARCH=arm CROSS_COMPILE=$(GCC_PREFIX) -j $(JOBS) uImage modules

with_grsecurity:
	cd $(LINUX_DIR) && make ARCH=arm CROSS_COMPILE=$(GCC_PREFIX) -j $(JOBS) uImage modules

with_lesser_grsecurity:
	cd $(LINUX_DIR) && make ARCH=arm CROSS_COMPILE=$(GCC_PREFIX) DISABLE_PAX_PLUGINS=y -j $(JOBS) uImage modules

# bootloader u-boot compile

u-boot:
	cd $(UBOOT_DIR) && make cubieboard_config
	cd $(UBOOT_DIR) && make CROSS_COMPILE=$(GCC_PREFIX)

u-boot-clean:
	cd $(UBOOT_DIR) && make CROSS_COMPILE=$(GCC_PREFIX) clean

u-boot-distclean:
	cd $(UBOOT_DIR) && make CROSS_COMPILE=$(GCC_PREFIX) distclean

# Debootstrap

debootstrap:
	./make_debootstrap.sh all

prepare_sdcard:
	SDCARD_DEVICE=$(SDCARD_DEVICE) ./prepare_sdcard.sh copy2sdcard

# Cleaning stuff

clean:


distclean: clean
	sudo rm -rf chroot-armhf/
