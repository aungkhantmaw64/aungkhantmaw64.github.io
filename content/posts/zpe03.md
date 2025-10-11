+++
title = 'Configuring PSRAM for ESP32S3 in Zephyr RTOS'
date = '2025-10-08T00:03:13+07:00'
draft = false
images = ["images/ram-memory.jpg"]
thumbnail = "images/ram-memory.jpg"
tags = ["device tree", "zephyrproject", "PSRAM", "ESP32S3"]
categories = ["firmware", "C/C++"]
+++

_Putting ESP32-S3 on Steroids!_

## <!--more-->

I recently bought an `ESP32-S3-DevKitC` with `8MB` of external PSRAM and `16MB` of Flash.
My initial plan was to use it as a main controller for my smartwatch side project based on Zephyr RTOS.
Although I haven't found time to work on the side project yet, I decided at least to write about enabling PSRAM on ESP32, which could have been a small part of the project.

This module is specifically chosen for running high-end UI applications using libraries such as LVGL, where frame buffers consume a relatively large amount of RAM to render high-resolution vector graphics.
For example, consider **GC9A01** LCD display driver with a resolution of **240 x 240** pixels. If our application requires a color depth of `RGB565` (16-bit) and double buffering, the total RAM required would be approximately **233** KB. This is close to the size of the built-in SRAM, that is **512KB**. Without extra RAM space, the SoC will definitely struggles running the graphical interface.

## Let's Configure The External PSRAM on ESP32S3 in Zephyr Project

The model number engraved on the metal shield subtlely indicate the PSRAM and Flash sizes.
For instance, the number `N16R8` means 16 MB of Flash and 8MB of RAM. With this naming convention, `N8R4` would mean 8MB of flash and 4MB of RAM.
If we don't trust the numbers on the module, we can install `esptool.py` tools from Espressif and run the following command in the console (with the dev kit connected to the host machine) to verify memory sizes.

```bash
esptool --port /dev/ttyACM0 flash-id
```

> I'm using an Ubuntu PC as my host machine and `/dev/ttyACM0` is the serial port of the dev kit. This may vary on different platforms.

Here is the output of the above command:

```bash
esptool v5.1.0
Connected to ESP32-S3 on /dev/ttyACM0:
Chip type:          ESP32-S3 (QFN56) (revision v0.2)
Features:           Wi-Fi, BT 5 (LE), Dual Core + LP Core, 240MHz, Embedded PSRAM 8MB (AP_3v3)
Crystal frequency:  40MHz
MAC:                50:78:7d:15:ea:e8

Stub flasher running.

Flash Memory Information:
=========================
Manufacturer: 68
Device: 4018
Detected flash size: 16MB
Flash type set in eFuse: quad (4 data lines)
Flash voltage set by eFuse: 3.3V

Hard resetting via RTS pin...
```

> Older versions of `esptool` might produce the output in a slightly different format.

The `esptool` versions may vary with the Zephyr version we use. To check Zephyr version, it would be easier to print the `VERSION` file like this:

```bash
cat ${ZEPHYR_ROOT}/zephyr/VERSION

VERSION_MAJOR = 4
VERSION_MINOR = 2
PATCHLEVEL = 99
VERSION_TWEAK = 0
EXTRAVERSION =
```

Great!

We have verified that my ESP32 module does indeed have `16 MB` of Flash and `8 MB` of SPI RAM.

> Although the above output does not specify the types of SPI peripherals, the flash interfaces with Quad SPI, while the PSRAM interfaces Octal SPI, according to the [datasheet](https://www.espressif.com/sites/default/files/documentation/esp32-s3-wroom-1_wroom-1u_datasheet_en.pdf).

Quad and Octal SPI are enhanced versions of traditional SPI interface.
They use _double data rate (DDR)_ techniques and employ more parallel data lines to achieve faster data transfer rates.
Quad SPI utilizes `4` parallel data pins, while Octal SPI utilizes `8`.
The datasheet specifies which SPI peripherals are used by the flash and PSRAM based on the module revision.
According to the pin map, both flash and PSRAM use the same shared data buses and are selected by `SPICS0` and `SPICS1`, respectively.

> For firmware engineers, it is enough to know the types, sizes, and pin maps of SPIs used by the flash and PSRAM; for more information on the SPI stands, refer to the references section.

Now, let's begin creating a Zephyr project and see how we can utilizes the extra RAM and flash to our advantage.
The PSRAM will not work out of the box, as Zephyr does not have the capability to automatically detect it.
We have to specify the memory configuration using the device-tree and Kconfig.

Before doing so, let's compile a simple `helloworld` app without configuring anything for `ESP32S3` and observe the flash and RAM sizes in the output:

```bash
 west build -b esp32s3_devkitc/esp32s3/appcpu -p always apps/psram_01/
```

> `apps/psram_01/` is the path to the project directory. A link to the ready-to-build development environment on GitHub is provided in the References section.

Here's the build (Linker) output:

```bash
Linking C executable zephyr/zephyr.elf
Memory region         Used Size  Region Size  %age Used
     mcuboot_hdr:          32 B         32 B    100.00%
        metadata:          80 B         96 B     83.33%
           FLASH:      132524 B    8388480 B      1.58%
     iram0_1_seg:       10816 B       128 KB      8.25%
     dram0_1_seg:       20600 B       128 KB     15.72%
     irom0_1_seg:        7272 B         2 MB      0.35%
     drom0_1_seg:       67116 B         2 MB      3.20%
        IDT_LIST:          0 GB         8 KB      0.00%
```

The linker output suggests that the built-in `256 KB` of SRAM is equally divided into two `128 KB` regions, IRAM (used for caching code sections that requires quick execution, such as interrupt service routine) and DRAM (used for saving data).
In addition, the default flash size is set to `8 MB`.

## References

- UIs on Embedded System - <https://blog.st.com/uis-on-embedded-systems/>
- ESP32S3-WROOM datasheet - <https://www.espressif.com/sites/default/files/documentation/esp32-s3-wroom-1_wroom-1u_datasheet_en.pdf>
- Understanding Serial Peripheral Interface (SPI) Standards - <https://www.arasan.com/blog/understanding-serial-peripheral-interface-spi-standards-a-comprehensive-overview/>
- Code Repo - <https://github.com/aungkhantmaw64/zephyr-pg>
