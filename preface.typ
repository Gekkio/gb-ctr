#import "common.typ": *

== Preface
#v(2em)

#caveat[
  #text(17pt)[
    IMPORTANT: This document focuses at the moment on 1st and 2nd generation
    devices (models before the Game Boy Color), and some hardware details are
    very different in later generations.

    Be very careful if you make assumptions about later generation devices based
    on this document!
  ]
]

#pagebreak()

== How to read this document
#counter(heading).update((0, 0))
#v(2em)

#speculation[
  This is something that hasn't been verified, but would make a lot of sense.
]

#caveat[
  This explains some caveat about this documentation that you should know.
]

#warning[
  This is a warning about something.
]

=== Formatting of numbers

When a single bit is discussed in isolation, the value looks like this: #bit("0"), #bit("1").

Binary numbers are prefixed with #bin("") like this: #bin("0101101"), #bin("11011"), #bin("00000000"). Values are prefixed with zeroes when necessary, so the total number of digits always matches the number of digits in the value.

Hexadecimal numbers are prefixed with #hex("") like this: #hex("1234"), #hex("DEADBEEF"), #hex("FF04"). Values are prefixed with zeroes when necessary, so the total number of characters always matches the number of nibbles in the value.

Examples:

#v(1em)

#table(
  columns: 4,
  stroke: none,
  [], [4-bit], [8-bit], [16-bit],
  [Binary], bin("0101"), bin("10100101"), bin("0000101010100101"),
  [Hexadecimal], hex("5"), hex("A5"), hex("0AA5")
)

#pagebreak()
=== Register definitions

#reg-figure(
  caption: [#hex("1234") - This is a hardware register definition]
)[
  #reg-table(
    [R/W-0], [R/W-1], [U-1], [R-0], [R-1], [R-x], [W-1], [U-0],
    colspanx(2)[VALUE\<1:0\>], unimpl-bit(), colspanx(3)[BIGVAL\<7:5\>], [FLAG], unimpl-bit(),
    [bit 7], [6], [5], [4], [3], [2], [1], [bit 0]
  )
  #set align(left)

  #v(1em)
  *Top row legend:*

  #grid(
    columns: (1cm, 1fr),
    gutter: 1em,
    [*R*], [Bit can be read.],
    [*W*], [Bit can be written. If the bit cannot be read, reading returns a constant value defined in the bit list of the register in question.],
    [*U*], [Unimplemented bit. Writing has no effect, and reading returns a constant value defined in the bit list of the register in question.],
    [*-n*], [Value after system reset: #bit("0"), #bit("1"), or x.],
    [*#bit("1")*], [Bit is set.],
    [*#bit("0")*], [Bit is cleared.],
    [*x*], [Bit is unknown (e.g. depends on external things such as user input)]
  )

  #v(1em)
  *Middle row legend:*
  #tablex(
    columns: 2,
    align: center + horizon,
    `VALUE<1:0>`, [Bits 1 and 0 of VALUE],
    unimpl-bit(), [Unimplemented bit],
    `BIGVAL<7:5>`, [Bits 7, 6, 5 of BIGVAL],
    `FLAG`, [Single-bit value FLAG]
  )

  #v(1em)
  *In this example:*

  - After system reset, VALUE is #bin("01"), BIGVAL is either #bin("010") or #bin("011"), FLAG is #bin("1").
  - Bits 5 and 0 are unimplemented. Bit 5 always returns #bit("1"), and bit 0 always returns #bit("0").
  - Both bits of VALUE can be read and written. When this register is written, bit 7 of the written value goes to bit 1 of VALUE.
  - FLAG can only be written to, so reads return a value that is defined elsewhere.
  - BIGVAL cannot be written to. Only bits 5-7 of BIGVAL are defined here, so look elsewhere for the low bits 0-4.
]
