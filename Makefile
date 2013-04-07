JOBS=16

all:
	@echo "What you should do:"
	@echo "  -- kernel compilation --"
	@echo "compile:		make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi-"
	@echo "with_grsecurity:	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi-"
	@echo "with_lesser_grsecurity:	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- DISABLE_PAX_PLUGINS=y"

# Kernel compil

compile:
	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- -j $(JOBS)

with_grsecurity:
	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- -j $(JOBS)

with_lesser_grsecurity:
	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- DISABLE_PAX_PLUGINS=y -j $(JOBS)

# repositories update

update:
	git submodule update
