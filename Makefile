
-include makefiles.vars

all:
	@echo "What you can do:"
	@echo ""
	@echo "  -- kernel compilation --"
	@echo "compile:		make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi-"
	@echo "with_grsecurity:	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi-"
	@echo "with_lesser_grsecurity:	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- DISABLE_PAX_PLUGINS=y"
	@echo ""
	@echo "  -- u-boot compilation --"
	@echo "u-boot:			make cubieboard_config"
	@echo ""
	@echo "  -- root_fs & sdcard partitionning --"
	@echo "debootstrap:		create the root_fs (need testing)"
	@echo "prepare_sdcard:		install the root_fs to the sdcard (not yet tested)"
	@echo ""
	@echo "  -- git submodule management --"
	@echo "initsm:			git submodule init"
	@echo "updatesm:		git submodule update"
	@echo ""
	@echo "  -- cleaning targets --"
	@echo "clean:			clean the compiled files (not done yet)"
	@echo "distclean:		clean the compilet files and the root_fs"
	@echo ""

# Kernel compile

compile:
	cd $(LINUX_DIR) && make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- -j $(JOBS)

with_grsecurity:
	cd $(LINUX_DIR) && make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- -j $(JOBS)

with_lesser_grsecurity:
	cd $(LINUX_DIR) && make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- DISABLE_PAX_PLUGINS=y -j $(JOBS)

# bootloader u-boot compile

u-boot:
	cd $(UBOOT_DIR) && make cubieboard_config
	cd $(UBOOT_DIR) && make CROSS_COMPILE=arm-linux-gnueabi-

u-boot-clean:
	cd $(UBOOT_DIR) && make CROSS_COMPILE=arm-linux-gnueabi- clean

u-boot-distclean:
	cd $(UBOOT_DIR) && make CROSS_COMPILE=arm-linux-gnueabi- distclean

# Debootstrap

debootstrap:
	./make_debootstrap.sh

prepare_sdcard:
	./prepare_sdcard.sh

# repositories update

initsm:
	git submodule init

updatesm:
	git submodule update

# Cleaning stuff

clean:


distclean:
	sudo rm -rf chroot-armhf/
