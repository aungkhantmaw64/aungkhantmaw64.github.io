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

## My New Toy, ESP32S3

I recently bought an `ESP32-S3-DevKitC` with `8MB` of external PSRAM and `16MB` of Flash.
My initial plan was to use it as a main controller for my smartwatch side project based on Zephyr RTOS.
Although I haven't found time to work on the side project yet, I decided at least to write about enabling PSRAM on ESP32, which could have been a small part of the project.

This module is specifically chosen for running high-end UI applications using libraries such as LVGL, where frame buffers consume a relatively large amount of RAM to render high-resolution vector graphics.
For example, consider **GC9A01** LCD display driver with a resolution of **240 x 240** pixels. If our application requires a color depth of `RGB565` (16-bit) and double buffering, the total RAM required would be approximately **233** KB. This is close to the size of the built-in SRAM, that is **512KB**.

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

We have verified that my ESP32 module does indeed have 16 MB of Flash and 8 MB of SPI RAM.

> Although the above output does not specify the types of SPI peripherals, the flash interfaces with Quad SPI, while the PSRAM interfaces Octal SPI, according to the [datasheet](https://www.espressif.com/sites/default/files/documentation/esp32-s3-wroom-1_wroom-1u_datasheet_en.pdf).

Now, let's move to a Zephyr project and see how we can utilize this extra RAM and flash sizes to our advantage.
The PSRAM will not work out of the box, as Zephyr does not have the capability to automatically detect it.
We have to specify the memory configuration using the device-tree and Kconfig.

## References

- UIs on Embedded System - <https://blog.st.com/uis-on-embedded-systems/>
- ESP32S3-WROOM datasheet - <https://www.espressif.com/sites/default/files/documentation/esp32-s3-wroom-1_wroom-1u_datasheet_en.pdf>
