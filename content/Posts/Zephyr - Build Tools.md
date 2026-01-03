---
title: Zephyr - Build Tools
date: 2026-01-03
series: Mastering Zephyr RTOS
hideToc: false
tags:
  - Zephyr
---
_This article explains how to use zephyr build tools to build, flash and monitor the firmware._

## <!--more-->

# West
**West** is a meta-tool provided by Zephyr that allows you to build, flash, debug Zephyr application, sign binaries and do many other interesting tasks. West deserves a separate article for a deeper exploration but here, we will only introduce a few use cases of west that are relevant to this article.

## Checking Supported Boards
As a first step, we can find out which boards are supported by Zephyr without going to the documentation page by running:

```bash
west boards
```

Results:

```bash
root@3d1a07d63aab:/opt/zephyrproject/zephyr/workshop# west boards
weact_stm32f405_core
blackpill_f401ce
mini_stm32h743
blackpill_f411ce
blackpill_f401cc
weact_stm32g431_core
b_u585i_iot02a
stm32g071b_disco
nucleo_l4r5zi
nucleo_u5a5zj_q
steval_fcu001v1
nucleo_f030r8
stm32h750b_dk
..
..
```

The results show a long list of supported boards. To narrow down the list, we can use filters with the `-n` option. We will use the option with `nrf` keyword to check if our NRF5340DK board is included in the list:

```bash
west boards -n nrf
```

Results:

```bash
root@3d1a07d63aab:/opt/zephyrproject/zephyr/workshop# west boards -n nrf
nrf52_vbluno52
nrf51_vbluno51
nrf52_sparkfun
nrf52840_papyr
nrf52840_blip
nrf52832_mdk
nrf52840_mdk_usb_dongle
nrf52840_mdk
nrf52_adafruit_feather
adafruit_feather_nrf52840_express
adafruit_feather_nrf52840_sense
nrf9151dk
nrf52840dongle
nrf9131ek
nrf54l15pdk
nrf52833dk
nrf52840dk
nrf5340dk
..
```

Great! The list shows all the boards with names containing the keyword, "nrf", including our board, nrf5340dk. You can also use the `-f` option to print more detailed information about the boards with your preferred format:

```bash
west boards -f "{name} => {qualifiers}" -n nrf
```

Results:

```bash
root@3d1a07d63aab:/opt/zephyrproject/zephyr/workshop# west boards -f "{name} => {qualifiers}" -n nrf
nrf52_vbluno52 => nrf52832
nrf51_vbluno51 => nrf51822
nrf52_sparkfun => nrf52832
nrf52840_papyr => nrf52840
nrf52840_blip => nrf52840
nrf52832_mdk => nrf52832
nrf52840_mdk_usb_dongle => nrf52840
nrf52840_mdk => nrf52840
nrf52_adafruit_feather => nrf52832
adafruit_feather_nrf52840_express => nrf52840
adafruit_feather_nrf52840_sense => nrf52840
nrf9151dk => nrf9151,nrf9151/ns
nrf52840dongle => nrf52840
nrf9131ek => nrf9131,nrf9131/ns
nrf54l15pdk => nrf54l15/cpuapp,nrf54l15/cpuflpr,nrf54l15/cpuflpr/xip
nrf52833dk => nrf52820,nrf52833
nrf52840dk => nrf52840,nrf52811
...
```

Now that you know your board’s name, you can now use `west` to print out information specifically for your board by specifying its name with the `—board` option:

```bash
west boards -f "{name} => {qualifiers}" --board nrf5340dk
```

Results:

```bash
root@3d1a07d63aab:/opt/zephyrproject/zephyr/workshop# west boards -f "{name} => {qualifiers}" --board nrf5340dk
nrf5340dk => nrf5340/cpuapp,nrf5340/cpuapp/ns,nrf5340/cpunet
```

The `qualifiers` is a useful parameter needed during the build process to specify details about your build target. For example, if you're building a non-secure version of your application firmware, you would use `nrf5340/cpuapp/ns`. If you're targeting the network core of the NRF5340 SoC, you would use `nrf5340/cpunet`.
## Building The Firmware

Now, let us build the firmware with the following west build command and since we do not want to consider the security features yet, we will just use the qualifier for the simple application target, nrf5340/cpuapp:

```bash
west build -p always -b nrf5340dk/nrf5340/cpuapp apps/blinky
```

Results:

```bash
root@6d014c305b28:/opt/zephyrproject/zephyr/workshop# west build -p always -b nrf5340dk/nrf5340/cpuapp apps/blinky

-- west build: making build dir /opt/zephyrproject/zephyr/workshop/build pristine
-- west build: generating a build system
Loading Zephyr default modules (Zephyr base).
-- Application: /opt/zephyrproject/zephyr/workshop/apps/blinky
-- CMake version: 3.25.1
-- Found Python3: /opt/zephyrproject/.venv/bin/python3 (found suitable version "3.11.2", minimum required is "3.8") found components: Interpreter
-- Cache files will be written to: /root/.cache/zephyr
-- Zephyr version: 3.7.99 (/opt/zephyrproject/zephyr)
-- Found west (found suitable version "1.2.0", minimum required is "0.14.0")
-- Board: nrf5340dk, qualifiers: nrf5340/cpuapp
-- ZEPHYR_TOOLCHAIN_VARIANT not set, trying to locate Zephyr SDK
-- Found host-tools: zephyr 0.16.5 (/zephyr-sdk-0.16.5)
-- Found toolchain: zephyr 0.16.5 (/zephyr-sdk-0.16.5)
-- Found Dtc: /zephyr-sdk-0.16.5/sysroots/x86_64-pokysdk-linux/usr/bin/dtc (found suitable version "1.6.0", minimum required is "1.4.6")
-- Found BOARD.dts: /opt/zephyrproject/zephyr/boards/nordic/nrf5340dk/nrf5340dk_nrf5340_cpuapp.dts
-- Generated zephyr.dts: /opt/zephyrproject/zephyr/workshop/build/zephyr/zephyr.dts
-- Generated devicetree_generated.h: /opt/zephyrproject/zephyr/workshop/build/zephyr/include/generated/zephyr/devicetree_generated.h
-- Including generated dts.cmake file: /opt/zephyrproject/zephyr/workshop/build/zephyr/dts.cmake
Parsing /opt/zephyrproject/zephyr/Kconfig
Loaded configuration '/opt/zephyrproject/zephyr/boards/nordic/nrf5340dk/nrf5340dk_nrf5340_cpuapp_defconfig'
Merged configuration '/opt/zephyrproject/zephyr/workshop/apps/blinky/prj.conf'
Configuration saved to '/opt/zephyrproject/zephyr/workshop/build/zephyr/.config'
Kconfig header saved to '/opt/zephyrproject/zephyr/workshop/build/zephyr/include/generated/zephyr/autoconf.h'
-- Found GnuLd: /zephyr-sdk-0.16.5/arm-zephyr-eabi/arm-zephyr-eabi/bin/ld.bfd (found version "2.38")
-- The C compiler identification is GNU 12.2.0
-- The CXX compiler identification is GNU 12.2.0
-- The ASM compiler identification is GNU
-- Found assembler: /zephyr-sdk-0.16.5/arm-zephyr-eabi/bin/arm-zephyr-eabi-gcc
-- Using ccache: /usr/bin/ccache
-- Configuring done
-- Generating done
-- Build files have been written to: /opt/zephyrproject/zephyr/workshop/build
-- west build: building application
[1/135] Preparing syscall dependency handling

[2/135] Generating include/generated/zephyr/version.h
-- Zephyr version: 3.7.99 (/opt/zephyrproject/zephyr), build: v3.7.0-1625-gf29377a12cb5
[135/135] Linking C executable zephyr/zephyr.elf
Memory region         Used Size  Region Size  %age Used
           FLASH:       19884 B         1 MB      1.90%
             RAM:        4416 B       448 KB      0.96%
        IDT_LIST:          0 GB        32 KB      0.00%
Generating files from /opt/zephyrproject/zephyr/workshop/build/zephyr/zephyr.elf for board: nrf5340dk

```

The `-p` option stands for pristine, with three choices available: `always`, `never`, and `auto`. In the example above, always means that each time the command is run, the existing build directory will be cleaned, and the application will be rebuilt from scratch. The auto choice allows the build system to decide whether everything or just part of the application needs to be rebuilt.

While the always pristine build ensures a clean build, it can be significantly slower than auto for large codebases. So, choose this option wisely to control the build process.
## Flashing The Firmware Into The Target

Now connect your board to the PC and flash the firmware with:

```bash
west flash
```

Results:

```bash
root@811c26a4fc90:/opt/zephyrproject/zephyr/workshop# west flash

-- west flash: rebuilding
[0/16] Performing build step for 'tfm'
ninja: no work to do.
[2/13] Performing install step for 'tfm'
-- Install configuration: "MinSizeRel"
----- Installing platform NS -----
[13/13] Linking C executable zephyr/zephyr.elf
Memory region         Used Size  Region Size  %age Used
           FLASH:       20784 B       192 KB     10.57%
             RAM:        4544 B       192 KB      2.31%
        IDT_LIST:          0 GB        32 KB      0.00%
Generating files from /opt/zephyrproject/zephyr/workshop/build/zephyr/zephyr.elf for board: nrf5340dk
image.py: sign the payload
image.py: sign the payload
-- west flash: using runner nrfjprog
-- runners.nrfjprog: reset after flashing requested

```

## Monitoring The Logs
You can use serial monitor software like `minicom` to see the console output from the DK board UART. Specify the port with the `-D` option, in this case `/dev/ttyACM1`. This can be different on your host platform:

```bash
minicom -D /dev/ttyACM1
```

Results:

```bash
Welcome to minicom 2.8

OPTIONS: I18n
Port /dev/ttyACM1, 11:12:14

Press CTRL-A Z for help on special keys

*** Booting Zephyr OS build v3.7.0-1625-gf29377a12cb5 ***
Hello world
```

> If you do not see the log, try pushing the reset button as it might have already been printed out and the console did not catch it.