#import "../../common.typ": *

#let sm83-simple-figure = cetz.canvas(length: 1mm, {
  import cetz.draw: *
  set-style(stroke: (thickness: 1.5pt), mark: (scale: 1.5, width: 3mm))

  let margin = 4
  let core-x = (0, 91)
  let left-box-x = (margin, 42)
  let right-box-x = (58, 79)
  let right-edge = 119
  let intr-y = -20
  let data-y = -42
  let addr-y = -79

  let regs = (
    ("IR", "IE"),
    none,
    ("A", "F"),
    ("B", "C"),
    ("D", "E"),
    ("H", "L"),
    ("PC",),
    ("SP",)
  )

  let label(pos, body, ..args) = content(pos, align(center, text(8.5pt, body)), ..args)
  let box(a, b, body, name: none, size: 8.5pt, ..style) = {
    rect(a, b, name: name, ..style)
    content((a, 50%, b), align(center, text(size, body)))
  }
  let arrow(a, b, start: false, end: false, name: none) = line(
    a, b,
    name: name,
    mark: (start: if start { "straight" }, end: if end { "straight" }),
    stroke: (thickness: 1.6pt),
  )
  let bus(y, name, inner, outer, inside: (false, false), outside: (false, false)) = {
    arrow((left-box-x.at(1), y), (core-x.at(1), y), start: inside.at(0), end: inside.at(1), name: name)
    arrow((core-x.at(1), y), (right-edge, y), start: outside.at(0), end: outside.at(1), name: name + "-soc")
    label((rel: (0, 2), to: name + ".mid"), inner, anchor: "south")
    label((rel: (0, 2), to: name + "-soc.mid"), outer, anchor: "south")
  }

  // CPU core box
  rect((core-x.at(0), -8), (core-x.at(1), -91), stroke: (thickness: 1.2pt, dash: "dashed"), name: "core")
  label((rel: (0, 1), to: "core.north"), text(weight: "bold")[SM83 CPU core], anchor: "south")

  // Control unit
  box((left-box-x.at(0), -11), (left-box-x.at(1), -28), name: "control")[Control unit]
  bus(intr-y, "intr", [Interrupt signals \ (REQ in, ACK out)], [SoC \ interrupts], inside: (true, true), outside: (true, true))

  // Register file
  let regs-top = -39
  let y = regs-top - 7
  let cell-h = 4
  for row in regs {
    if row == none { y -= 3; continue }
    let w = (left-box-x.at(1) - left-box-x.at(0) - 4) / row.len()
    for (i, name) in row.enumerate() {
      let x = left-box-x.at(0) + 2 + i * w
      box((x, y), (x + w, y - cell-h), name, size: 7.5pt, stroke: (thickness: 0.7pt))
    }
    y -= cell-h
  }
  rect((left-box-x.at(0), regs-top), (left-box-x.at(1), y - 3), name: "regs")
  label((rel: (0, -4), to: "regs.north"))[Register file]

  box((right-box-x.at(0), -49), (right-box-x.at(1), -60), name: "alu")[ALU \ 8-bit]
  box((right-box-x.at(0), -63), (right-box-x.at(1), -74), name: "idu")[IDU \ 16-bit]
  bus(data-y, "data", [8-bit CPU data bus \ (bidirectional)], [SoC \ internal \ data bus], inside: (true, true), outside: (true, true))
  bus(addr-y, "addr", [], [SoC \ internal \ address bus], inside: (false, true), outside: (false, true))
  label((rel: (0, -2), to: "addr.mid"), anchor: "north")[16-bit CPU address bus \ (output only)]

  for pos in (25%, 75%) {
    let input = ("alu.north-west", pos, "alu.south-west")
    arrow(("regs.east", "|-", input), input, end: true)
  }
  arrow("alu.north", ("alu.north", "|-", "data.mid"), end: true)

  arrow(("idu.south", "|-", "addr.mid"), "idu.south", end: true)
  arrow("idu.west", ("regs.east", "|-", "idu.west"), end: true)
})
