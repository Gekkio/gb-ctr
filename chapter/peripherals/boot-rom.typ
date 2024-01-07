#import "../../common.typ": *

== Boot ROM

The Game Boy SoC includes a small embedded boot ROM, which can be mapped to the #hex-range("0000", "00FF") memory area. While mapped, all reads from this area are handled by the boot ROM instead of the external cartridge, and all writes to this area are ignored and cannot be seen by external hardware (e.g. the cartridge MBC).

The boot ROM is enabled by default, so when the system exits the reset state and the CPU starts execution from address #hex("0000"), it executes the boot ROM instead of instructions from the cartridge ROM. The boot ROM is responsible for showing the initial logo, and checking that a valid cartridge is inserted into the system. If the cartridge is valid, the boot ROM unmaps itself before execution of the cartridge ROM starts at #hex("0100"). The cartridge ROM has no chance of executing any instructions before the boot ROM is unmapped, which prevents the boot ROM from being read byte by byte in normal conditions.

#warning[
  Don't confuse the boot ROM with the additional SNES ROM in SGB/SGB2 that is
  executed by the SNES CPU.
]

#reg-figure(
  caption: [#hex("FF50") - BOOT - Boot ROM lock register]
)[
  #reg-table(
    [U], [U], [U], [U], [U], [U], [U], [R/W-0],
    unimpl-bit(), unimpl-bit(), unimpl-bit(), unimpl-bit(), unimpl-bit(), unimpl-bit(), unimpl-bit(), [BOOT_OFF],
    [bit 7], [6], [5], [4], [3], [2], [1], [bit 0]
  )
  #set align(left)
  #grid(
    columns: (auto, 1fr),
    gutter: 1em,
    [*bit 7-1*], [*Unimplemented*: Ignored during writes, reads are undefined],
    [*bit 0*], [
      *BOOT_OFF*: Boot ROM lock bit\
      #bin("1") = Boot ROM is disabled and #hex-range("0000", "00FF") works normally.\
      #bin("0") = Boot ROM is active and intercepts accesses to #hex-range("0000", "00FF").

      #v(1em)

      BOOT_OFF can only transition from #bin("0") to #bin("1"), so once #bin("1") has been written, the boot ROM is permanently disabled until the next system reset. Writing #bin("0") when BOOT_OFF is #bin("0") has no effect and doesn't lock the boot ROM.
    ]
  )
]

The 1-bit BOOT register controls mapping of the boot ROM. Once #bin("1") has been written to it to unmap the boot ROM, it can only be mapped again by resetting the system.

=== Boot ROM types

#show raw: set text(7pt)
#figure(
  table(
    columns: 4,
    align: left + horizon,
    [Type], [CRC32], [MD5], [SHA1],
    [DMG], `59c8598e`, `32fbbd84168d3482956eb3c5051637f5`, `4ed31ec6b0b175bb109c0eb5fd3d193da823339f`,
    [MGB], `e6920754`, `71a378e71ff30b2d8a1f02bf5c7896aa`, `4e68f9da03c310e84c523654b9026e51f26ce7f0`,
    [SGB], `ec8a83b9`, `d574d4f9c12f305074798f54c091a8b4`, `aa2f50a77dfb4823da96ba99309085a3c6278515`,
    [SGB2], `53d0dd63`, `e0430bca9925fb9882148fd2dc2418c1`, `93407ea10d2f30ab96a314d8eca44fe160aea734`,
    [DMG0], `c2f5cc97`, `a8f84a0ac44da5d3f0ee19f9cea80a8c`, `8bd501e31921e9601788316dbd3ce9833a97bcbc`,
  ),
  caption: "Summary of boot ROM file hashes"
)

==== DMG boot ROM

The most common boot ROM is the DMG boot ROM used in almost all original Game Boy units. If a valid cartridge is inserted, the boot ROM scrolls a logo to the center of the screen, and plays a "di-ding" sound recognizable by most people who have used Game Boy consoles.

This boot ROM was originally dumped by neviksti in 2003 by decapping the Game Boy SoC and visually inspecting every single bit.

==== MGB boot ROM

This boot ROM was originally dumped by Bennvenn in 2014 by using a simple clock glitching method that only requires one wire.

==== SGB boot ROM

This boot ROM was originally dumped by Costis Sideris in 2009 by using an FPGA-based clock glitching method @costis_sgb.

==== SGB2 boot ROM

This boot ROM was originally dumped by gekkio in 2015 by using a Teensy 3.1 -based clock glitching method @gekkio_sgb2.

==== Early DMG boot ROM ("DMG0")

Very early original Game Boy units released in Japan (often called "DMG0") included the launch version "DMG-CPU" SoC chip, which used a different boot ROM than later units.

This boot ROM was originally dumped by gekkio in 2016 by using a clock glitching method invented by BennVenn.
