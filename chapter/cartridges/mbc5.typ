#import "../../common.typ": *

== MBC5 mapper chip

The majority of games for Game Boy Color use the MBC5 chip. MBC5 supports ROM sizes up to 64 Mbit (512 banks of #hex("4000") bytes), and RAM sizes up to 1 Mbit (16 banks of #hex("2000") bytes). The information in this section is based on my MBC5 research, and The Cycle-Accurate Game Boy Docs @tcagbd.

=== MBC5 registers

#reg-figure(
  caption: [#hex-range("0000", "1FFF") - RAMG - MBC5 RAM gate register]
)[
  #reg-table(
    [W-0], [W-0], [W-0], [W-0], [W-0], [W-0], [W-0], [W-0],
    colspanx(8)[RAMG\<7:0\>],
    [bit 7], [6], [5], [4], [3], [2], [1], [bit 0]
  )
  #set align(left)
  #grid(
    columns: (auto, 1fr),
    gutter: 1em,
    [*bit 7-0*], [
      *RAMG\<7:0\>*: RAM gate register\
      #bin("00001010") = enable access to cartridge RAM\
      All other values disable access to cartridge RAM
    ]
  )
]

The 8-bit MBC5 RAMG register works in a similar manner as MBC1 RAMG, but it is a full 8-bit register so upper bits matter when writing to it. Only #bin("00001010") enables RAM access, and all other values (including #bin("10001010") for example) disable access to RAM.

When RAM access is disabled, all writes to the external RAM area #hex-range("A000", "BFFF") are ignored, and reads return undefined values. Pan Docs recommends disabling RAM when it's not being accessed to protect the contents @pandocs.

#speculation[
  We don't know the physical implementation of RAMG, but it's certainly possible that the #bin("00001010") bit pattern check is done at write time and the register actually consists of just a single bit.
]

#reg-figure(
  caption: [#hex-range("2000", "2FFF") - ROMB0 - MBC5 lower ROM bank register]
)[
  #reg-table(
    [W-0], [W-0], [W-0], [W-0], [W-0], [W-0], [W-0], [W-1],
    colspanx(8)[ROMB0\<7:0\>],
    [bit 7], [6], [5], [4], [3], [2], [1], [bit 0]
  )
  #set align(left)
  #grid(
    columns: (auto, 1fr),
    gutter: 1em,
    [*bit 7-0*], [
      *ROMB0\<7:0\>*: Lower ROM bank register
    ]
  )
]

The 8-bit ROMB0 register is used as the lower 8 bits of the ROM bank number when the CPU accesses the #hex-range("4000", "7FFF") memory area.

#reg-figure(
  caption: [#hex-range("3000", "3FFF") - ROMB1 - MBC5 upper ROM bank register]
)[
  #reg-table(
    [U], [U], [U], [U], [U], [U], [U], [W-0],
    unimpl-bit(), unimpl-bit(), unimpl-bit(), unimpl-bit(), unimpl-bit(), unimpl-bit(), unimpl-bit(), [ROMB1],
    [bit 7], [6], [5], [4], [3], [2], [1], [bit 0]
  )
  #set align(left)
  #grid(
    columns: (auto, 1fr),
    gutter: 1em,
    [*bit 7-1*], [*Unimplemented*: Ignored during writes],
    [*bit 0*], [*ROMB1*: Upper ROM bank register],
  )
]

The 1-bit ROMB1 register is used as the most significant bit (bit 9) of the ROM bank number when the CPU accesses the #hex-range("4000", "7FFF") memory area.

#reg-figure(
  caption: [#hex-range("4000", "5FFF") - RAMB - MBC5 RAM bank register]
)[
  #reg-table(
    [U], [U], [U], [U], [W-0], [W-0], [W-0], [W-0],
    unimpl-bit(), unimpl-bit(), unimpl-bit(), unimpl-bit(), colspanx(4)[RAMB\<3:0\>],
    [bit 7], [6], [5], [4], [3], [2], [1], [bit 0]
  )
  #set align(left)
  #grid(
    columns: (auto, 1fr),
    gutter: 1em,
    [*bit 7-4*], [*Unimplemented*: Ignored during writes],
    [*bit 3-0*], [*RAMB\<3:0\>*: RAM bank register],
  )
]

The 4-bit RAMB register is used as the RAM bank number when the CPU accesses the #hex-range("A000", "BFFF") memory area.
