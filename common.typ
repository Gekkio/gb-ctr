#import "@preview/cetz:0.3.2"

#let monotext(..args) = text(font: "Anonymous Pro", fallback: false, ..args)

#let awesome-brands(..args) = text(font: "Font Awesome 6 Brands", fallback: false, ..args)

#let awesome(..args) = text(font: "Font Awesome 6 Free Solid", fallback: false, ..args)

#let color-box(icon: none, title: none, fgcolor: black, bgcolor: white, title-color: white, content) = [
  #let radius = 5pt
  #box(fill: bgcolor, stroke: 2pt + fgcolor, radius: radius)[
    #block(breakable: false, width: 100%, fill: fgcolor, inset: (x: 16pt, y: 8pt), below: 0pt, radius: (top-left: radius, top-right: radius))[
      #awesome(fill: title-color, icon)
      #text(fill: title-color, weight: "bold")[#title]
    ]
    #block(breakable: false, width: 100%, inset: 16pt)[#content]
  ]
]

#let caveat(content) = [
  #color-box(content, icon: "\u{f05a}", title: "Caveat", fgcolor: rgb("#DC143C"), bgcolor: rgb("#FFE4E1"))
]
#let speculation(content) = [
  #color-box(content, icon: "\u{f12e}", title: "Speculation", fgcolor: rgb("#467BA9"), bgcolor: rgb("#F0FFFF"))
]
#let warning(content) = [
  #color-box(content, icon: "\u{f06a}", title: "Warning", fgcolor: rgb("#FFD700"), bgcolor: rgb("#FFFACD"), title-color: rgb("#505050"))
]

#let bit(content) = monotext(content)
#let bin(content) = monotext("0b" + content)
#let hex(content) = monotext("0x" + content)
#let hex-range(start, end) = monotext({"0x" + start + "-0x" + end})

#let unimpl-bit() = table.cell(fill: rgb("#D3D3D3ff"))[]

#let reg-table(..args) = monotext(9pt)[
  #table(
    columns: (1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
    inset: 5pt,
    align: center + horizon,
    ..args
  )
]
#let reg-figure(caption: none, content) = [
  #v(1cm)
  #figure(
    content,
    caption: caption,
    kind: "register",
    supplement: [Register],
    numbering: (..nums) => counter(heading).display((..hnums) => numbering("1", hnums.pos().at(1))) + "." + numbering("1", ..nums)
  )
]
