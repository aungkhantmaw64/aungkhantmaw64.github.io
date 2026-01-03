---
title: Zephyr - General Purpose Input Output
series: Mastering Zephyr RTOS
tags:
  - Zephyr
date: 2026-01-03
---
_This article introduces GPIO API in Zephyr by showing how to blink user leds on the NRF5340-DK board._
# <!--more-->

We will use the following APIs to interact with GPIO devices:

- `gpio_is_ready_dt` - to validate if the GPIO port connected to the LEDs is ready.
- `gpio_pin_configure_dt` - to configure the LED pins as GPIO output that are turned off at initialization stage.
- `gpio_pin_interrupt_configure_dt` - to configure the push buttons as interrupt driven GPIO inputs.
- `gpio_pin_set_dt` - to turn on and off the LEDS.

We should also be familiar with the following data structures:

- `struct device` - a structure representing an instance of peripheral device. (gpio, i2c, spi, etc.)
- `struct gpio_dt_spec` - a structure containing data fields such as port, pin, and dt_flag.

The above structs must be created but should not be populated manually. Their values will be filled out by the Device Tree APIs such as `DEVICE_DT_GET` for `struct device` and `GPIO_DT_SPEC_GET` for `struct gpio_dt_spec`.

# Blinking LEDS

Let us enable GPIO APIs by setting CONFIG_GPIO=y in the prj.conf file:

```bash
CONFIG_GPIO=y
```

And include the following header files at the top of the main.c file:

```C
#include <zephyr/devicetree.h>
#include <zephyr/drivers/gpio.h>
#include <zephyr/kernel.h>
```

- `<zephyr/devicetree.h>` for device tree APIs
- `<zephyr/drivers/gpio.h>` for GPIO driver APIs
- `<zephyr/kernel.h>` for kernel services like `k_msleep` for delaying some period between on/off states of the LEDs.

We will obtain device tree specifications for each on-board LED using `GPIO_DT_SPEC_GET`. This macro populates an instance of `struct gpio_dt_spec` with properties defined in the device tree sources with the `gpio-leds` compatible. It takes two arguments: _node_id_ and _property_.

You can obtain the node_id of a device tree node using several APIs such as `DT_ALIAS`, `DT_CHOSEN`, `DT_NODELABEL`, etc. We will use `DT_NODELABEL` as it is more convenient to use the node labels (led0, led1, led2, and led3) in this example as they are already defined by the board-level source tree. If you are interested in other API, see this [link](https://docs.zephyrproject.org/latest/build/dts/api/api.html).

Board-level device tree for the four on-board leds of the NRF5340-DK:
```C
leds {
  compatible = "gpio-leds";
  led0: led_0 {
    gpios = <&gpio0 28 GPIO_ACTIVE_LOW>;
    label = "Green LED 0";
  };
  led1: led_1 {
    gpios = <&gpio0 29 GPIO_ACTIVE_LOW>;
    label = "Green LED 1";
  };
  led2: led_2 {
    gpios = <&gpio0 30 GPIO_ACTIVE_LOW>;
    label = "Green LED 2";
  };
  led3: led_2 {
    gpios = <&gpio0 31 GPIO_ACTIVE_LOW>;
    label = "Green LED 3";
  };
};
```

## Step 1 - Initialization
Here is one way to create instances representing the 4 LED pins in the global scope:

```c
const struct gpio_dt_spec led0 = GPIO_DT_SPEC_GET(DT_NODELABEL(led0), gpios);
const struct gpio_dt_spec led1 = GPIO_DT_SPEC_GET(DT_NODELABEL(led1), gpios);
const struct gpio_dt_spec led2 = GPIO_DT_SPEC_GET(DT_NODELABEL(led2), gpios);
const struct gpio_dt_spec led3 = GPIO_DT_SPEC_GET(DT_NODELABEL(led3), gpios);
```

The `GPIO_DT_SPEC_GET` macro uses the node id returned by `DT_NODELABEL` and use the `gpios` property to get the specifications of a GPIO pin. Although, the above code works, it contains some duplication and can be improved as follows:

```c
enum { LED0, LED1, LED2, LED3 };

const struct gpio_dt_spec led_dt_specs[4] = {
    [LED0] = GPIO_DT_SPEC_GET(DT_NODELABEL(led0), gpios),
    [LED1] = GPIO_DT_SPEC_GET(DT_NODELABEL(led1), gpios),
    [LED2] = GPIO_DT_SPEC_GET(DT_NODELABEL(led2), gpios),
    [LED3] = GPIO_DT_SPEC_GET(DT_NODELABEL(led3), gpios)};
```

The improve code packs all the device tree specs into a single array, which reduces code duplication and allows the repeated operations to be performed in a loop. Let us initialize the LEDs as GPIO pins as follows:

```c
int main() {
  for (size_t i = {0}; i < ARRAY_SIZE(led_dt_specs); i++) {
    if (!gpio_is_ready_dt(&led_dt_specs[i])) {
      printf("%s: pin %d is not ready.\n", led_dt_specs[i].port->name,
             led_dt_specs[i].pin);
      return -EBUSY;
    }
    printf("%s: pin %d is ready.\n", led_dt_specs[i].port->name,
           led_dt_specs[i].pin);
    int ret = gpio_pin_configure_dt(&led_dt_specs[i], GPIO_OUTPUT_INACTIVE);
    if (ret < 0) {
      printf("Failed to initialize %s: pin %d. Error code: %d",
             led_dt_specs[i].port->name, led_dt_specs[i].pin, ret);
      return ret;
    }
    printf("%s: pin %d is successfully initialized.\n",
           led_dt_specs[i].port->name, led_dt_specs[i].pin);
  }
  return 0;
}
```

First, we iterate through the `led_dt_specs` to do the same initialization steps for all the LED pins. `ARRAY_SIZE` macro returns the number of elements in the given array.

Before any initialization, the GPIO devices are checked if they are ready first with the `gpio_is_ready_dt` and then configured as a GPIO output pin with intial LOW state by calling the `gpio_pin_configure_dt` function with the `GPIO_OUTPUT_INACTIVE` flag.

Zephyr uses POSIX-compliant error codes where functions return non-zero integer values to indicate an issue in a operation. So, we check this error code in the above example and let the code break out of the main function if any device initialization did not succeed.

## Step 2 - Controlling GPIO Pins

Now we will make the LEDs blink one after another with 500 milliseconds intervals between on/off states within an infinite loop. k_msleep is an RTOS service that makes the current task (caller) enter sleep mode for a given time period in terms of milliseconds. gpio_pin_set_dt can be used to set the state of the given GPIO spec. It also returns an error code, which is omitted here for the sake of simplicity.

```c
/**
* Other initialization code
*/
while (1) {
  static int led_state = 1;
  for (size_t i = {0}; i < ARRAY_SIZE(led_dt_specs); i++) {
    gpio_pin_set_dt(&led_dt_specs[i], led_state);
    k_msleep(500);
    gpio_pin_set_dt(&led_dt_specs[i], !led_state);
    k_msleep(500);
  }
}
```

Here is the complete code for the blinky application.

```c
#include <zephyr/devicetree.h>
#include <zephyr/drivers/gpio.h>
#include <zephyr/kernel.h>

enum { LED0, LED1, LED2, LED3 };

const struct gpio_dt_spec led_dt_specs[4] = {
    [LED0] = GPIO_DT_SPEC_GET(DT_NODELABEL(led0), gpios),
    [LED1] = GPIO_DT_SPEC_GET(DT_NODELABEL(led1), gpios),
    [LED2] = GPIO_DT_SPEC_GET(DT_NODELABEL(led2), gpios),
    [LED3] = GPIO_DT_SPEC_GET(DT_NODELABEL(led3), gpios)};

int main() {
  for (size_t i = {0}; i < ARRAY_SIZE(led_dt_specs); i++) {
    if (!gpio_is_ready_dt(&led_dt_specs[i])) {
      printf("%s: pin %d is not ready.\n", led_dt_specs[i].port->name,
             led_dt_specs[i].pin);
      return -EBUSY;
    }
    printf("%s: pin %d is ready.\n", led_dt_specs[i].port->name,
           led_dt_specs[i].pin);
    int ret = gpio_pin_configure_dt(&led_dt_specs[i], GPIO_OUTPUT);
    if (ret < 0) {
      printf("Failed to initialize %s: pin %d. Error code: %d",
             led_dt_specs[i].port->name, led_dt_specs[i].pin, ret);
      return ret;
    }
    printf("%s: pin %d is successfully initialized.\n",
           led_dt_specs[i].port->name, led_dt_specs[i].pin);
  }
  while (1) {
    static int led_state = 1;
    for (size_t i = {0}; i < ARRAY_SIZE(led_dt_specs); i++) {
      gpio_pin_set_dt(&led_dt_specs[i], led_state);
      k_msleep(500);
      gpio_pin_set_dt(&led_dt_specs[i], !led_state);
      k_msleep(500);
    }
  }
  return 0;
}

```

Now if we build and flash the program using `west`, you will see the console log output as follows:

```bash
Welcome to minicom 2.8

OPTIONS: I18n
Port /dev/ttyACM1, 14:19:21

Press CTRL-A Z for help on special keys

*** Booting Zephyr OS build v3.7.0-1625-gf29377a12cb5 ***
gpio@842500: pin 28 is ready.
gpio@842500: pin 28 is successfully initialized.
gpio@842500: pin 29 is ready.
gpio@842500: pin 29 is successfully initialized.
gpio@842500: pin 30 is ready.
gpio@842500: pin 30 is successfully initialized.
gpio@842500: pin 31 is ready.
gpio@842500: pin 31 is successfully initialized.
```

## Step 3 - Working with GPIO Inputs
Now let us add button inputs for our Zephyr application. In the `nrf5340dk_common.dtsi`,the buttons are defined as:

```c
buttons {
    compatible = "gpio-keys";
    button0: button_0 {
            gpios = <&gpio0 23 (GPIO_PULL_UP | GPIO_ACTIVE_LOW)>;
            label = "Push button 1";
            zephyr,code = <INPUT_KEY_0>;
    };
    button1: button_1 {
            gpios = <&gpio0 24 (GPIO_PULL_UP | GPIO_ACTIVE_LOW)>;
            label = "Push button 2";
            zephyr,code = <INPUT_KEY_1>;
    };
    button2: button_2 {
            gpios = <&gpio0 8 (GPIO_PULL_UP | GPIO_ACTIVE_LOW)>;
            label = "Push button 3";
            zephyr,code = <INPUT_KEY_2>;
    };
    button3: button_3 {
            gpios = <&gpio0 9 (GPIO_PULL_UP | GPIO_ACTIVE_LOW)>;
            label = "Push button 4";
            zephyr,code = <INPUT_KEY_3>;
    };
};
```

From the above device tree, we will create another `struct gpio_dt_spec` array for the buttons:
```c
const struct gpio_dt_spec led_dt_specs[4] = {
    [BUTTON0] = GPIO_DT_SPEC_GET(DT_NODELABEL(button0), gpios),
    [BUTTON1] = GPIO_DT_SPEC_GET(DT_NODELABEL(button1), gpios),
    [BUTTON2] = GPIO_DT_SPEC_GET(DT_NODELABEL(button2), gpios),
    [BUTTON3] = GPIO_DT_SPEC_GET(DT_NODELABEL(button3), gpios)};
```

From the device tree, we can say that buttons are pulled up by default. So, we should configures these pins as interrupt driven pins which triggers on the pin state change to zero with `gpio_pin_interrupt_configure_dt` and the `GPIO_INT_EDGE_TO_INACTIVE` flag.

```c
// Initializes the Buttons
for (size_t i = {0}; i < ARRAY_SIZE(button_dt_specs); i++) {
   if (!gpio_is_ready_dt(&button_dt_specs[i])) {
      printk("%s: pin %d is not ready.\n",
             button_dt_specs[i].port->name,
             button_dt_specs[i].pin);
      return -EBUSY;
    }
    int ret = gpio_pin_configure_dt(&button_dt_specs[i],
                                   GPIO_INPUT);
    if (ret < 0) {
      printk("Failed to initialize %s: pin %d as GPIO input.
      Error code: %d",
             button_dt_specs[i].port->name,
             button_dt_specs[i].pin, ret);
      return ret;
    }

    ret = gpio_pin_interrupt_configure_dt(
                    &button_dt_specs[i],
                    GPIO_INT_EDGE_TO_INACTIVE);
    if (ret < 0) {
      printf("Failed to initialize %s: pin %d. Error code: %d",
             button_dt_specs[i].port->name,
             button_dt_specs[i].pin,
             ret);
      return ret;
    }
    printk("%s: pin %d is successfully initialized.\n",
           button_dt_specs[i].port->name, button_dt_specs[i].pin);
}
```

We create callback functions/interrupt service routines for each button GPIO pin.

```C
static uint8_t button_pin_pushed = {0};

void on_button0_pressed(const struct device *dev, struct gpio_callback *cb, uint32_t pins) {
  printk("Button 0 pressed.\n");
  button_pin_pushed = BUTTON0;
}

void on_button1_pressed(const struct device *dev, struct gpio_callback *cb, uint32_t pins) {
  printk("Button 1 pressed.\n");
  button_pin_pushed = BUTTON1;
}

void on_button2_pressed(const struct device *dev, struct gpio_callback *cb, uint32_t pins) {
  printk("Button 2 pressed.\n");
  button_pin_pushed = BUTTON2;
}

void on_button3_pressed(const struct device *dev, struct gpio_callback *cb, uint32_t pins) {
  printk("Button 3 pressed.\n");
  button_pin_pushed = BUTTON3;
}
```

Every time one of the callbacks is executed, we assign the global variable, button_pin_pushed, with the enum value representing the “Push” event so that the LEDs can be turned on with different patterns based on these button events.
The following two functions are required for this purpose.

- `gpio_init_callback`
- `gpio_add_callback`

We can call these two functions in the button initialization loop like this:

```C
// Initializes the Buttons
for (size_t i = {0}; i < ARRAY_SIZE(button_dt_specs); i++) {
/**
* Do other stuffs
**/
gpio_init_callback(&button_cb_data[i], button_handlers[i],
                       BIT(button_dt_specs[i].pin));
gpio_add_callback(button_dt_specs[i].port, &button_cb_data[i]);
/**
* Do other stuffs
**/
}

```

`button_handlers` and `button_cb_data` holds an array of button callback and callback data, respectively. These two are declared as global variables at the top of the file as:

```c
static const gpio_callback_handler_t button_handlers[4] = {
    on_button0_pressed, on_button1_pressed, on_button2_pressed,
    on_button3_pressed};

static struct gpio_callback button_cb_data[4] = {0};
```

We can now flash the program into the board to see how the LEDs behave. 