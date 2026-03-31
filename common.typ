#import "@preview/cetz:0.4.2"

#let monotext(..args) = text(font: "Anonymous Pro", fallback: false, ..args)

#let awesome-brands(..args) = text(font: "Font Awesome 7 Brands", fallback: false, ..args)

#let awesome(..args) = text(font: "Font Awesome 7 Free Solid", fallback: false, ..args)

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

#let to-hex4(n) = {
  let digits = "0123456789ABCDEF"
  let result = ""
  let rem = n
  if rem == 0 { return "0000" }
  while rem > 0 {
    result = digits.at(calc.rem(rem, 16)) + result
    rem = calc.quo(rem, 16)
  }
  while result.len() < 4 { result = "0" + result }
  result
}

#let addr-space-figure(ticks: (), regions: (), caption: none) = figure(
  {
    set text(6pt)
    cetz.canvas(length: 1cm, {
      import cetz.draw: *
      let W = 16.0
      let H = 2.0
      let total = 0x10000
      for region in regions.sorted(key: r => if r.highlight { 1 } else { 0 }) {
        let x0 = region.start / total * W
        let x1 = region.end / total * W
        rect((x0, 0), (x1, H), fill: region.color, stroke: black + if region.highlight { 1pt } else { 0.5pt })
        if x1 - x0 >= 1.0 {
          content((x0 + (x1 - x0) / 2, H / 2), align(center + horizon, region.label))
        }
      }
      for addr in ticks {
        let x = addr / total * W
        line((x, 0), (x, -0.15), stroke: 0.4pt + black)
        content((x, -0.2), anchor: "north", hex(to-hex4(addr)))
      }
    })
  },
  caption: caption,
)
