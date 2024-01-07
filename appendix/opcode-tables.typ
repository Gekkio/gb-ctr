#import "../common.typ": *

== Instruction set tables

These tables include all the opcodes in the Sharp SM83 instruction set. The style and layout of these tables was inspired by the opcode tables available at pastraiser.com @pastraiser.

#set page(flipped: true)

#let colors = (
  load_8b: rgb("#87CEEB"),
  load_16b: rgb("#98FB98"),
  alu_8b: rgb("#FFD700"),
  alu_16b: rgb("#FFC0CB"),
  rotate_shift_bit: rgb("#30D5C8"),
  control: rgb("#F4A460"),
  misc: rgb("#DB7093"),
  undefined: rgb("#C0C0C0"),
)

#let inset = 5pt
#let border = (content) => box(inset: inset, content)

#let col_labels = ([], ..range(16).map((x) => border("x" + str(x, base: 16))))

#let ops = toml("../opcodes.toml")

#let opcode_table = (opcodes) => {
  monotext(6pt, weight: "bold")[
    #table(
      inset: 0pt,
      columns: (auto, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
      align: (col, row) => {
        if col == 0 {
          right
        } else {
          center
        }
      },
      fill: (col, row) => {
        if col == 0 or row == 0 {
          none
        } else {
          let opcode = (col - 1) + (row - 1) * 0x10
          if opcodes.len() > opcode {
            let op = opcodes.at(opcode)
            let category = ops.categories.at(op.category)
            colors.at(category.kind)
          }
        }
      },
      ..col_labels,
      ..range(16).map((y) => {
        (
          border(str(y, base: 16) + "x"),
          ..range(16).map((x) => {
            let opcode = x + (y * 0x10)
            let op = opcodes.at(opcode)
            let dest = label("op:" + op.category)
            link(dest, block(width: 100%, inset: inset, op.mnemonic))
          })
        )
      }).flatten()
    )
  ]
}

#figure(
  opcode_table(ops.opcodes),
  caption: "Sharp SM83 instruction set",
  kind: table
)

*Legend:*

#let color-box = (fill, content) => box(fill: fill, stroke: black, inset: 6pt)[#content]

#color-box(colors.load_8b)[8-bit loads]
#color-box(colors.load_16b)[16-bit loads]
#color-box(colors.alu_8b)[8-bit arithmetic/logical]
#color-box(colors.alu_16b)[16-bit arithmetic]
#color-box(colors.rotate_shift_bit)[Rotates, shifts, and bit operations]
#color-box(colors.control)[Control flow]
#color-box(colors.misc)[Miscellaneous]
#color-box(colors.undefined)[Undefined]

#grid(
  columns: (auto, 1fr),
  gutter: 1em,
  [*n*], [unsigned 8-bit immediate data],
  [*nn*], [unsigned 16-bit immediate data],
  [*e*], [signed 8-bit immediate data],
)

#figure(
  opcode_table(ops.cb_opcodes),
  caption: "Sharp SM83 CB-prefixed instructions",
  kind: table
)
