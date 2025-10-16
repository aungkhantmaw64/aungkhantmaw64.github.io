+++
date = '2025-10-12T16:41:18+07:00'
draft = false
title = 'Roll Your Own (RYO) Embedded Linux Distro'
thumbnail = "images/blue-penguin.jpg"
tags = ["u-boot", "busybox", "linux"]
categories = ["Embedded Linux"]
+++

_Having fun with U-Boot, Linux Kernel, and BusyBox_

## <!--more-->

Building a custom embedded Linux image for single board computers (SBC) often requires build systems like `Buildroot`, and `Yocto`. However, today I wanted to learn how to create my own image without using these build systems, for educational purposes. I have a few SBCs, such as `Beagle Bone Black` and `Raspberry PI 4 model B`, available. So, I'll use these for my experiments and may also build an image for the QEMU emulator along the way.

## Installing Toolchains

First and foremost, the important step is to install toolchains required for cross-compiling, since our target board often has a different CPU architecture than the host PC we use for compiling the code.

> For example, the **Beagle Bone Black** uses the Texas Instruments Sitara `AM335x` processor, which is based on `ARM Cortex-A8`. Also, the **Raspberry Pi 4** uses the Broadcom `BCM2711` SoC, which features a quad-core `ARM Cortex-A72` CPU.

Installing the toolchains could be as simple as downloading the pre-built binaries and adding them to the system `PATH`. But, here I will go with the hard way that uses `crosstool-ng`, a tool that allows us to customize the toolchain we want to install.

### Installing Dependencies

I'm using **PoP! OS**, a distro based on **Ubuntu**, on my host machine. Before moving forward, we need to install the dependencies in advance with this command:

```bash
sudo apt-get update && sudo apt-get install -y autoconf automake bc bison bzip2 build-essential coccinelle \
  device-tree-compiler dfu-util efitools flex git gcc g++ gperf gdisk graphviz gawk help2man imagemagick \
  liblz4-tool libgnutls28-dev libguestfs-tools libncurses-dev libncurses5-dev \
  libpython3-dev libsdl2-dev libssl-dev lz4 lzma lzma-alone libtool libtool-bin libstdc++6 meson \
  ninja-build openssl pkg-config python3-dev python3-asteval python3-coverage python3-filelock \
  python3-pkg-resources python3-pycryptodome python3-pyelftools \
  python3-pytest python3-pytest-xdist python3-sphinxcontrib.apidoc \
  python3-sphinx-rtd-theme python3-subunit python3-testtools \
  python3-virtualenv patch rsync swig texinfo uuid-dev unzip wget xz-utils linux-libc-dev linux-headers-generic

```

> A link to the `Dockerfile` for this build environment is provided in the references section. We can use it, if we don't want to install the tools natively.

Let us create a project folder and clone the `crosstool-ng` repo in it:

```bash
git clone https://github.com/crosstool-ng/crosstool-ng
```

We can bootstrap `crosstool-ng` and build it with the following commands:

```bash
cd crosstool-ng
./bootstrap
./configure --prefix=/opt/crosstool-ng
make
make install
export PATH="$PATH:/opt/crosstool-ng/bin"
```

> We can specify the build directory with `prefix` option,`/opt/crosstool-ng` in this example. Change this to a preferred directory if necessary.

After installing ct-ng, we can run the following command to open the configuration menu for installing the toolchains.

```bash
ct-ng menuconfig
```

A graphical user interface for the configuration menu similar to the following picture will appear. And it is important to learn how to work with `Kconfig` as we will often encounter `menuconfig` in different stages of embedded Linux development since most build systems commonly use `Kconfig` for configuration.

![crosstool-ng menuconfig](/images/ct-ng-menuconfig.png)

First-timers who have no experience working with the toolchains can get significantly overwhelmed by the available options. This may still be true when working with the bootloader (U-Boot), kernel, and rootfs. For this reason, we can always find the pre-built configuration files provided by the vendor in almost all the projects.

For `crosstool-ng`, we can run the following commands to see the available configurations:

```bash
ct-ng list-samples
```

The output results could be similar to this:

```bash
Status  Sample name
[L...]   aarch64-ol7u9-linux-gnu
[L...]   aarch64-ol8u10-linux-gnu
[L...]   aarch64-ol8u6-linux-gnu
[L...]   aarch64-ol8u7-linux-gnu
[L...]   aarch64-ol8u8-linux-gnu
[L...]   aarch64-ol8u9-linux-gnu
[L...]   aarch64-ol9u2-linux-gnu
[L...]   aarch64-ol9u3-linux-gnu
[L...]   aarch64-ol9u4-linux-gnu
[L...]   aarch64-ol9u5-linux-gnu
[L...]   aarch64-rpi3-linux-gnu
[L...]   aarch64-rpi4-linux-gnu
[L...]   aarch64-unknown-linux-gnu
[L...]   aarch64-unknown-linux-musl
[L...]   aarch64-unknown-linux-uclibc
[L...]   alphaev56-unknown-linux-gnu
[L...]   alphaev67-unknown-linux-gnu
[L...]   arc-arc700-linux-uclibc
[L...]   arc-archs-linux-gnu
[L...]   arc-multilib-elf32
[L...]   arc-multilib-linux-gnu
[L...]   arc-multilib-linux-uclibc
[L...]   arm-bare_newlib_cortex_m3_nommu-eabi
```

From the output, we can find the names of the toolchains with the corresponding supported CPU architecture. What we are looking for here are `arm-cortex_a8-linux-gnueabi` and `arm-unknown-linux-gnueabi`.

> `arm-cortex_a8-linux-gnueabi` is specifically optimized for `Cortex-A8`, while `arm-unknown-linux-gnueabi` is a more generic toolchain, that works with most `ARM`-based SoCs.

We can use the following command to inspect the toolchain in more detail:

```bash
ct-ng show-arm-cortex_a8-linux-gnueabi
```

And, the output will be similar to this:

```bash
  Languages       : C,C++
  OS              : linux-6.16
  Binutils        : binutils-2.45
  Compiler        : gcc-15.2.0
  Linkers         :
  C library       : glibc-2.42
  Debug tools     : duma-2_5_21 gdb-16.3 ltrace-0.7.3 strace-6.16
  Companion libs  : expat-2.7.1 gettext-0.26 gmp-6.3.0 isl-0.27 libelf-0.8.13 libiconv-1.18 mpc-1.3.1 mpfr-4.2.2 ncurses-6.5 zlib-1.3.1 zstd-1.5.7
  Companion tools :
```

> Replace `arm-cortex_a8-linux-gnueabi` in the above command with your preferred toolchain names to inspect them.

Once we have decided on which toolchain to use, we can derive the `.config` configuration file from the pre-built configuration like this:

```bash
ct-ng arm-cortex_a8-linux-gnueabi
```

Then, this time, it will be easier to chnage the configurations based on our needs, since the toolchain has already been set up with all the basic options required for our target architecture, thanks to the pre-built configs.

As for the first time, we will not be concerned about changing any options yet. However, we should be aware of the default installation path for the toolchains, since we have to add it in the system `PATH` afterward. If we already have a preferred installation path, we can change it in the `Path and misc options` tab of the `menuconfig`.

Once we are done configuring, we can start building the toolchains with this command:

```bash
ct-ng build
```

And, this is where we take a break to grab some coffee or go to the bathroom, as it will take some time to build the toolchains.

## Bootloader (U-Boot)

Before compiling the bootloader, we can check if the toolchain is correctly installed by the following command:

```bash
arm-cortex_a8-linux-gnueabi-gcc --version
```

The version information should be generated like this, and if not, we will need to check if it is properly added to the system `PATH`.

```bash
arm-cortex_a8-linux-gnueabi-gcc (crosstool-NG 1.28.0.1_403899e) 15.2.0
Copyright (C) 2025 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

```

Now, we will clone the u-boot repo into our project folder:

```bash
git clone https://github.com/u-boot/u-boot.git
```

Similar to `crosstool-ng`, `U-Boot` also has board-specific configuration presets provided by the vendors.

## References

- Crosstool-NG - <https://crosstool-ng.github.io/docs/install/>
- U-Boot Documentation - <https://u-boot.org/>
