---
title: Roll Your Own Embedded Linux Image
date: 2025-01-03
tags:
  - Linux
---
_This article explains how you can roll your own embedded linux image without any build systems for the beagle bone black SBC._

## <!--more-->

## Bootloader (U-Boot)
### Step 1 - Build
Build steps:
```bash
# Step 1: Clean up the previous build files
make ARCH=arm CROSS_COMPILE=arm-cortex_a8-linux-gnueabi- distclean
# Step 2: Generate a board-specific configuration preset
make ARCH=arm CROSS_COMPILE=arm-cortex_a8-linux-gnueabi- arm335x_evm_defconfig
# Step 3 (optional): Modify the generated build config file
make ARCH=arm CROSS_COMPILE=arm-cortex_a8-linux-gnueabi- menuconfig
# Step 4: Compile the bootloader (Use O=/your/build/path for a custom build directory)
make ARCH=arm CROSS_COMPILE=arm-cortex_a8-linux-gnueabi- -j4
```
Notes:
- Preset configs can be found under the `u-boot/configs` folder.
- `CONFIG_SYS_LOAD_ADDR` is `0x82000000`, by default in `am335x_evm_defconfig`. Use this memory address to load the kernel.
- `am335x_evm_defconfig` is used for Beagle Bone Black as it is based on *am335x* SoC.

### Step 2 - Flash
Important generated build files:
- **u-boot.img** - `a tertiary program loader` or the u-boot bootloader itself.
- **MLO** - `a secondary program loader` that is loaded into the on-chip RAM memory space by the ROM code, the Primary Program Loader, before loading the bigger `u-boot.img` in to the DRAM memory. 

>  The full `u-boot` bootloader barely fits inside that tiny 128KB of the on-chip RAM space. So, the smaller part of `u-boot`, MLO, is loaded first to do the minimal steps of initializing the memory controller of DRAM, which has a larger space to load `u-boot`. 


Important things to remember when creating a bootable SD card:
- Two partitions must be created:
	- `boot` - formatted as `FAT32` with a size of `64 MiB` to store the bootloader and its script (optional).
	- `rootfs` - formatted as `ext4` with a size of `1 GiB` to store the root file system.

SD Card Partitioning Script:
```bash
#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "  Usage: $0 <drive>"
  echo "      Example: $0 mmcblk0"
  echo "      Run lsblk to find the drive name."
  exit 1
fi

DRIVE=$1

NUM_SECTORS=$(cat /sys/block/$DRIVE/size)
if [ $? -ne 0 ]; then
  echo "Error: Unable to read the number of sectors from /sys/block/${DRIVE}/size"
  exit 1
fi

if [[ $NUM_SECTORS -eq 0 || $NUM_SECTORS -gt 126000000 ]]; then
  echo "The block device has ${NUM_SECTORS} sectors."
  echo "This does not seem like a valid SD card."
  exit 1
fi

SD_CARD_SIZE=$(($NUM_SECTORS * 512))
SD_CARD_SIZE_GB=$(($SD_CARD_SIZE / 1024 / 1024 / 1024))

echo -n "The SD card size is ~${SD_CARD_SIZE_GB} GiB. Are you sure you want to format it? (y/n): "
read -r CONFIRM
if [[ $CONFIRM != "y" && $CONFIRM != "Y" ]]; then
  echo "Aborting."
  exit 1
fi

read -p "Enter the device name (e.g., /dev/sdX): " device

echo "Unmounting any mounted partitions on ${DRIVE}..."

sudo umount ${device}* || true

# Overwite any existing partiton table with zeros
echo "Overwriting the partition table with zeros..."
sudo dd if=/dev/zero of=${device} bs=1M count=10

echo "Formatting the SD card ${device}..."

part1_label="boot"
part2_label="rootfs"

echo "Creating a new partition table."
sudo parted -s $device mklabel msdos

echo "Creating the first partition (FAT32)"
sudo parted -s $device mkpart primary fat32 1MiB 64MiB

echo "Making the first partition bootable"
sudo parted -s $device set 1 boot on

echo "Creating the second partition (ext4)"
sudo parted -s $device mkpart primary ext4 64MiB 1GiB

echo "Formatting (FAT32) boot partition ${device}p1"
sudo mkfs.vfat -F 32 -n "${part1_label}" ${device}p1

echo "Formatting (EXT4) root partition ${device}p2"
sudo mkfs.ext4 -L "${part2_label}" ${device}p2

echo "Partitioning and formatting complete!"

```

### Step 3 - Boot Script
The following script does these steps:
- load the kernel image (zImage) and device tree binary (\*.dtb) using TFTP protocol via Ethernet from a host computer
- load the root file system using the network file system (NFS)

uboot.txt:
```bash
fdtaddr=0x88000000
loadaddr=0x82000000
ipaddr=192.168.7.9
serverip=192.168.7.1
loadkernel=tftpboot ${loadaddr} ${serverip}:zImage;
loaddtb=tftpboot ${fdtaddr} ${serverip}:am335x-boneblack.dtb
console=ttyS0,115200n8
rootpath=/srv/nfs/bbb,nolock,wsize=1024,rsize=1024 rootwait rootdelay=5
netargs=setenv bootargs console=${console} root=/dev/nfs nfsroot=${serverip}:${rootpath},vers=4 rw ip=${ipaddr}:${serverip}:0.0.0.0:255.255.255.0:bbb:eth0:off rootwait
bootcmd=setenv autoload no;run loadkernel;run loaddtb;run netargs;bootz ${loadaddr} - ${fdtaddr}
```
Convert the plain text script into bootable environment file:
```bash
mkenvimage -s 0x2000 -o uboot.env uboot.txt
```

The host computer must have these daemons running:
- tftpd-hpa
- nfs-server
When setting `bootargs`, consult [kernel-parameters documentation](https://www.kernel.org/doc/html/v4.14/admin-guide/kernel-parameters.html) for more details.

On the host side:
```bash
# Change the owership of the tftp folder (e.g, /var/lib/tftpboot)
sudo chown -R tftp:tftp /var/lib/tftpboot
# Change the file permissons of the tftp folder
sudo chmod -R 777 /var/lib/tftpboot
# Change the ownership of the nfs folder (e.g, /srv/nfs/bbb)
sudo chown -R nobody:nogroup /srv/nfs/bbb 
# Change the file permissions of the nfs folder
sudo chmod -R 775 /srv/nfs/bbb
```
TFTP configuration:
```bash
# File name: /etc/default/tftp-hpa
TFTP_USERNAME="tftp"                                                                    TFTP_DIRECTORY="/var/lib/tftpboot"
TFTP_ADDRESS=":69"
TFTP_OPTIONS="--create --secure"
```
NFS Configuration:
```bash
#!/etc/exports
/srv/nfs/bbb 192.168.7.9(rw,sync,no_root_squash,no_subtree_check,fsid=0,crossmnt)

```
Steps to mount NFS: 
```bash
# Step 1: Go to the NFS folder
cd /srv/nfs/bbb
# Step 2: 
sudo exportfs -arv
# Step 3:
sudo service nfs-kernel-server restart
```

Important things to note:
- Check NFS version mismatch
- Check `ip` parameters (ipaddr, serverip, gateway, netmask, etc.) are set correctly.
- Check CONFIG_ENV_SIZE when using `mkenvimage`.
- Check `/etc/exports` (settings might vary depending on the NFS version)

## Kernel (Linux)
### Building 
Compilation steps: 
```bash
# Step 1: Clean leftovers from the previous builds
make ARCH=arm CROSS_COMPILE=arm-cortex_a8-linux-gnueabi- distclean
# Step 2: Generate a board-specific configuration preset (.config)
make ARCH=arm CROSS_COMPILE=arm-cortex_a8-linux-gnueabi- multi_v7_defconfig
# Step 3 (optional): Modify the configuration based on your preferences
make ARCH=arm CROSS_COMPILE=arm-cortex_a8-linux-gnueabi- menuconfig
# Step 4: Build the kernel
make ARCH=arm CROSS_COMPILE=arm-cortex_a8-linux-gnueabi- zImage dtbs -j4
# Step 5: Build the kernel modules
make ARCH=arm CROSS_COMPILE=arm-cortex_a8-linux-gnueabi- modules -j4
# Step 6: Install the modules into the root file system (staging area)
make ARCH=arm CROSS_COMPILE=arm-cortex_a8-linux-gnueabi- INSTALL_MOD_PATH=<path_to_staging_area> modules_install
```

> Older versions of u-boot do not support `bootz` but only `bootm` command. In that case, use `make ARCH=arm CROSS_COMPILE=arm-cortex_a8-linux-gnueabi- uImage dtb LOADADDR=0x82000000` command to generate `uImage`.

Important Build Output:
- `zImage` - the compressed kernel image.
- `<board>.dtb` - device tree binary for the target board.

> [!question] *Can't find the `dtb` file and `zImage`?*

Run the following commands:
```bash
# Find zImage in the linux directory
find <path_to_linux_root> -name 'zImage'
# Find dtb of your specific board
find <path_to_linux_root> -name '*.dtb'
# (optional) Use the following command for the beagle bone black's device tree binary
find <path_to_linux_root> -name 'am335x-boneblack.dtb'
```

Notes: 
- `multi_v7_defconfig` is a preset for all ARM Cortex-A8 (ARMv7-A) based boards including Beagle Bone Black.

### Configure
Notes:
- Select device drivers as built-in kernel features (\*) or loadable modules (M).
- Ethernet driver for `LAN8710A-EZC-TR` is located under `drivers/net/phy`, not `drivers/net/ethernet`. See `CONFIG_SMSC_PHY` option for further details.

## Root File System (RFS)
### Build 
Build steps:
```bash
# Step 1: Clean up previous builds
make distclean
# Step 2: Generate a default configuration file
make ARCH=arm CROSS_COMPILE=arm-cortex_a8-linux-gnueabi- defconfig
# Step 3 (Optional): Customize the generated build config
make ARCH=arm CROSS_COMPILE=arm-cortex_a8-linux-gnueabi- menuconfig
# Step 4: Build the source code in the given install path
make ARCH=arm CROSS_COMPILE=arm-cortex_a8-linux-gnueabi- CONFIG_PREFIX=<install_path> install -j4
```

### Configure
Notes:
- Disable `tc` (Networking Utilities) and `SHA1` (Settings) hardware acceleration. (These old headers are not supported anymore in the latest kernels)
- Build the RFS as a static (CONFIG_STATIC=y)

# Resources
- [TFTP and NFS Booting ON Beagle Bone Black Wireless](https://bootlin.com/blog/tftp-nfs-booting-beagle-bone-black-wireless-pocket-beagle/)