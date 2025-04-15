#import "../../common.typ": *
#import "../../timing.typ"

== Clocks

=== System clock

The system oscillator is the primary clock source in a Game Boy system, and it generates the *system clock*. Almost all other clocks are derived from the system clock using prescalers / clock dividers, but there are some exceptions:

- If a Game Boy is set up to do a serial transfer in secondary mode, the serial data register is directly clocked using the serial clock signal coming from the link port. Two Game Boys connected with a link cable never have precisely the same clock phase and frequency relative to each other, so the serial clock of the primary side has no direct relation to the system clock of the secondary side.

- The inserted game cartridge may use use other clock(s) internally. A typical example in some official games is the Real Time Clock (RTC), which is based on a 32.768 kHz oscillator and a clock-domain crossing circuit so that RTC data can be read using the cartridge bus while the RTC circuit is ticking independently using its own clock.

The Game Boy SoC uses two pins for the system oscillator: XI and XO. These pins along with some external components can be used from a Pierce oscillator circuit. Alternatively, the XI pin can be driven directly with a clock signal originating from somewhere else, and the XO pin can be left unconnected.

==== System clock frequency

In DMG and MGB consoles the system oscillator circuit uses an external quartz crystal with a nominal frequency of *4.194304 MHz* (= $2^22$ MHz = 4 MiHz) to form a Pierce oscillator circuit. This frequency is considered to be the standard frequency of a Game Boy.

In SGB the system oscillator input is directly driven by the ICD2 chip on the SGB cartridge. The clock is derived via /5 division of the main SNES / SFC clock, which has a different frequency depending on the console region (21.447 MHz NTSC, 21.281 MHz PAL). The SNES / SFC clock does not divide into 4.194304 MHz with integer division, so the clock seen by the SGB SoC is not the same as in DMG and MGB consoles. The frequency is higher, so everything is sped up by a small amount and audio has a slightly higher pitch.

In SGB2, just like SGB, the system oscillator input is driven by the ICD2 chip, but instead of using the SNES / SFC clock, the ICD2 chip is driven by a Pierce oscillator circuit with a 20.971520 MHz crystal. ICD2 then divides this frequency by /5 to obtain the final frequency seen by the SGB2 SoC, which is 4.194304 MHz that matches the standard DMG / MGB frequency.

=== Clock periods, T-cycles, and M-cycles

In digital logic, a clock switches between low and high states and every transition happens on a _clock edge_, which might be a rising edge (low → high transition) or a falling edge (high → low transition). A single _clock period_ is measured between two edges of the same type, so that the clock goes through two opposing edges and returns to its original state after the clock period. The typical convention is that a clock period consists of a rising edge and a falling edge.

In addition to the system clock and other clocks derived from it, Game Boy systems also use _inverted clocks_ in some peripherals, which means the rising edge of an inverted clock may happen at the same time as a falling edge of the original clock. @example-clock-periods shows two clock periods of the system clock and an inverted clock derived from it, and how they are out of phase due to clock inversion.

#figure({
  import timing: diagram, clock as c, data as d, either as e, high as h, low as l, unknown as u, undefined as x, high_impedance as z
  set text(20pt)
  diagram(
    w_scale: 2.0,
    y_scale: 2.0,
    (label: "CLK 4 MiHz", wave: (
      l(1),
      ..range(5).map((_) => c(1)),
    )),
    (label: "Inverted 4 MiHz", wave: (
      h(1),
      ..range(5).map((_) => c(1)),
    )),
    fg: () => {
      let rising_color = olive
      let falling_color = blue
      import cetz.draw
      let label(content) = align(center, text(10pt, content))
      draw.on-layer(-1, {
        draw.line((2, 7), (2, 8), stroke: (dash: "dashed"))
        draw.line((6, 7), (6, 8), stroke: (dash: "dashed"))
        draw.line((10, 7), (10, 8), stroke: (dash: "dashed"))
        draw.content((4, 7.5), label[period])
        draw.content((8, 7.5), label[period])

        draw.line((4, -1), (4, -3), stroke: (dash: "dashed"))
        draw.line((8, -1), (8, -3), stroke: (dash: "dashed"))
        draw.line((12, -1), (12, -3), stroke: (dash: "dashed"))
        draw.content((6, -2), label[also\ a period])
        draw.content((10, -2), label[also\ a period])
      })
    }
  )},
  caption: "Example clock periods"
) <example-clock-periods>

#figure({
  import timing: diagram, clock as c, data as d, either as e, high as h, low as l, unknown as u, undefined as x, high_impedance as z
  set text(20pt)
  diagram(
    w_scale: 2.0,
    y_scale: 2.0,
    (label: "CLK 4 MiHz", wave: (
      l(1),
      c(1, label: "T1"),
      c(1, label: "T1"),
      c(1, label: "T2"),
      c(1, label: "T2"),
      c(1, label: "T3"),
      c(1, label: "T3"),
      c(1, label: "T4"),
      c(1, label: "T4"),
      c(1),
    )),
    (label: "PHI 1 MiHz", wave: (
      l(1),
      c(4),
      c(4),
      c(1),
    )),
    fg: () => {
      let rising_color = olive
      let falling_color = blue
      import cetz.draw
      draw.on-layer(-1, {
        for x in range(1, 9, step: 2) {
          draw.set-style(stroke: (paint: rising_color.transparentize(50%), thickness: 0.1em))
          draw.line((x * 2, -1), (x * 2, 7))
        }
        for x in range(2, 9, step: 2) {
          draw.set-style(stroke: (paint: falling_color.transparentize(50%), thickness: 0.1em))
          draw.line((x * 2, -1), (x * 2, 7))
        }
      })
      let rising(content) = text(10pt, fill: rising_color, weight: "bold", content)
      let falling(content) = text(10pt, fill: falling_color, weight: "bold", content)
      let y = 8
      draw.content((1 * 2, y), rising[T1R])
      draw.content((2 * 2, y), falling[T1F])
      draw.content((3 * 2, y), rising[T2R])
      draw.content((4 * 2, y), falling[T2F])
      draw.content((5 * 2, y), rising[T3R])
      draw.content((6 * 2, y), falling[T3F])
      draw.content((7 * 2, y), rising[T4R])
      draw.content((8 * 2, y), falling[T4F])
    }
  )},
  caption: "Clock edges in a machine cycle"
) <reference-m-cycle>

