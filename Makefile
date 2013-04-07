LINUX_DIR=linux-stable
UBOOT_DIR=u-boot-sunxi
JOBS=16

all:
	@echo "What you should do:"
	@echo "  -- kernel compilation --"
	@echo "compile:		make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi-"
	@echo "with_grsecurity:	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi-"
	@echo "with_lesser_grsecurity:	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- DISABLE_PAX_PLUGINS=y"
	@echo "  -- u-boot compilation --"
	@echo "u-boot:	make cubieboard_config"

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

# repositories update

update:
	git submodule update
