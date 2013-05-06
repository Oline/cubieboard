setenv bootargs console=ttyS0,115200 hdmi.audio=EDID:0 disp.screen0_output_mode=EDID:1280x1024p60 root=/dev/mmcblk0p1 rootwait panic=10 ${extra}
ext2load mmc 0 0x43000000 boot/script.bin
ext2load mmc 0 0x48000000 boot/uImage
bootm 0x48000000
