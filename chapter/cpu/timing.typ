#import "../../common.typ": *
#import "../../timing.typ"

== CPU core timing

=== Fetch/execute overlap

Sharp SM83 uses a microprocessor design technique known as _fetch/execute overlap_ to improve CPU performance by doing opcode fetches in parallel with instruction execution whenever possible. Since the CPU can only perform one memory access per M-cycle, it is worth it to try to do memory operations as soon as possible. Also, when doing a memory read, the CPU cannot use the data during the same M-cycle so the true minimum effective duration of instructions is 2 machine cycles, not 1 machine cycle.

Every instruction needs one machine cycle for the fetch stage, and at least one machine cycle for the decode/execute stage. However, the fetch stage of an instruction always overlaps with the last machine cycle of the execute stage of the previous instruction. The overlapping execute stage cycle may still do some work (e.g. ALU operation and/or register writeback) but memory access is reserved for the fetch stage of the next instruction.

Since all instructions effectively last one machine cycle longer, fetch/execute overlap is usually ignored in documentation intended for programmers. It is much easier to think of a program as a sequence of non-overlapping instructions and consider only the execute stages when calculating instruction durations. However, when emulating a SM83 CPU core, understanding and emulating the overlap can be useful.

#warning[
  Sharp SM831x is a family of single-chip SoCs from Sharp that use the SM83 CPU core, and their datasheet @sm831x includes a description of fetch/execute overlap. However, the description is not completely correct and can in fact be misleading.

  For example, the timing diagram includes an instruction that does not involve opcode fetch at all, and memory operations for two instructions are shown to happen at the same time, which is not possible.
]

==== Fetch/execute overlap timing example

Let's assume the CPU is executing a program that starts from the address #hex("1000") and contains the following instructions:

#let colors = (
  inc: rgb("#b3b3ff"),
  ldh: rgb("#fffcb3"),
  rst: rgb("#b3ffb3"),
  nop: rgb("#ffb3b3"),
)

#monotext[
  #table(
    columns: 2,
    align: left + horizon,
    stroke: none,
    hex("1000"), table.cell(fill: colors.inc)[INC A],
    hex("1001"), table.cell(fill: colors.ldh)[LDH (n), A],
    hex("1003"), table.cell(fill: colors.rst)[RST #hex("08")],
    hex("0008"), table.cell(fill: colors.nop)[NOP]
  )
]

The following timing diagram shows all memory operations done by the CPU, and
the fetch and execute stages of each instruction:

#figure({
  import timing: diagram, clock as c, data as d, either as e, high as h, low as l, unknown as u, undefined as x, high_impedance as z
  diagram(
    w_scale: 0.6, 
    (label: "CLK 4 MiHz", wave: (
      l(1),
      ..range(80).map(_ => c(1)),
      c(1),
    )),
    (label: "PHI 1 MiHz", wave: (
      l(1),
      ..range(10).map(_ => (c(4), c(4))).flatten(),
      c(1),
    )),
    (label: "Mem R/W", wave: (
      x(1),
      d(8, [R: opcode], fill: colors.inc),
      d(8, [R: opcode], fill: colors.ldh),
      d(8, [R: n], fill: colors.ldh),
      d(8, [W: A], fill: colors.ldh),
      d(8, [R: opcode], fill: colors.rst),
      x(8),
      d(8, [W: msb(PC)], fill: colors.rst),
      d(8, [W: lsb(PC)], fill: colors.rst),
      d(8, [R: opcode], fill: colors.nop),
      d(8, [R: opcode], opacity: 60%),
      x(1, opacity: 60%),
    )),
    (label: "Mem addr", wave: (
      x(1),
      d(8, hex("1000"), fill: colors.inc),
      d(8, hex("1001"), fill: colors.ldh),
      d(8, hex("1002"), fill: colors.ldh),
      d(8, monotext[#hex("FF00")+n], fill: colors.ldh),
      d(8, hex("1003"), fill: colors.rst),
      x(8),
      d(8, monotext[SP-1], fill: colors.rst),
      d(8, monotext[SP-2], fill: colors.rst),
      d(8, hex("0008"), fill: colors.nop),
      d(8, hex("0009"), opacity: 60%),
      x(1, opacity: 60%),
    )),
    (label: [Before #monotext[INC A]], wave: (
      d(9, [execute], opacity: 60% ),
      x(73),
    )),
    (label: monotext[INC A], wave: (
      x(1),
      d(8, [M1: fetch], fill: colors.inc),
      d(8, [M2: execute], fill: colors.inc),
      x(65),
    )),
    (label: monotext[LDH (n), A], wave: (
      x(9),
      d(8, [M1: fetch], fill: colors.ldh ),
      d(24, [M2-4: execute], fill: colors.ldh ),
      x(41),
    )),
    (label: monotext[RST #hex("08")], wave: (
      x(33),
      d(8, [M1: fetch], fill: colors.rst),
      d(32, [M2-5: execute], fill: colors.rst),
      x(9),
    )),
    (label: monotext[NOP], wave: (
      x(65),
      d(8, [M1: fetch], fill: colors.nop),
      d(8, [M2: execute], fill: colors.nop),
      x(1),
    )),
    (label: [After #monotext[NOP]], wave: (
      x(73),
      d(8, [M1: fetch], opacity: 60%),
      x(1, opacity: 60%),
    )),
  )},
  caption: "Fetch/execute overlap example"
)
