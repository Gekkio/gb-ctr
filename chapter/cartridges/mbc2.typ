#import "../../common.typ": *

== MBC2 mapper chip

MBC2 supports ROM sizes up to 2 Mbit (16 banks of #hex("4000") bytes) and includes an internal 512x4 bit RAM array, which is its unique feature. The information in this section is based on my MBC2 research, Tauwasser's research notes @tauwasser_mbc2, and Pan Docs @pandocs.

#speculation[
  MBC1 is strictly more powerful than MBC2 because it supports more ROM and RAM. This raises a very important question: why does MBC2 exist? It's possible that Nintendo tried to integrate a small amount of RAM on the MBC chip for cost reasons, but it seems that this didn't work out very well since all later MBCs revert this design decision and use separate RAM chips.
]

=== MBC2 registers

#caveat[
  These registers don't have any standard names and are usually referred to using one of their addresses or purposes instead. This document uses names to clarify which register is meant when referring to one.
]

The MBC2 chip includes two registers that affect the behaviour of the chip. The registers are mapped a bit differently compared to other MBCs. Both registers are accessible within #hex-range("0000", "3FFF"), and within that range, the register is chosen based on the A8 address signal. In practice, this means that the registers are mapped to memory in an alternating pattern. For example, #hex("0000"), #hex("2000") and #hex("3000") are RAMG, and #hex("0100"), #hex("2100") and #hex("3100") are ROMB. Both registers are smaller than 8 bits, and unused bits are simply ignored during writes. The registers are not directly readable.

#reg-figure(
  caption: [#hex-range("0000", "3FFF") when A8=#bin("0") - RAMG - MBC2 RAM gate register]
)[
  #reg-table(
    [U], [U], [U], [U], [W-0], [W-0], [W-0], [W-0],
    unimpl-bit(), unimpl-bit(), unimpl-bit(), unimpl-bit(), table.cell(colspan: 4)[RAMG\<3:0\>],
    [bit 7], [6], [5], [4], [3], [2], [1], [bit 0]
  )
  #set align(left)
  #grid(
    columns: (auto, 1fr),
    gutter: 1em,
    [*bit 7-4*], [*Unimplemented*: Ignored during writes],
    [*bit 3-0*], [
      *RAMG\<3:0\>*: RAM gate register\
      #bin("1010") = enable access to chip RAM\
      All other values disable access to chip RAM
    ]
  )
]

The 4-bit MBC2 RAMG register works in a similar manner as MBC1 RAMG, so the upper bits don't matter and only the bit pattern #bin("1010") enables access to RAM.

When RAM access is disabled, all writes to the external RAM area #hex-range("A000", "BFFF") are ignored, and reads return undefined values. Pan Docs recommends disabling RAM when it's not being accessed to protect the contents @pandocs.

#speculation[
  We don't know the physical implementation of RAMG, but it's certainly possible that the #bin("1010") bit pattern check is done at write time and the register actually consists of just a single bit.
]

#reg-figure(
  caption: [#hex-range("0000", "3FFF") when A8=#bin("1") - ROMB - MBC2 ROM bank register]
)[
  #reg-table(
    [U], [U], [U], [U], [W-0], [W-0], [W-0], [W-1],
    unimpl-bit(), unimpl-bit(), unimpl-bit(), unimpl-bit(), table.cell(colspan: 4)[ROMB\<3:0\>],
    [bit 7], [6], [5], [4], [3], [2], [1], [bit 0]
  )
  #set align(left)
  #grid(
    columns: (auto, 1fr),
    gutter: 1em,
    [*bit 3-0*], [
      *ROMB\<3:0\>*: ROM bank register\
      Never contains the value #bin("0000").\
      If #bin("0000") is written, the resulting value will be #bin("0001") instead.
    ]
  )
]

The 4-bit ROMB register is used as the ROM bank number when the CPU accesses the #hex-range("4000", "7FFF") memory area.

Like MBC1 BANK1, the MBC2 ROMB register doesn't allow zero (bit pattern #bin("0000")) in the register, so any attempt to write #bin("0000") writes #bin("0001") instead.

=== ROM in the #hex-range("0000", "7FFF") area

In MBC2 cartridges, the A0-A13 cartridge bus signals are connected directly to the corresponding ROM pins, and the remaining ROM pins (A14-A17) are controlled by the MBC2. These remaining pins form the ROM bank number.

When the #hex-range("0000", "3FFF") address range is accessed, the effective bank number is always 0.

When the #hex-range("4000", "7FFF") address range is accessed, the effective bank number is the current ROMB register value.

#figure(
  table(
    columns: 3,
    stroke: (y: none),
    align: center,
    table.hline(),
    [], table.cell(colspan: 2)[ROM address bits],
    [Accessed address], [Bank number], [Address within bank],
    table.hline(),
    [], [17-14], [13-0],
    table.hline(),
    hex-range("0000", "3FFF"), bin("0000"), [A\<13:0\>],
    table.hline(),
    hex-range("4000", "7FFF"), [ROMB], [A\<13:0\>],
    table.hline(),
  ),
  kind: table,
  caption: "Mapping of physical ROM address bits in MBC2 carts"
)

=== RAM in the #hex-range("A000", "BFFF") area

All MBC2 carts include SRAM, because it is located directly inside the MBC2 chip. These cartridges never use a separate RAM chip, but battery backup circuitry and a battery are optional. If RAM is not enabled with the RAMG register, all reads return undefined values and writes have no effect.

MBC2 RAM is only 4-bit RAM, so the upper 4 bits of data do not physically exist in the chip. When writing to it, the upper 4 bits are ignored. When reading from it, the upper 4 data signals are not driven by the chip, so their content is undefined and should not be relied on.

MBC2 RAM consists of 512 addresses, so only A0-A8 matter when accessing the RAM region. There is no banking, and the #hex-range("A000", "BFFF") area is larger than the RAM, so the addresses wrap around. For example, accessing #hex("A000") is the same as accessing #hex("A200"), so it is possible to write to the former address and later read the written data using the latter address.

#figure(
  table(
    columns: 2,
    stroke: (y: none),
    align: center + bottom,
    table.hline(),
    [], [RAM address bits],
    [Accessed address], [],
    table.hline(),
    [], [8-0],
    table.hline(),
    hex-range("A000", "BFFF"), [A\<8:0\>],
    table.hline(),
  ),
  kind: table,
  caption: "Mapping of physical RAM address bits in MBC2 carts"
)

=== Dumping MBC2 carts

MBC2 cartridges are very simple to dump. The total number of banks is read from the header, and each bank is read one byte at a time. ROMB zero adjustment must be considered in the ROM dumping code, but this only means that bank 0 should be read from #hex-range("0000", "3FFF") and not from #hex-range("4000", "7FFF") like other banks.

#figure(
  raw(read("../../code-snippets/mbc2_rom_dump.py"), lang: "python", block: true),
  caption: "Python pseudo-code for MBC2 ROM dumping"
)
