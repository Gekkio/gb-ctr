#import "../../common.typ": *

== Serial communication

#reg-figure(
  caption: [#hex("FF01") - SB - Serial data register]
)[
  #reg-table(
    [R/W-0], [R/W-0], [R/W-0], [R/W-0], [R/W-0], [R/W-0], [R/W-0], [R/W-0],
    table.cell(colspan: 8)[SB\<7:0\>],
    [bit 7], [6], [5], [4], [3], [2], [1], [bit 0]
  )
  #set align(left)
  #grid(
    columns: (auto, 1fr),
    gutter: 1em,
    [*bit 7-0*], [*SB\<7:0\>*: Serial data],
  )
]

#reg-figure(
  caption: [#hex("FF02") - SC - Serial control register]
)[
  #reg-table(
    [R/W-0], [U], [U], [U], [U], [U], [U], [R/W-0],
    [SIO_EN], unimpl-bit(), unimpl-bit(), unimpl-bit(), unimpl-bit(), unimpl-bit(), unimpl-bit(), [SIO_CLK],
    [bit 7], [6], [5], [4], [3], [2], [1], [bit 0]
  )
  #set align(left)
  #grid(
    columns: (auto, 1fr),
    gutter: 1em,
    [*bit 7*], [*SIO_EN*],
    [*bit 6-1*], [*Unimplemented*: Ignored during writes, reads are undefined],
    [*bit 0*], [*SIO_CLK*]
  )
]
