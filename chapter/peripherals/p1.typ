#import "../../common.typ": *

== Port P1 (Joypad, Super Game Boy communication)

#reg-figure(
  caption: [#hex("FF00") - P1 - Joypad/Super Game Boy communication register]
)[
  #reg-table(
    [U], [U], [W-0], [W-0], [R-x], [R-x], [R-x], [R-x],
    unimpl-bit(), unimpl-bit(), [P15], [P14], [P13], [P12], [P11], [P10],
    [bit 7], [6], [5], [4], [3], [2], [1], [bit 0]
  )
  #set align(left)
  #grid(
    columns: (auto, 1fr),
    gutter: 1em,
    [*bit 7-6*], [*Unimplemented*: Ignored during writes, reads are undefined],
    [*bit 5*], [*P15*],
    [*bit 4*], [*P14*],
    [*bit 3*], [*P13*],
    [*bit 2*], [*P12*],
    [*bit 1*], [*P11*],
    [*bit 0*], [*P10*],
  )
]
