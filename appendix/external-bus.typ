#import "../common.typ": *
#import "../timing.typ"

== Game Boy external bus

=== Bus timings

#let bus-diagram = (addr: array, rd: array, wr: array, a15: array, cs: array, data: array, sampling-edge: false) => {
  import timing: diagram, clock as c, data as d, either as e, high as h, low as l, unknown as u, undefined as x, high_impedance as z
  text(13pt,
    diagram(
      grid: true,
      (label: "CLK 4 MiHz", wave: (
        l(1),
        ..range(9).map(_ => c(1)).flatten()
      )),
      (label: "PHI 1 MiHz", wave: (l(1), c(4), c(4), c(1),)),
      (label: "A0-A14", wave: addr),
      (label: "RD", wave: rd),
      (label: "WR", wave: wr),
      (label: "A15", wave: a15),
      (label: "CS", wave: cs),
      (label: "Data", wave: data),
      fg: () => {
        import cetz.draw
        draw.set-style(stroke: (paint: rgb("#00000080"), thickness: 0.01em))
        draw.line((1.0, -0.5), (1.0, 15.5))
        draw.line((9.0, -0.5), (9.0, 15.5))
        if sampling-edge {
          draw.line((7, -0.5), (7, 15.5), stroke: (paint: rgb("#80800080"), thickness: 0.8pt))
        }
      }
    )
  )
}

#figure(
  {
    import timing: diagram, clock as c, data as d, either as e, high as h, low as l, unknown as u, undefined as x, high_impedance as z
    bus-diagram(
      addr: (u(10),),
      rd: (e(1), l(9),),
      wr: (h(10),),
      a15: (e(1), h(8), e(1),),
      cs: (e(1), h(8), e(1),),
      data: (x(1), z(9),),
    )
  },
  caption: "External bus idle machine cycle"
)

#v(1cm)

#figure(
  {
    import timing: diagram, clock as c, data as d, either as e, high as h, low as l, unknown as u, undefined as x, high_impedance as z
    [
      #columns(2, [
        #block(
          breakable: false,
          [
            #bus-diagram(
              addr: (u(2), d(7, "addr"), u(1),),
              rd: (e(1), l(9),),
              wr: (h(10),),
              a15: (e(1), h(2), l(6), e(1),),
              cs: (e(1), h(8), e(1),),
              data: (x(1), z(2), d(6, "data"), z(1)),
              sampling-edge: true
            )
            #align(right, [
              a) #hex-range("0000", "7FFF") #footnote[
                Does not apply to #hex-range("0000", "00FF") accesses while the boot ROM is enabled. Boot ROM accesses do not affect the external bus, so it is in the idle state.
              ] <bootrom>
            ])
          ]
        )
        #colbreak()
        #block(
          breakable: false,
          [
            #bus-diagram(
              addr: (u(2), d(7, "addr"), u(1),),
              rd: (e(1), l(9),),
              wr: (h(10),),
              a15: (e(1), h(8), e(1),),
              cs: (e(1), h(2), l(6), e(1),),
              data: (x(1), z(2), d(6, "data"), z(1)),
              sampling-edge: true,
            )
            #align(right, [
              b) #hex-range("A000", "FDFF")
            ])
          ]
        )
      ])
      #block(
        breakable: false,
        [
          #bus-diagram(
            addr: (u(2), d(7, "addr"), u(1),),
            rd: (e(1), l(9),),
            wr: (h(10),),
            a15: (e(1), h(8), e(1),),
            cs: (e(1), h(8), e(1),),
            data: (x(1), z(9),),
          )
          #align(right, [
            c) #hex-range("FE00", "FFFF")
          ])
          #v(1cm)
        ]
      )
    ]
  },
  caption: "External bus CPU read machine cycles"
)
#figure(
  {
    import timing: diagram, clock as c, data as d, either as e, high as h, low as l, unknown as u, undefined as x, high_impedance as z
    [
      #columns(2, [
        #block(
          breakable: false,
          [
            #bus-diagram(
              addr: (u(2), d(7, "addr"), u(1),),
              rd: (e(1), l(1), h(7), l(1),),
              wr: (h(5), l(3), h(2),),
              a15: (e(1), h(2), l(6), e(1),),
              cs: (e(1), h(8), e(1),),
              data: (x(1), z(4), d(4, "data"), z(1)),
            )
            #align(right, [
              a) #hex-range("0000", "7FFF") #footnote(<bootrom>)
            ])
          ]
        )
        #colbreak()
        #block(
          breakable: false,
          [
            #bus-diagram(
              addr: (u(2), d(7, "addr"), u(1),),
              rd: (e(1), l(1), h(7), l(1),),
              wr: (h(5), l(3), h(2),),
              a15: (e(1), h(8), e(1),),
              cs: (e(1), h(2), l(6), e(1),),
              data: (x(1), z(4), d(4, "data"), z(1)),
            )
            #align(right, [
              b) #hex-range("A000", "FDFF")
            ])
          ]
        )
      ])
      #block(
        breakable: false,
        [
          #bus-diagram(
            addr: (u(2), d(7, "addr"), u(1),),
            rd: (e(1), l(9),),
            wr: (h(10),),
            a15: (e(1), h(8), e(1),),
            cs: (e(1), h(8), e(1),),
            data: (x(1), z(9),),
          )
          #align(right, [
            c) #hex-range("FE00", "FFFF")
          ])
          #v(1cm)
        ]
      )
    ]
  },
  caption: "External bus CPU write machine cycles"
)

#figure(
  {
    import timing: diagram, clock as c, data as d, either as e, high as h, low as l, unknown as u, undefined as x, high_impedance as z
    [
      #columns(2, [
        #block(
          breakable: false,
          [
            #bus-diagram(
              addr: (u(1), d(8, "addr"), u(1),),
              rd: (e(1), l(9),),
              wr: (h(10),),
              a15: (e(1), l(8), e(1),),
              cs: (e(1), h(8), e(1),),
              data: (x(1), d(8, "data"), z(1)),
            )
            #align(right, [
              a) #hex-range("0000", "7FFF") #footnote(<bootrom>)
            ])
          ]
        )
        #colbreak()
        #block(
          breakable: false,
          [
            #bus-diagram(
              addr: (u(1), d(8, "addr"), u(1),),
              rd: (e(1), l(9),),
              wr: (h(10),),
              a15: (e(1), h(8), e(1),),
              cs: (e(1), l(8), e(1),),
              data: (x(1), d(8, "data"), z(1)),
            )
            #align(right, [
              b) #hex-range("A000", "FFFF")
            ])
          ]
        )
      ])
      #v(1cm)
    ]
  },
  caption: "External bus timings for OAM DMA read machine cycles"
)
