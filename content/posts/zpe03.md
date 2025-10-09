+++
title = 'Configuring PSRAM for ESP32S3 in Zephyr RTOS'
date = '2025-10-08T00:03:13+07:00'
draft = false
tags = ["device tree", "zephyrproject", "PSRAM", "ESP32S3"]
categories = ["firmware", "C/C++"]
+++

## <!--more-->

# Context

With an extra space of 8MB RAM available on an ESP32 device, we can run GUI applications based on libraries such as LVGL, in which frame buffers require a significant memory space (larger frame buffer = better image resolution, for example).
Alternatively, we can perform complex algorithms with a greater focus on the problem rather than on the space optimization (an issue often encountered in embedded systems development), or have freedom to allocate more memory for RTOS tasks.

I recently bought an ESP32-S3-DevKitC with 8MB of external PSRAM and 16MB of Flash.
My initial plan was to use it as a main controller for my smartwatch side project based on Zephyr RTOS.
Although I haven't found time to work on the side project yet, I decided at least to write about enabling PSRAM on ESP32, which could have been a small part of the project.

# Solution

SPI RAM size and Flash size can be checked on the metal shield of the module. They are curved as `N16R8`, which means 16 MB of Flash and 8MB of RAM. According to its naming convention, `N8R4` would mean 8MB of flash and 4MB of RAM.
On the other hand, if you don't trust the numbers on the module, you can install `esptool.py` tools from Espressif and run the following command in the console, while the dev kit is connected to your PC to find out:

```bash
esptool --port /dev/ttyACM0 flash-id
```

> I'm using Ubuntu as my host machine and /dev/ttyACM0 is the serial port of the dev kit. This may vary on different platforms.

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

> Older versions of `esptool` might produce the output in a different format.

The `esptool` versions may vary with the Zephyr version you use. To check which Zephyr version, its easier to print the `VERSION` file like this:

```bash
cat ${ZEPHYR_ROOT}/zephyr/VERSION

VERSION_MAJOR = 4
VERSION_MINOR = 2
PATCHLEVEL = 99
VERSION_TWEAK = 0
EXTRAVERSION =
```

Now we have confirmed that my esp32 module really has 16 MB of Flash and 8 MB of SPI RAM.
