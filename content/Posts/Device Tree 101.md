---
title: Device Tree 101
date: 2026-01-03
hideToc: false
tags:
  - Zephyr
---

_This article explains device trees and how they are used in ZephyrProject_

## <!--more-->

## Device Tree File Formats

Device tree files use one of these extensions: `.dtsi`, `.dts`, or `.overlay`. 
In this context, `dts` stands for **'device tree source,'** while `dtsi` stands for **'device tree source include,'** as the contents of `.dtsi` files are usually included by other higher-level device tree files. Therefore, `.dtsi` files commonly contain SoC-level definitions, whereas `.dts` files contain board-level definitions. Both types of files use the same syntax, and the choice of extension is based on conventions.

In terms of properties, the file extensions do not differ. However, another type of device tree source file, called **overlays**, is often used to override the default properties in the built-in `.dts` files.

> For application development, it is a good practice to use overlays than to modify the built-in sources provided by Zephyr.

Before we dive into Devicetree APIs in those generated headers, let us look at some of the built-in Zephyr device tree sources files to get familiar with the syntax and learn how we can write, extend or modify these sources in our own applications.

---
## Device Tree Syntax

Every tree-like structure has a **_root_** and **_child_** (or leaf) nodes, and the device tree is no different. In a device tree, every node has an ID and properties that define its characteristics. The root node is represented as `/`, while child nodes can be named according to the context. Here is the basic syntax for a device tree source file.

```bash
// Root Node
  / {
  // Child Node
  node_a {
      // Node properties here
         };
  // Child Node
  node_b {
      // Node properties here
         };
    };
```

The device tree above shows a root (`/`) with two child nodes: `node_a` and `node_b`. Properties for each node go inside curly braces and end with a semicolon (`;`).

Since there are a lot of properties in the Zephyr bindings index, we will focus on just a few standard ones and those relevant to the example nodes in this article. However, if you’re curious about all the details, you can check out the device tree [specifications](https://www.devicetree.org/specifications/) or the Zephyr [bindings index](https://docs.zephyrproject.org/latest/build/dts/api/bindings.html) for more info on Zephyr-specific properties.

---
## Device Tree Properties

Each property of a tree node is a name and value pair, which is normally written with the following syntax.

Property values come in different types with their own syntax. We will look at a few common ones that you will often see in board-level and SoC-level Zephyr device trees, like `int`,`boolean`, `string`, `phandle`, and `array`. If you run into a type that is not covered here, you can always check the device tree specification for more details.

### Property Value Types
#### Integer
`Integer` type properties usually represent single values, like `clock-frequency` or `easydma-maxcnt-bits`, where you just need to set one value for these hardware parameters. You can describe an integer property like this, where 10000 is the 32-bit integer value:

```bash
my-int32-prop=<10000>;
```

Whether the value is in _Hz_ or _MHz_ depends on how the property is defined in the device tree bindings. Also, if you need to use a 64-bit integer, it should be written as two 32-bit values in big-endian order:

```bash
my-u64-prop=<0x12345678 0x9ABCDEF0>;
```

In device tree specs, a “cell” is defined as a 32-bit unit of information.
#### Boolean
`Boolean` type properties are often used to indicate whether a feature exists in a node. These properties are sometimes called 'empty properties' because the property name is written without any value on the right side to show a true status. If the property is missing, it means false.
#### String

`String` type properties are obviously a double quoted text written as:

```bash
my-string-prop=”hello”;
```
#### Phandle
`Phandle` type properties are like pointers in C. Instead of pointing to a memory address, a node can be referenced with a phandle by using (&) followed by the node name:

```bash
my_node {
// Write properties here
};

&my_node {
// Using phandle to overwrite properties of my_node
};

other_node {
// Using phanle as a property value
phandle-to-my_node=&my_node;
};
```

> The syntax above also shows that you can overwrite or extend a node's characteristics using a phandle. This approach is sometimes used with device tree overlays, which we will cover later in this series.
#### Array
`Array` type properties are collections of values. There are different types of arrays: array (32-bit), uint8-array, string-array, phandles, and phandle-array. Here’s how you can describe them:

---
## Q&A

> **Q: Why are some values written in hex format and some in decimal in my-array?**

> **A**: In Zephyr, integer values are usually assumed to be 32-bit by default. You can write a 32-bit integer in either hex or decimal format—whichever you prefer. The example above is just for demonstration. But be careful with integers of other sizes. For example, an 8-bit integer in my-uint8-array should be written in hex format without the 0x prefix, and a 64-bit value should use the 2-cell format as described earlier.

> **Q: Why are there two types of arrays that contain phandles?**

> **A**: It can be a bit confusing at first. A phandle is like a reference or pointer to a node, so a phandles is essentially a list of these “references”. On the other hand, a phandle-array includes compound elements where each element consists of a phandle and additional cells called specifiers. The details of what each specifier means or how many there are in a particular phandle are defined in the bindings.