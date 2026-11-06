#import "../../common.typ": *

== PPU (Picture Processing Unit)

#reg-figure(
  caption: [#hex("FF40") - LCDC - PPU control register]
)[
  #reg-table(
    [R/W-0], [R/W-0], [R/W-0], [R/W-0], [R/W-0], [R/W-0], [R/W-0], [R/W-0],
    [LCD_EN], [WIN_MAP], [WIN_EN], [TILE_SEL], [BG_MAP], [OBJ_SIZE], [OBJ_EN], [BG_EN],
    [bit 7], [6], [5], [4], [3], [2], [1], [bit 0]
  )
]

#reg-figure(
  caption: [#hex("FF41") - STAT - PPU status register]
)[
  #reg-table(
    [U-1], [R/W-0], [R/W-0], [R/W-0], [R/W-0], [R-0], [R-0], [R-0],
    unimpl-bit(), [INTR_LYC], [INTR_M2], [INTR_M1], [INTR_M0], [LYC_STAT], table.cell(colspan: 2)[LCD_MODE\<1:0\>],
    [bit 7], [6], [5], [4], [3], [2], [1], [bit 0]
  )
  #set align(left)
  #grid(
    columns: (auto, 1fr),
    gutter: 1em,
    [*bit 7*], [*Unimplemented*: Ignored during writes, reads return #bit("1") (@undriven-bus)],
    [*bit 6*], [*INTR_LYC*],
    [*bit 5*], [*INTR_M2*],
    [*bit 4*], [*INTR_M1*],
    [*bit 3*], [*INTR_M0*],
    [*bit 2*], [*LYC_STAT*],
    [*bit 1-0*], [*LCD_MODE*],
  )
]

#reg-figure(
  caption: [#hex("FF42") - SCY - Vertical scroll register]
)[
  #reg-table(
    [R/W-0], [R/W-0], [R/W-0], [R/W-0], [R/W-0], [R/W-0], [R/W-0], [R/W-0],
    table.cell(colspan: 8)[SCY\<7:0\>],
    [bit 7], [6], [5], [4], [3], [2], [1], [bit 0]
  )
]

#reg-figure(
  caption: [#hex("FF43") - SCX - Horizontal scroll register]
)[
  #reg-table(
    [R/W-0], [R/W-0], [R/W-0], [R/W-0], [R/W-0], [R/W-0], [R/W-0], [R/W-0],
    table.cell(colspan: 8)[SCX\<7:0\>],
    [bit 7], [6], [5], [4], [3], [2], [1], [bit 0]
  )
]

#reg-figure(
  caption: [#hex("FF44") - LY - Scanline register]
)[
  #reg-table(
    [R-0], [R-0], [R-0], [R-0], [R-0], [R-0], [R-0], [R-0],
    table.cell(colspan: 8)[LY\<7:0\>],
    [bit 7], [6], [5], [4], [3], [2], [1], [bit 0]
  )
]

#reg-figure(
  caption: [#hex("FF45") - LYC - Scanline compare register]
)[
  #reg-table(
    [R/W-0], [R/W-0], [R/W-0], [R/W-0], [R/W-0], [R/W-0], [R/W-0], [R/W-0],
    table.cell(colspan: 8)[LYC\<7:0\>],
    [bit 7], [6], [5], [4], [3], [2], [1], [bit 0]
  )
]
