#import "../../common.typ": *

== MBC1 mapper chip

The majority of games for the original Game Boy use the MBC1 chip. MBC1 supports ROM sizes up to 16 Mbit (128 banks of #hex("4000") bytes) and RAM sizes up to 256 Kbit (4 banks of #hex("2000") bytes). The information in this section is based on my MBC1 research, Tauwasser's research notes @tauwasser_mbc1, and Pan Docs @pandocs.

=== MBC1 registers

#caveat[
  These registers don't have any standard names and are usually referred to using their address ranges or purposes instead. This document uses names to clarify which register is meant when referring to one.
]

The MBC1 chip includes four registers that affect the behaviour of the chip. Of the cartridge bus address signals, only A13-A15 are connected to the MBC, so lower address bits don't matter when the CPU is accessing the MBC and all registers are effectively mapped to address ranges instead of single addresses. All registers are smaller than 8 bits, and unused bits are simply ignored during writes. The registers are not directly readable.

#reg-figure(
  caption: [#hex-range("0000", "1FFF") - RAMG - MBC1 RAM gate register]
)[
  #reg-table(
    [U], [U], [U], [U], [W-0], [W-0], [W-0], [W-0],
    unimpl-bit(), unimpl-bit(), unimpl-bit(), unimpl-bit(), colspanx(4)[RAMG\<3:0\>],
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

The RAMG register is used to enable access to the cartridge SRAM if one exists on the cartridge circuit board. RAM access is disabled by default but can be enabled by writing to the #hex-range("0000", "1FFF") address range a value with the bit pattern #bin("1010") in the lower nibble. Upper bits don't matter, but any other bit pattern in the lower nibble disables access to RAM.

When RAM access is disabled, all writes to the external RAM area #hex-range("A000", "BFFF") are ignored, and reads return undefined values. Pan Docs recommends disabling RAM when it's not being accessed to protect the contents @pandocs.

#speculation[
  We don't know the physical implementation of RAMG, but it's certainly possible that the #bin("1010") bit pattern check is done at write time and the register actually consists of just a single bit.
]

#reg-figure(
  caption: [#hex-range("2000", "3FFF") - BANK1 - MBC1 bank register 1]
)[
  #reg-table(
    [U], [U], [U], [W-0], [W-0], [W-0], [W-0], [W-1],
    unimpl-bit(), unimpl-bit(), unimpl-bit(), colspanx(5)[BANK1\<4:0\>],
    [bit 7], [6], [5], [4], [3], [2], [1], [bit 0]
  )
  #set align(left)
  #grid(
    columns: (auto, 1fr),
    gutter: 1em,
    [*bit 7-5*], [*Unimplemented*: Ignored during writes],
    [*bit 4-0*], [
      *BANK1\<4:0\>*: Bank register 1\
      Never contains the value #bin("00000").\
      If #bin("00000") is written, the resulting value will be #bin("00001") instead.
    ]
  )
]

The 5-bit BANK1 register is used as the lower 5 bits of the ROM bank number when the CPU accesses the #hex-range("4000", "7FFF") memory area.

MBC1 doesn't allow the BANK1 register to contain zero (bit pattern #bin("00000")), so the initial value at reset is #bin("00001") and attempting to write #bin("00000") will write #bin("00001") instead. This makes it impossible to read banks #hex("00"), #hex("20"), #hex("40") and #hex("60") from the #hex-range("4000", "7FFF") memory area, because those bank numbers have #bin("00000") in the lower bits. Due to the zero value adjustment, requesting any of these banks actually requests the next bank (e.g.  #hex("21") instead of #hex("20")).

#reg-figure(
  caption: [#hex-range("2000", "3FFF") - BANK1 - MBC1 bank register 2]
)[
  #reg-table(
    [U], [U], [U], [U], [U], [U], [W-0], [W-0],
    unimpl-bit(), unimpl-bit(), unimpl-bit(), unimpl-bit(), unimpl-bit(), unimpl-bit(), colspanx(2)[BANK2\<1:0\>],
    [bit 7], [6], [5], [4], [3], [2], [1], [bit 0]
  )
  #set align(left)
  #grid(
    columns: (auto, 1fr),
    gutter: 1em,
    [*bit 7-2*], [*Unimplemented*: Ignored during writes],
    [*bit 1-0*], [
      *BANK2\<1:0\>*: Bank register 2
    ]
  )
]

The 2-bit BANK2 register can be used as the upper bits of the ROM bank number, or as the 2-bit RAM bank number. Unlike BANK1, BANK2 doesn't disallow zero, so all 2-bit values are possible.

#reg-figure(
  caption: [#hex-range("6000", "7FFF") - MODE - MBC1 mode register]
)[
  #reg-table(
    [U], [U], [U], [U], [U], [U], [U], [W-0],
    unimpl-bit(), unimpl-bit(), unimpl-bit(), unimpl-bit(), unimpl-bit(), unimpl-bit(), unimpl-bit(), [MODE],
    [bit 7], [6], [5], [4], [3], [2], [1], [bit 0]
  )
  #set align(left)
  #grid(
    columns: (auto, 1fr),
    gutter: 1em,
    [*bit 7-1*], [*Unimplemented*: Ignored during writes],
    [*bit 0*], [
      *MODE*: Mode register\
      #bin("1") = BANK2 affects accesses to #hex-range("0000", "3FFF"), #hex-range("4000", "7FFF"), #hex-range("A000", "BFFF")\
      #bin("0") = BANK2 affects only accesses to #hex-range("4000", "7FFF")
    ]
  )
]

The MODE register determines how the BANK2 register value is used during memory accesses.

#warning[
  Most documentation, including Pan Docs @pandocs, calls value #bin("0") ROM banking mode, and value #bin("1") RAM banking mode. This terminology reflects the common use cases, but "RAM banking" is slightly misleading because value #bin("1") also affects ROM reads in multicart cartridges and cartridges that have a 8 or 16 Mbit ROM chip.
]

=== ROM in the #hex-range("0000", "7FFF") area

In MBC1 cartridges, the A0-A13 cartridge bus signals are connected directly to the corresponding ROM pins, and the remaining ROM pins (A14-A20) are controlled by the MBC1. These remaining pins form the ROM bank number.

When the #hex-range("0000", "3FFF") address range is accessed, the effective bank number depends on the MODE register. In MODE #bin("0") the bank number is always 0, but in MODE #bin("1") it's formed by shifting the BANK2 register value left by 5 bits.

When the #hex-range("4000", "7FFF") addess range is accessed, the effective bank number is always a combination of BANK1 and BANK2 register values.

If the cartridge ROM is smaller than 16 Mbit, there are less ROM address pins to connect to and therefore some bank number bits are ignored. For example, 4 Mbit ROMs only need a 5-bit bank number, so the BANK2 register value is always ignored because those bits are simply not connected to the ROM.

#figure(
  tablex(
    columns: 4,
    auto-hlines: false,
    align: center,
    hlinex(),
    [], colspanx(3)[ROM address bits],
    [Accessed address], colspanx(2)[Bank number], [Address within bank],
    hlinex(),
    [], [20-19], [18-14], [13-0],
    hlinex(),
    [#hex-range("0000", "3FFF"), MODE = #bin("0")], bin("00"), bin("00000"), [A\<13:0\>],
    hlinex(),
    [#hex-range("0000", "3FFF"), MODE = #bin("1")], [BANK2], bin("00000"), [A\<13:0\>],
    hlinex(),
    hex-range("4000", "7FFF"), [BANK2], [BANK1], [A\<13:0\>],
    hlinex(),
  ),
  kind: table,
  caption: "Mapping of physical ROM address bits in MBC1 carts"
)

==== ROM banking example 1

Let's assume we have previously written #hex("12") to the BANK1 register and #bin("01") to the BANK2 register. The effective bank number during ROM reads depends on which address range we read and on the value of the MODE register:

#block(breakable: false, {
  let bank1 = box(inset: (y: 2pt), fill: rgb("#0000ff4c"))[10010]
  let bank2 = box(inset: (y: 2pt), fill: rgb("#ff00004c"))[01]
  let prefix = box(inset: (y: 2pt))[0b]
  let pass(text) = box(inset: (y: 2pt), fill: rgb("#00000019"), text)
  tablex(
    columns: 3,
    align: (left + horizon, right + horizon, left + horizon),
    auto-vlines: false,
    auto-hlines: false,
    [*Value of the BANK 1 register*],
    monotext[#prefix#bank1], [],
    [*Value of the BANK 2 register*],
    monotext[#prefix#bank2], [],
    [*Effective ROM bank number\ (reading #hex-range("4000", "7FFF"))*],
    monotext[#prefix#bank2#bank1], [(= 50 = #hex("32"))],
    [*Effective ROM bank number\ (reading #hex-range("0000", "3FFF"), MODE = #bin("0"))*],
    monotext[#prefix#pass[00]#pass[00000]], [(= 0 = #hex("00"))],
    [*Effective ROM bank number\ (reading #hex-range("0000", "3FFF"), MODE = #bin("1"))*],
    monotext[#prefix#bank2#pass[00000]], [(= 32 = #hex("20"))],
  )
})

==== ROM banking example 2

Let's assume we have previously requested ROM bank number 68, MBC1 mode is #bin("0"), and we are now reading a byte from #hex("72A7"). The actual physical ROM address that will be read is going to be #hex("1132A7") and is constructed in the following way:

#block(breakable: false, {
  let bank1(content) = box(inset: (y: 2pt), fill: rgb("#0000ff4c"), content)
  let bank2(content) = box(inset: (y: 2pt), fill: rgb("#ff00004c"), content)
  let addr(content) = box(inset: (y: 2pt), fill: rgb("#00ff004c"), content)
  let prefix = box(inset: (y: 2pt))[0b]
  let pass(content) = box(inset: (y: 2pt), fill: rgb("#00000019"), content)
  tablex(
    columns: 3,
    align: (left + horizon, right + horizon, left + horizon),
    auto-vlines: false,
    auto-hlines: false,
    [*Value of the BANK 1 register*],
    monotext[#prefix#bank1("00100")], [],
    [*Value of the BANK 2 register*],
    monotext[#prefix#bank2("10")], [],
    [*ROM bank number*],
    monotext[#prefix#bank2("10")#bank1("00100")], [(= 68 = #hex("44"))],
    [*Address being read*],
    monotext[#prefix#pass[01]#addr("11 0010 1010 0111")], [(= #hex("72A7"))],
    [*Actual physical ROM address*],
    monotext[#prefix#bank2("1 0")#bank1("001 00")#addr("11 0010 1010 0111")], [(= #hex("1132A7"))],
  )
})

=== RAM in the #hex-range("A000", "BFFF") area

Some MBC1 carts include SRAM, which is mapped to the #hex-range("A000", "BFFF") area. If no RAM is present, or RAM is not enabled with the RAMG register, all reads return undefined values and writes have no effect.

On boards that have RAM, the A0-A12 cartridge bus signals are connected directly to the corresponding RAM pins, and pins A13-A14 are controlled by the MBC1. Most of the time the RAM size is 64 Kbit, which corresponds to a single bank of #hex("2000") bytes. With larger RAM sizes the BANK2 register value can be used for RAM banking to provide the two high address bits.

In MODE #bin("0") the BANK2 register value is not used, so the first RAM bank is always mapped to the #hex-range("A000", "BFFF") area. In MODE #bin("1") the BANK2 register value is used as the bank number.

#figure(
  tablex(
    columns: 3,
    auto-hlines: false,
    align: center + bottom,
    hlinex(),
    [], colspanx(2)[RAM address bits],
    [Accessed address], [Bank number], [Address within bank],
    hlinex(),
    [], [14-13], [12-0],
    hlinex(),
    [#hex-range("A000", "BFFF"), MODE = #bin("0")], bin("00"), [A\<12:0\>],
    hlinex(),
    [#hex-range("A000", "BFFF"), MODE = #bin("1")], [BANK2], [A\<12:0\>],
    hlinex(),
  ),
  kind: table,
  caption: "Mapping of physical RAM address bits in MBC1 carts"
)

==== RAM banking example 1

Let's assume we have previously written #bin("10") to the BANK2 register, MODE is #bin("1"), RAMG is #bin("1010") and we are now reading a byte from #hex("B123").  The actual physical RAM address that will be read is going to be #hex("5123") and is constructed in the following way:

#block(breakable: false, {
  let bank2(content) = box(inset: (y: 2pt), fill: rgb("#ff00004c"), content)
  let addr(content) = box(inset: (y: 2pt), fill: rgb("#00ff004c"), content)
  let prefix = box(inset: (y: 2pt))[0b]
  let pass(content) = box(inset: (y: 2pt), fill: rgb("#00000019"), content)
  tablex(
    columns: 3,
    align: (left + horizon, right + horizon, left + horizon),
    auto-vlines: false,
    auto-hlines: false,
    [*Value of the BANK 2 register*],
    monotext[#prefix#bank2("10")], [],
    [*Address being read*],
    monotext[#prefix#pass[101]#addr("1 0001 0010 0011")], [(= #hex("B123"))],
    [*Actual physical RAM address*],
    monotext[#prefix#bank2("10")#addr("1 0001 0010 0011")], [(= #hex("5123"))],
  )
})

=== MBC1 multicarts ("MBC1M")

MBC1 is also used in a couple of "multicart" cartridges, which include more than one game on the same cartridge. These cartridges use the same regular MBC1 chip, but the circuit board is wired a bit differently. This alternative wiring is sometimes called "MBC1M", but technically the mapper chip is the same. All known MBC1 multicarts use 8 Mbit ROMs, so there's no definitive wiring for other ROM sizes.

In MBC1 multicarts bit 4 of the BANK1 register is not physically connected to anything, so it's skipped. This means that the bank number is actually a 6-bit number. In all known MBC1 multicarts the games reserve 16 banks each, so BANK2 can actually be considered "game number", while BANK1 is the internal bank number within the selected game. At reset BANK2 is #bin("00"), and the "game" in this slot is actually a game selection menu. The menu code selects MODE #bin("1") and writes the game number to BANK2 once the user selects a game.

From a ROM banking point of view, multicarts simply skip bit 4 of the BANK1 register, but otherwise the behaviour is the same. MODE #bin("1") guarantees that all ROM accesses, including accesses to #hex-range("0000", "3FFF"), use the BANK2 register value.

#figure(
  tablex(
    columns: 4,
    auto-hlines: false,
    align: center,
    hlinex(),
    [], colspanx(3)[ROM address bits],
    [Accessed address], colspanx(2)[Bank number], [Address within bank],
    hlinex(),
    [], [19-18], [17-14], [13-0],
    hlinex(),
    [#hex-range("0000", "3FFF"), MODE = #bin("0")], bin("00"), bin("0000"), [A\<13:0\>],
    hlinex(),
    [#hex-range("0000", "3FFF"), MODE = #bin("1")], [BANK2], bin("0000"), [A\<13:0\>],
    hlinex(),
    hex-range("4000", "7FFF"), [BANK2], [BANK1\<3:0\>], [A\<13:0\>],
    hlinex(),
  ),
  kind: table,
  caption: "Mapping of physical ROM address bits in MBC1 multicarts"
)

==== ROM banking example 1

Let's assume we have previously requested "game number" 3 (= #bin("11")) and ROM bank number 29 (= #hex("1D")), MBC1 mode is #bin("1"), and we are now reading a byte from #hex("6C15"). The actual physical ROM address that will be read is going to be #hex("F6C15") and is constructed in the following way:

#block(breakable: false, {
  let bank1(content) = box(inset: (y: 2pt), fill: rgb("#0000ff4c"), content)
  let bank2(content) = box(inset: (y: 2pt), fill: rgb("#ff00004c"), content)
  let addr(content) = box(inset: (y: 2pt), fill: rgb("#00ff004c"), content)
  let prefix = box(inset: (y: 2pt))[0b]
  let pass(content) = box(inset: (y: 2pt), fill: rgb("#00000019"), content)
  tablex(
    columns: 3,
    align: (left + horizon, right + horizon, left + horizon),
    auto-vlines: false,
    auto-hlines: false,
    [*Value of the BANK 1 register*],
    monotext[#prefix#pass("1")#bank1("1101")], [],
    [*Value of the BANK 2 register*],
    monotext[#prefix#bank2("11")], [],
    [*ROM bank number*],
    monotext[#prefix#bank2("11")#bank1("1101")], [(= 61 = #hex("3D"))],
    [*Address being read*],
    monotext[#prefix#pass[01]#addr("10 1100 0001 0101")], [(= #hex("6C15"))],
    [*Actual physical ROM address*],
    monotext[#prefix#bank2("11")#bank1("11 01")#addr("10 1100 0001 0101")], [(= #hex("F6C15"))],
  )
})

==== Detecting multicarts

MBC1 multicarts are not detectable by simply looking at the ROM header, because the ROM type value is just one of the normal MBC1 values. However, detection is possible by going through BANK2 values and looking at "bank 0" of each multicart game and doing some heuristics based on the header data. All the included games, including the game selection menu, have proper header data. One example of a good heuristic is logo data verification.

So, if you have a 8 Mbit cart with MBC1, first assume that it's a multicart and bank numbers are 6-bit values. Set BANK1 to zero and loop through the four possible BANK2 values while checking the data at #hex-range("0104", "0133"). In other words, check logo data starting from physical ROM locations #hex("00104"), #hex("40104"), #hex("80104"), and #hex("C0104"). If proper logo data exists with most of the BANK2 values, the cart is most likely a multicart. Note that multicarts can just have two actual games, so one of the locations might not have the header data in place.


=== Dumping MBC1 carts

MBC1 cartridge dumping is fairly straightforward with the right hardware. The total number of banks is read from the header, and each bank is read one byte at a time. However, BANK1 register zero-adjustment and multicart cartridges need to be considered in ROM dumping code.

Banks #hex("20"), #hex("40") and #hex("60") can only be read from the #hex-range("0000", "3FFF") memory area and only when MODE register value is #bin("1"). Using MODE #bin("1") has no undesirable effects when doing ROM dumping, so using it at all times is recommended for simplicity.

Multicarts should be detected using the logo check described earlier, and if a multicart is detected, BANK1 should be considered a 4-bit register in the dumping code.

#figure(
  raw(read("../../code-snippets/mbc1_rom_dump.py"), lang: "python", block: true),
  caption: "Python pseudo-code for MBC1 ROM dumping"
)
