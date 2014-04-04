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
	@echo "  -- kernel compilation --"
	@echo "kernel_defconfig:	Write the default sun4i kernel configuration for cubieboard (v1, not v2)"
	@echo "kernel_compile:		make ARCH=arm CROSS_COMPILE=$(GCC_PREFIX) uImage modules"
	@echo "with_grsecurity:	make ARCH=arm CROSS_COMPILE=$(GCC_PREFIX) uImage modules"
	@echo "with_lesser_grsecurity:	make ARCH=arm CROSS_COMPILE=$(GCC_PREFIX) DISABLE_PAX_PLUGINS=y uImage modules"
	@echo ""
	@echo "  -- u-boot compilation --"
	@echo "u-boot:			make CROSS_COMPILE=$(GCC_PREFIX) $(CUBIEBOARD_VERSION)_config"
	@echo ""
	@echo "  -- root_fs & sdcard partitionning --"
	@echo "debootstrap:		create the root_fs (need testing)"
	@echo "prepare_sdcard:		install u-boot and the root_fs to the sdcard"
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
	@echo "	CUBIEBOARD_VERSION	=	$(CUBIEBOARD_VERSION)"
	@echo "	FORMAT_SDCARD		=	$(FORMAT_SDCARD)"
	@echo "	SDCARD_DEVICE		=	$(SDCARD_DEVICE)"
	@echo ""
	@echo "	You can and MUST configure these variables from the file : makefile.vars"
	@echo ""

all:  u-boot kernel_defconfig kernel_compile debootstrap prepare_sdcard
	@echo "Done. You can now use your cubiboard :)"

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
ifeq ($(CUBIEBOARD_VERSION), cubieboard)
	cd $(LINUX_DIR) && make ARCH=arm CROSS_COMPILE=$(GCC_PREFIX) sun4i_defconfig
endif
ifeq ($(CUBIEBOARD_VERSION), cubieboard2)
	cd $(LINUX_DIR) && make ARCH=arm CROSS_COMPILE=$(GCC_PREFIX) sun7i_defconfig
endif
else
	@echo "File .config already exists."
endif

kernel_compile:
	cd $(LINUX_DIR) && make ARCH=arm CROSS_COMPILE=$(GCC_PREFIX) -j $(JOBS) uImage modules

with_grsecurity:
	cd $(LINUX_DIR) && make ARCH=arm CROSS_COMPILE=$(GCC_PREFIX) -j $(JOBS) uImage modules

with_lesser_grsecurity:
	cd $(LINUX_DIR) && make ARCH=arm CROSS_COMPILE=$(GCC_PREFIX) DISABLE_PAX_PLUGINS=y -j $(JOBS) uImage modules

kernel_clean:
	cd $(LINUX_DIR) && make CROSS_COMPILE=$(GCC_PREFIX) clean

kernel_distclean:
	cd $(LINUX_DIR) && make CROSS_COMPILE=$(GCC_PREFIX) mrproper


# bootloader u-boot compile

u-boot:
	cd $(UBOOT_DIR) && make CROSS_COMPILE=$(GCC_PREFIX) -j $(JOBS) $(CUBIEBOARD_VERSION)_config
	cd $(UBOOT_DIR) && make CROSS_COMPILE=$(GCC_PREFIX) -j $(JOBS)

u-boot_clean:
	cd $(UBOOT_DIR) && make CROSS_COMPILE=$(GCC_PREFIX) clean

u-boot_distclean:
	cd $(UBOOT_DIR) && make CROSS_COMPILE=$(GCC_PREFIX) distclean

# Debootstrap

debootstrap:
	./make_debootstrap.sh all

prepare_sdcard:
	./prepare_sdcard.sh all

# Cleaning stuff

clean: u-boot_clean kernel_clean


distclean: u-boot_distclean kernel_distclean
	sudo rm -rf chroot-armhf/
