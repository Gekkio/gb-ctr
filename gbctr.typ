#import "common.typ": awesome-brands, monotext

#let title = [Game Boy: Complete Technical Reference]
#let date = datetime.today()
#let config = json("config.json")

#set document(title: title, author: ("gekkio"), date: date)
#set par(justify: true)
#set text(font: "Noto Sans")
#show figure.where(kind: "register"): set figure.caption(position: top)
#show raw: set text(1.25em, font: "Anonymous Pro", fallback: false)
#set figure(numbering: (..nums) => [#counter(heading).display((..heading_nums) => heading_nums.pos().at(1))\.#nums.pos().at(0)])

#[
  #set align(center)
  #set par(justify: false)
  #set page(margin: (x: 2cm, y: 5cm), footer-descent: 0%, footer: [
    #link("http://creativecommons.org/licenses/by-sa/4.0/")[
      #text(17pt)[
        #awesome-brands[\u{f25e}]
        #awesome-brands[\u{f4e7}]
        #awesome-brands[\u{f4ef}]
      ]
    ]\
    This work is licensed under a #link("http://creativecommons.org/licenses/by-sa/4.0/")[Creative Commons Attribution-ShareAlike 4.0 International License].
  ])

  #image("images/gbctr.svg", width: 5cm)

  #text(17pt)[#title]

  gekkio\
    #monotext[#link("https://gekkio.fi")]

  #date.display("[month repr:long] [day padding:none], [year]")

  Revision #config.revision
  #if config.draft [\ DRAFT!]
]

#set page(
  margin: (x: 2cm, y: 2cm),
  footer: [
    #set text(10pt)
    #block(width: 100%)[
      #set align(center)
      #if config.draft [
        #place(left, text(style: "italic", [DRAFT! #config.revision]))
      ]
      #context {
        box(counter(page).display())
      }
    ]
  ]
)
#show heading: set block(above: 1.4em, below: 1em)

#set heading(numbering: (..nums) => {
  let level = nums.pos().len()
  if level <= 2 {
    none
  } else {
    numbering("1.1.1.1.1", ..nums.pos().slice(1))
  }
})
#include("preface.typ")

#pagebreak()
#show outline: set heading(outlined: true)
#show outline.entry: it => {
  if it.level == 1 {
    block(above: 20pt, below: 0pt, strong(it))
  } else if it.level == 2 {
    strong(it)
  } else {
    it
  }
}
#outline(fill: repeat(" . "), indent: n => calc.max(0, n - 1) * 1em)

#set heading(numbering: (..nums) => {
  let level = nums.pos().len()
  if level == 1 {
    numbering("I", ..nums)
  } else if level > 3 {
    none
  } else {
    numbering("1.1.1.1.1", ..nums.pos().slice(1))
  }
})

#let total-chapters = counter("total-chapters")

#counter(heading).update(0)
<maincontent>
#[
  #show heading.where(level: 1): it => [
    #pagebreak()
    #set align(center)
    #text(21pt)[
      #v(1fr)
      #block("Part " + counter(heading).display())
      #block(it.body)
      #v(1fr)
    ]
    #context {
      let chapters = total-chapters.get().at(0)
      return counter(heading).update((part) => (part, chapters))
    }
  ]
  #show heading.where(level: 2): it => [
    #pagebreak()
    #block[
      #text(17pt, [Chapter #counter(heading).display()])
    ]
    #text(21pt, it.body)
    #v(1em)
    #total-chapters.step()
    #counter(figure).update(0)
    #counter(figure.where(kind: table)).update(0)
    #counter(figure.where(kind: "register")).update(0)
  ]

  = Game Boy console architecture

  #include "chapter/console/intro.typ"
  #include "chapter/console/clocks.typ"

  = Sharp SM83 CPU core

  #include "chapter/cpu/intro.typ"
  #include "chapter/cpu/simple.typ"
  #include "chapter/cpu/timing.typ"
  #include "chapter/cpu/instruction-set.typ"

  = Game Boy SoC peripherals and features

  #include "chapter/peripherals/boot-rom.typ"
  #include "chapter/peripherals/dma.typ"
  #include "chapter/peripherals/ppu.typ"
  #include "chapter/peripherals/p1.typ"
  #include "chapter/peripherals/serial.typ"

  = Game Boy game cartridges

  #include "chapter/cartridges/mbc1.typ"
  #include "chapter/cartridges/mbc2.typ"
  #include "chapter/cartridges/mbc3.typ"
  #include "chapter/cartridges/mbc30.typ"
  #include "chapter/cartridges/mbc5.typ"
  #include "chapter/cartridges/mbc6.typ"
  #include "chapter/cartridges/mbc7.typ"
  #include "chapter/cartridges/huc1.typ"
  #include "chapter/cartridges/huc3.typ"
  #include "chapter/cartridges/mmm01.typ"
  #include "chapter/cartridges/tama5.typ"
]

#counter(heading).update(0)
#set heading(numbering: (..nums) => {
  let level = nums.pos().len()
  if level == 1 {
    none
  } else {
    numbering("A.1.1.1.1", ..nums.pos().slice(1))
  }
})
#set figure(numbering: (..nums) => [#counter(heading).display((..heading_nums) => numbering("A", heading_nums.pos().at(1)))\.#nums.pos().at(0)])

#pagebreak()
#text(21pt)[
  #set align(center)
  #v(1fr)
  = Appendices
  #v(1fr)
]

#show heading.where(
  level: 2
): it => block[
  #block[
    #text(17pt, [Appendix #counter(heading).display()])
  ]
  #text(21pt, it.body)
  #v(1em)
]

#pagebreak()
#include "appendix/opcode-tables.typ"
#pagebreak()
#include "appendix/memory-map.typ"
#pagebreak()
#include "appendix/external-bus.typ"
#pagebreak()
#include "appendix/pinouts.typ"

#pagebreak()
#bibliography("gbctr.yml")
