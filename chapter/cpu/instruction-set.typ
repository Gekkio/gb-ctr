#import "../../common.typ": *
#import "../../timing.typ"

#let ops = toml("../../opcodes.toml")

#let instruction-block(body, ..grid-args) = [
  #body
  #grid(
    columns: 1,
    gutter: 6pt,
    ..grid-args
  )
  #pagebreak()
]

#let simple-instruction-timing(mnemonic: str, timing_data: dictionary) = timing.diagram(w_scale: 0.9, ..{
  import timing: *
  let duration = timing_data.duration
  (
    (label: "M-cycle", wave: (
      x(1),
      ..range(duration).map((idx) => {
        let m_cycle = idx + 1
        d(8, "M" + str(m_cycle))
      }),
      x(1),
    )),
    (label: "Mem R/W", wave: (
      x(1),
      ..timing_data.mem_rw.enumerate().map(((idx, label)) => {
        let m_cycle = idx + 2
        if label == "U" { timing.u(8) } else { timing.d(8, label) }
      }),
      x(1, opacity: 40%),
    )),
  )
})

#let instruction-timing(mnemonic: str, timing_data: dictionary) = timing.diagram(w_scale: 0.9, ..{
  import timing: *
  let duration = timing_data.duration
  let map_cycle_labels(data) = data.enumerate().map(((idx, label)) => {
    let m_cycle = idx + 2
    if label == "U" {
      timing.u(8)
    } else {
      timing.d(8, label)
    }
  })
  (
    (label: "M-cycle", wave: (
      x(1),
      ..range(1 + duration).map((idx) => {
        let m_cycle = idx + 1
        if m_cycle == duration + 1 {
          d(8, "M" + str(m_cycle) + "/M1")
        } else {
          d(8, "M" + str(m_cycle))
        }
      }),
      x(1),
    )),
    (label: "Addr bus", wave: (
      x(1),
      timing.d(8, [Previous], opacity: 40%),
      ..map_cycle_labels(timing_data.addr),
      x(1, opacity: 40%),
    )),
    (label: "Data bus", wave: (
      x(1),
      timing.d(8, [IR ← mem], opacity: 40%),
      ..map_cycle_labels(timing_data.data),
      x(1, opacity: 40%),
    )),
    (label: "IDU op", wave: (
      x(1),
      timing.d(8, [Previous], opacity: 40%),
      ..map_cycle_labels(timing_data.idu_op),
      x(1, opacity: 40%),
    )),
    (label: "ALU op", wave: (
      x(1),
      timing.d(8, [Previous], opacity: 40%),
      ..map_cycle_labels(timing_data.alu_op),
      x(1, opacity: 40%),
    )),
    (label: "Misc op", wave: (
      x(1),
      timing.d(8, [Previous], opacity: 40%),
      ..map_cycle_labels(timing_data.misc_op),
      x(1, opacity: 40%),
    )),
  )
})

#let instruction = (body, mnemonic: str, opcode: content, operand_bytes: array, cb: false, flags: [-], timing: dictionary, simple-pseudocode: [], pseudocode: content) => instruction-block(
  body,
  grid(columns: (auto, 1fr, auto, 1fr),  gutter: 6pt,
    [*Opcode*], opcode,
    [*Duration*], if "cc_false" in timing [
      #let cc_false = if timing.cc_false.duration > 1 { str(timing.cc_false.duration) + " machine cycles" } else { "1 machine cycle" }
      #let cc_true = if timing.cc_true.duration > 1 { str(timing.cc_true.duration) + " machine cycles" } else { "1 machine cycle" }
      #cc_true (cc=true)\
      #cc_false (cc=false)
    ] else [
      #let duration = timing.duration
      #if duration > 1 [ #duration machine cycles ] else [ 1 machine cycle ]
    ],
    [*Length*], {
      let length = if cb { 2 } else { 1 } + operand_bytes.len()
      if cb {
        "2 bytes: CB prefix + opcode"
      } else if operand_bytes.len() > 0 {
        str(length) + " bytes: opcode + " + operand_bytes.join(" + ")
      } else {
        "1 byte: opcode"
      }
    },
    [*Flags*], flags,
  ),
  if "cc_false" in timing {
    [
      #block(breakable: false)[
        *Simple timing and pseudocode*
        #grid(columns: (auto, 1fr), gutter: 12pt,
          align(horizon, [_cc=true_]), simple-instruction-timing(mnemonic: mnemonic, timing_data: timing.cc_true),
          align(horizon, [_cc=false_]), simple-instruction-timing(mnemonic: mnemonic, timing_data: timing.cc_false),
        )
        #simple-pseudocode
      ]
      #block(breakable: false)[
        *Detailed timing and pseudocode*
        #grid(columns: (auto, 1fr), gutter: 12pt,
          align(horizon, [_cc=true_]), instruction-timing(mnemonic: mnemonic, timing_data: timing.cc_true),
          align(horizon, [_cc=false_]), instruction-timing(mnemonic: mnemonic, timing_data: timing.cc_false),
        )
        #pseudocode
      ]
    ]
  } else {
    [
      #block(breakable: false)[
        *Simple timing and pseudocode*
        #simple-instruction-timing(mnemonic: mnemonic, timing_data: timing)
        #simple-pseudocode
      ]
      #block(breakable: false)[
        *Detailed timing and pseudocode*
        #instruction-timing(mnemonic: mnemonic, timing_data: timing)
        #pseudocode
      ]
    ]
  }
)

#let flag-update = awesome[\u{f005}]

== Sharp SM83 instruction set

=== Overview

==== CB opcode prefix <op:CB>

==== Undefined opcodes <op:undefined>

#pagebreak()

=== 8-bit load instructions

#instruction(
  [
    ==== LD r, r': Load register (register) <op:LD_r_r>

    Load to the 8-bit register `r`, data from the 8-bit register `r'`.
  ],
  mnemonic: "LD r, r'",
  opcode: [#bin("01xxxyyy")/various],
  operand_bytes: (),
  timing: (
    duration: 1,
    mem_rw: ([opcode],),
    addr: ([PC],),
    data: ([IR ← mem],),
    idu_op: ([PC ← PC + 1],),
    alu_op: ([`r` ← `r'`],),
    misc_op: ("U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x41: # example: LD B, C
  B = C
```,
  pseudocode: ```python
# M2/M1
if IR == 0x41: # example: LD B, C
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1; B = C
```
)

#instruction(
  [
    ==== LD r, n: Load register (immediate) <op:LD_r_n>

    Load to the 8-bit register `r`, the immediate data `n`.
  ],
  mnemonic: "LD r, n",
  opcode: [#bin("00xxx110")/various],
  operand_bytes: ([`n`],),
  timing: (
    duration: 2,
    mem_rw: ([opcode], [R: `n`],),
    addr: ([PC], [PC],),
    data: ([Z ← mem], [IR ← mem],),
    idu_op: ([PC ← PC + 1], [PC ← PC + 1],),
    alu_op: ("U", [`r` ← Z],),
    misc_op: ("U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x06: # example: LD B, n
  B = read_memory(addr=PC); PC = PC + 1
```,
  pseudocode: ```python
# M2
if IR == 0x06: # example: LD B, n
  Z = read_memory(addr=PC); PC = PC + 1
  # M3/M1
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1; B = Z
```
)

#instruction(
  [
    ==== LD r, (HL): Load register (indirect HL) <op:LD_r_hl>

    Load to the 8-bit register `r`, data from the absolute address specified by the 16-bit register HL.
  ],
  mnemonic: "LD r, (HL)",
  opcode: [#bin("01xxx110")/various],
  operand_bytes: (),
  timing: (
    duration: 2,
    mem_rw: ([opcode], [R: data],),
    addr: ([HL], [PC],),
    data: ([Z ← mem], [IR ← mem],),
    idu_op: ("U", [PC ← PC + 1],),
    alu_op: ("U", [`r` ← Z],),
    misc_op: ("U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x46: # example: LD B, (HL)
  B = read_memory(addr=HL)
  ```,
  pseudocode: ```python
# M2
if IR == 0x46: # example: LD B, (HL)
  Z = read_memory(addr=HL)
  # M3/M1
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1; B = Z
  ```
)

#instruction(
  [
    ==== LD (HL), r: Load from register (indirect HL) <op:LD_hl_r>

    Load to the absolute address specified by the 16-bit register HL, data from the 8-bit register `r`.
  ],
  mnemonic: "LD (HL), r",
  opcode: [#bin("01110xxx")/various],
  operand_bytes: (),
  timing: (
    duration: 2,
    mem_rw: ([opcode], [W: data],),
    addr: ([HL], [PC],),
    data: ([mem ← `r`], [IR ← mem],),
    idu_op: ("U", [PC ← PC + 1],),
    alu_op: ("U", "U",),
    misc_op: ("U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x70: # example: LD (HL), B
  write_memory(addr=HL, data=B)
  ```,
  pseudocode: ```python
# M2
if IR == 0x70: # example: LD (HL), B
  write_memory(addr=HL, data=B)
  # M3/M1
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== LD (HL), n: Load from immediate data (indirect HL) <op:LD_hl_n>

    Load to the absolute address specified by the 16-bit register HL, the immediate data `n`.
  ],
  mnemonic: "LD (HL), n",
  opcode: [#bin("00110110")/#hex("36")],
  operand_bytes: ([`n`],),
  timing: (
    duration: 3,
    mem_rw: ([opcode], [R: `n`], [W: `n`],),
    addr: ([PC], [HL], [PC],),
    data: ([Z ← mem], [mem ← Z], [IR ← mem],),
    idu_op: ([PC ← PC + 1], "U", [PC ← PC + 1],),
    alu_op: ("U", "U", "U",),
    misc_op: ("U", "U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x36:
  n = read_memory(addr=PC); PC = PC + 1
  write_memory(addr=HL, data=n)
  ```,
  pseudocode: ```python
# M2
if IR == 0x36:
  Z = read_memory(addr=PC); PC = PC + 1
  # M3
  write_memory(addr=HL, data=Z)
  # M4/M1
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== LD A, (BC): Load accumulator (indirect BC) <op:LD_a_bc>

    Load to the 8-bit A register, data from the absolute address specified by the 16-bit register BC.
  ],
  mnemonic: "LD A, (BC)",
  opcode: [#bin("00001010")/#hex("0A")],
  operand_bytes: (),
  timing: (
    duration: 2,
    mem_rw: ([opcode], [R: data],),
    addr: ([BC], [PC],),
    data: ([Z ← mem], [IR ← mem],),
    idu_op: ("U", [PC ← PC + 1],),
    alu_op: ("U", [A ← Z],),
    misc_op: ("U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x0A:
  A = read_memory(addr=BC)
  ```,
  pseudocode: ```python
# M2
if IR == 0x0A:
  Z = read_memory(addr=BC)
  # M3/M1
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1; A = Z
  ```
)

#instruction(
  [
    ==== LD A, (DE): Load accumulator (indirect DE) <op:LD_a_de>

    Load to the 8-bit A register, data from the absolute address specified by the 16-bit register DE.
  ],
  mnemonic: "LD A, (DE)",
  opcode: [#bin("00011010")/#hex("1A")],
  operand_bytes: (),
  timing: (
    duration: 2,
    mem_rw: ([opcode], [R: data],),
    addr: ([DE], [PC],),
    data: ([Z ← mem], [IR ← mem],),
    idu_op: ("U", [PC ← PC + 1],),
    alu_op: ("U", [A ← Z],),
    misc_op: ("U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x1A:
  A = read_memory(addr=DE)
  ```,
  pseudocode: ```python
# M2
if IR == 0x1A:
  Z = read_memory(addr=DE)
  # M3/M1
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1; A = Z
  ```
)

#instruction(
  [
    ==== LD (BC), A: Load from accumulator (indirect BC) <op:LD_bc_a>

    Load to the absolute address specified by the 16-bit register BC, data from the 8-bit A register.
  ],
  mnemonic: "LD (BC), A",
  opcode: [#bin("00000010")/#hex("02")],
  operand_bytes: (),
  timing: (
    duration: 2,
    mem_rw: ([opcode], [W: data],),
    addr: ([BC], [PC],),
    data: ([mem ← A], [IR ← mem],),
    idu_op: ("U", [PC ← PC + 1],),
    alu_op: ("U", "U",),
    misc_op: ("U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x02:
  write_memory(addr=BC, data=A)
  ```,
  pseudocode: ```python
# M2
if IR == 0x02:
  write_memory(addr=BC, data=A)
  # M3/M1
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== LD (DE), A: Load from accumulator (indirect DE) <op:LD_de_a>

    Load to the absolute address specified by the 16-bit register DE, data from the 8-bit A register.
  ],
  mnemonic: "LD (DE), A",
  opcode: [#bin("00010010")/#hex("12")],
  operand_bytes: (),
  timing: (
    duration: 2,
    mem_rw: ([opcode], [W: data],),
    addr: ([DE], [PC],),
    data: ([mem ← A], [IR ← mem],),
    idu_op: ("U", [PC ← PC + 1],),
    alu_op: ("U", "U",),
    misc_op: ("U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x12:
  write_memory(addr=DE, data=A)
  ```,
  pseudocode: ```python
# M2
if IR == 0x12:
  write_memory(addr=DE, data=A)
  # M3/M1
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== LD A, (nn): Load accumulator (direct) <op:LD_a_nn>

    Load to the 8-bit A register, data from the absolute address specified by the 16-bit operand `nn`.
  ],
  mnemonic: "LD A, (nn)",
  opcode: [#bin("11111010")/#hex("FA")],
  operand_bytes: ([LSB(`nn`)], [MSB(`nn`)]),
  timing: (
    duration: 4,
    mem_rw: ([opcode], [R: lsb `nn`], [R: msb `nn`], [R: data],),
    addr: ([PC], [PC], [WZ], [PC],),
    data: ([Z ← mem], [W ← mem], [Z ← mem], [IR ← mem],),
    idu_op: ([PC ← PC + 1], [PC ← PC + 1], "U", [PC ← PC + 1],),
    alu_op: ("U", "U", "U", [A ← Z],),
    misc_op: ("U", "U", "U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xFA:
  nn_lsb = read_memory(addr=PC); PC = PC + 1
  nn_msb = read_memory(addr=PC); PC = PC + 1
  nn = unsigned_16(lsb=nn_lsb, msb=nn_msb)
  A = read_memory(addr=nn)
  ```,
  pseudocode: ```python
# M2
if IR == 0xFA:
  Z = read_memory(addr=PC); PC = PC + 1
  # M3
  W = read_memory(addr=PC); PC = PC + 1
  # M4
  Z = read_memory(addr=WZ)
  # M5/M1
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1; A = Z
  ```
)

#instruction(
  [
    ==== LD (nn), A: Load from accumulator (direct) <op:LD_nn_a>

    Load to the absolute address specified by the 16-bit operand `nn`, data from the 8-bit A register.
  ],
  mnemonic: "LD (nn), A",
  opcode: [#bin("11101010")/#hex("EA")],
  operand_bytes: ([LSB(`nn`)], [MSB(`nn`)]),
  timing: (
    duration: 4,
    mem_rw: ([opcode], [R: lsb `nn`], [R: msb `nn`], [W: data],),
    addr: ([PC], [PC], [WZ], [PC],),
    data: ([Z ← mem], [W ← mem], [mem ← A], [IR ← mem],),
    idu_op: ([PC ← PC + 1], [PC ← PC + 1], "U", [PC ← PC + 1],),
    alu_op: ("U", "U", "U", "U",),
    misc_op: ("U", "U", "U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xEA:
  nn_lsb = read_memory(addr=PC); PC = PC + 1
  nn_msb = read_memory(addr=PC); PC = PC + 1
  nn = unsigned_16(lsb=nn_lsb, msb=nn_msb)
  write_memory(addr=nn, data=A)
  ```,
  pseudocode: ```python
# M2
if IR == 0xEA:
  Z = read_memory(addr=PC); PC = PC + 1
  # M3
  W = read_memory(addr=PC); PC = PC + 1
  # M4
  write_memory(addr=WZ, data=A)
  # M5/M1
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== LDH A, (C): Load accumulator (indirect #hex("FF00")+C) <op:LDH_a_c>

    Load to the 8-bit A register, data from the address specified by the 8-bit C register. The full 16-bit absolute address is obtained by setting the most significant byte to #hex("FF") and the least significant byte to the value of C, so the possible range is #hex-range("FF00", "FFFF").
  ],
  mnemonic: "LDH A, (C)",
  opcode: [#bin("11110010")/#hex("F2")],
  operand_bytes: (),
  timing: (
    duration: 2,
    mem_rw: ([opcode], [R: data],),
    addr: ([#hex("FF00")+C], [PC],),
    data: ([Z ← mem], [IR ← mem],),
    idu_op: ("U", [PC ← PC + 1],),
    alu_op: ("U", [A ← Z],),
    misc_op: ("U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xF2:
  A = read_memory(addr=unsigned_16(lsb=C, msb=0xFF))
  ```,
  pseudocode: ```python
# M2
if IR == 0xF2:
  Z = read_memory(addr=unsigned_16(lsb=C, msb=0xFF))
  # M3/M1
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1; A = Z
  ```
)

#instruction(
  [
    ==== LDH (C), A: Load from accumulator (indirect #hex("FF00")+C) <op:LDH_c_a>

    Load to the address specified by the 8-bit C register, data from the 8-bit A register. The full 16-bit absolute address is obtained by setting the most significant byte to #hex("FF") and the least significant byte to the value of C, so the possible range is #hex-range("FF00", "FFFF").
  ],
  mnemonic: "LDH (C), A",
  opcode: [#bin("11100010")/#hex("E2")],
  operand_bytes: (),
  timing: (
    duration: 2,
    mem_rw: ([opcode], [W: data],),
    addr: ([#hex("FF00")+C], [PC],),
    data: ([mem ← A], [IR ← mem],),
    idu_op: ("U", [PC ← PC + 1],),
    alu_op: ("U", "U",),
    misc_op: ("U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xE2:
  write_memory(addr=unsigned_16(lsb=C, data=msb=0xFF), data=A)
  ```,
  pseudocode: ```python
# M2
if IR == 0xE2:
  write_memory(addr=unsigned_16(lsb=C, data=msb=0xFF), data=A)
  # M3/M1
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== LDH A, (n): Load accumulator (direct #hex("FF00")+n) <op:LDH_a_n>

    Load to the 8-bit A register, data from the address specified by the 8-bit immediate data `n`. The full 16-bit absolute address is obtained by setting the most significant byte to #hex("FF") and the least significant byte to the value of `n`, so the possible range is #hex-range("FF00", "FFFF").
  ],
  mnemonic: "LDH A, (n)",
  opcode: [#bin("11110000")/#hex("F0")],
  operand_bytes: ([`n`],),
  timing: (
    duration: 3,
    mem_rw: ([opcode], [R: `n`], [R: data],),
    addr: ([PC], [#hex("FF00")+Z], [PC],),
    data: ([Z ← mem], [Z ← mem], [IR ← mem],),
    idu_op: ([PC ← PC + 1], "U", [PC ← PC + 1],),
    alu_op: ("U", "U", [A ← Z],),
    misc_op: ("U", "U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xF0:
  n = read_memory(addr=PC); PC = PC + 1
  A = read_memory(addr=unsigned_16(lsb=n, msb=0xFF))
  ```,
  pseudocode: ```python
# M2
if IR == 0xF0:
  Z = read_memory(addr=PC); PC = PC + 1
  # M3
  Z = read_memory(addr=unsigned_16(lsb=Z, msb=0xFF))
  # M4/M1
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1; A = Z
  ```
)

#instruction(
  [
    ==== LDH (n), A: Load from accumulator (direct #hex("FF00")+n) <op:LDH_n_a>

    Load to the address specified by the 8-bit immediate data `n`, data from the 8-bit A register. The full 16-bit absolute address is obtained by setting the most significant byte to #hex("FF") and the least significant byte to the value of `n`, so the possible range is #hex-range("FF00", "FFFF").
  ],
  mnemonic: "LDH (n), A",
  opcode: [#bin("11100000")/#hex("E0")],
  operand_bytes: ([`n`],),
  timing: (
    duration: 3,
    mem_rw: ([opcode], [R: `n`], [W: data],),
    addr: ([PC], [#hex("FF00")+Z], [PC],),
    data: ([Z ← mem], [mem ← A], [IR ← mem],),
    idu_op: ([PC ← PC + 1], "U", [PC ← PC + 1],),
    alu_op: ("U", "U", "U",),
    misc_op: ("U", "U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xE0:
  n = read_memory(addr=PC); PC = PC + 1
  write_memory(addr=unsigned_16(lsb=n, msb=0xFF), data=A)
  ```,
  pseudocode: ```python
# M2
if IR == 0xE0:
  Z = read_memory(addr=PC); PC = PC + 1
  # M3
  write_memory(addr=unsigned_16(lsb=Z, msb=0xFF), data=A)
  # M4/M1
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== LD A, (HL-): Load accumulator (indirect HL, decrement) <op:LD_a_hld>

    Load to the 8-bit A register, data from the absolute address specified by the 16-bit register HL. The value of HL is decremented after the memory read.
  ],
  mnemonic: "LD A, (HL-)",
  opcode: [#bin("00111010")/#hex("3A")],
  operand_bytes: (),
  timing: (
    duration: 2,
    mem_rw: ([opcode], [R: data],),
    addr: ([HL], [PC],),
    data: ([Z ← mem], [IR ← mem],),
    idu_op: ([HL ← HL - 1], [PC ← PC + 1],),
    alu_op: ("U", [A ← Z],),
    misc_op: ("U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x3A:
  A = read_memory(addr=HL); HL = HL - 1
  ```,
  pseudocode: ```python
# M2
if IR == 0x3A:
  Z = read_memory(addr=HL); HL = HL - 1
  # M3/M1
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1; A = Z
  ```
)

#instruction(
  [
    ==== LD (HL-), A: Load from accumulator (indirect HL, decrement) <op:LD_hld_a>

    Load to the absolute address specified by the 16-bit register HL, data from the 8-bit A register. The value of HL is decremented after the memory write.
  ],
  mnemonic: "LD (HL-), A",
  opcode: [#bin("00110010")/#hex("32")],
  operand_bytes: (),
  timing: (
    duration: 2,
    mem_rw: ([opcode], [W: data],),
    addr: ([HL], [PC],),
    data: ([mem ← A], [IR ← mem],),
    idu_op: ([HL ← HL - 1], [PC ← PC + 1],),
    alu_op: ("U", "U",),
    misc_op: ("U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x32:
  write_memory(addr=HL, data=A); HL = HL - 1
  ```,
  pseudocode: ```python
# M2
if IR == 0x32:
  write_memory(addr=HL, data=A); HL = HL - 1
  # M3/M1
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== LD A, (HL+): Load accumulator (indirect HL, increment) <op:LD_a_hli>

    Load to the 8-bit A register, data from the absolute address specified by the 16-bit register HL. The value of HL is incremented after the memory read.
  ],
  mnemonic: "LD A, (HL+)",
  opcode: [#bin("00101010")/#hex("2A")],
  operand_bytes: (),
  timing: (
    duration: 2,
    mem_rw: ([opcode], [R: data],),
    addr: ([HL], [PC],),
    data: ([Z ← mem], [IR ← mem],),
    idu_op: ([HL ← HL + 1], [PC ← PC + 1],),
    alu_op: ("U", [A ← Z],),
    misc_op: ("U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x2A:
  A = read_memory(addr=HL); HL = HL + 1
  ```,
  pseudocode: ```python
# M2
if IR == 0x2A:
  Z = read_memory(addr=HL); HL = HL + 1
  # M3/M1
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1; A = Z
  ```
)

#instruction(
  [
    ==== LD (HL+), A: Load from accumulator (indirect HL, increment) <op:LD_hli_a>

    Load to the absolute address specified by the 16-bit register HL, data from the 8-bit A register. The value of HL is decremented after the memory write.
  ],
  mnemonic: "LD (HL+), A",
  opcode: [#bin("00100010")/#hex("22")],
  operand_bytes: (),
  timing: (
    duration: 2,
    mem_rw: ([opcode], [W: data],),
    addr: ([HL], [PC],),
    data: ([mem ← A], [IR ← mem],),
    idu_op: ([HL ← HL + 1], [PC ← PC + 1],),
    alu_op: ("U", "U",),
    misc_op: ("U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x22:
  write_memory(addr=HL, data=A); HL = HL + 1
  ```,
  pseudocode: ```python
# M2
if IR == 0x22:
  write_memory(addr=HL, data=A); HL = HL + 1
  # M3/M1
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

=== 16-bit load instructions

#instruction(
  [
    ==== LD rr, nn: Load 16-bit register / register pair <op:LD_rr_nn>

    Load to the 16-bit register `rr`, the immediate 16-bit data `nn`.
  ],
  mnemonic: "LD rr, nn",
  opcode: [#bin("00xx0001")/various],
  operand_bytes: ([LSB(`nn`)], [MSB(`nn`)]),
  timing: (
    duration: 3,
    mem_rw: ([opcode], [R: lsb `nn`], [R: msb `nn`],),
    addr: ([PC], [PC], [PC],),
    data: ([Z ← mem], [W ← mem], [IR ← mem],),
    idu_op: ([PC ← PC + 1], [PC ← PC + 1], [PC ← PC + 1],),
    alu_op: ("U", "U", "U",),
    misc_op: ("U", "U", [`rr` ← WZ],),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x01: # example: LD BC, nn
  nn_lsb = read_memory(addr=PC); PC = PC + 1
  nn_msb = read_memory(addr=PC); PC = PC + 1
  nn = unsigned_16(lsb=nn_lsb, msb=nn_msb)
  BC = nn
  ```,
  pseudocode: ```python
# M2
if IR == 0x01: # example: LD BC, nn
  Z = read_memory(addr=PC); PC = PC + 1
  # M3
  W = read_memory(addr=PC); PC = PC + 1
  # M4/M1
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1; BC = WZ
  ```
)

#instruction(
  [
    ==== LD (nn), SP: Load from stack pointer (direct) <op:LD_nn_sp>

    Load to the absolute address specified by the 16-bit operand `nn`, data from the 16-bit SP register.
  ],
  mnemonic: "LD (nn), SP",
  opcode: [#bin("00001000")/#hex("08")],
  operand_bytes: ([LSB(`nn`)], [MSB(`nn`)]),
  timing: (
    duration: 5,
    mem_rw: ([opcode], [R: Z], [R: W], [W: SPH], [W: SPL],),
    addr: ([PC], [PC], [WZ], [WZ], [PC],),
    data: ([Z ← mem], [W ← mem], [mem ← SPL], [mem ← SPH], [IR ← mem],),
    idu_op: ([PC ← PC + 1], [PC ← PC + 1], [WZ ← WZ + 1], "U", [PC ← PC + 1],),
    alu_op: ("U", "U", "U", "U", "U",),
    misc_op: ("U", "U", "U", "U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x08:
  nn_lsb = read_memory(addr=PC); PC = PC + 1
  nn_msb = read_memory(addr=PC); PC = PC + 1
  nn = unsigned_16(lsb=nn_lsb, msb=nn_msb)
  write_memory(addr=nn, data=lsb(SP)); nn = nn + 1
  write_memory(addr=nn, data=msb(SP))
  ```,
  pseudocode: ```python
# M2
if IR == 0x08:
  Z = read_memory(addr=PC); PC = PC + 1
  # M3
  W = read_memory(addr=PC); PC = PC + 1
  # M4
  write_memory(addr=WZ, data=lsb(SP)); WZ = WZ + 1
  # M5
  write_memory(addr=WZ, data=msb(SP))
  # M6/M1
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== LD SP, HL: Load stack pointer from HL <op:LD_sp_hl>

    Load to the 16-bit SP register, data from the 16-bit HL register.
  ],
  mnemonic: "LD SP, HL",
  opcode: [#bin("11111001")/#hex("F9")],
  operand_bytes: (),
  timing: (
    duration: 2,
    mem_rw: ([opcode], "U",),
    addr: ([HL], [PC],),
    data: ("U", [IR ← mem],),
    idu_op: ([SP ← HL], [PC ← PC + 1],),
    alu_op: ("U", "U",),
    misc_op: ("U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xF9:
  SP = HL
  ```,
  pseudocode: ```python
# M2
if IR == 0xF9:
  SP = HL
  # M3/M1
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== PUSH rr: Push to stack <op:PUSH_rr>

    Push to the stack memory, data from the 16-bit register `rr`.
  ],
  mnemonic: "PUSH rr",
  opcode: [#bin("11xx0101")/various],
  operand_bytes: (),
  timing: (
    duration: 4,
    mem_rw: ([opcode], "U", [W: msb `rr`], [W: lsb `rr`],),
    addr: ([SP], [SP], [SP], [PC],),
    data: ("U", [mem ← msb `rr`], [mem ← lsb `rr`], [IR ← mem],),
    idu_op: ([SP ← SP - 1], [SP ← SP - 1], [SP ← SP], [PC ← PC + 1],),
    alu_op: ("U", "U", "U", "U",),
    misc_op: ("U", "U", "U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xC5: # example: PUSH BC
  SP = SP - 1
  write_memory(addr=SP, data=msb(BC)); SP = SP - 1
  write_memory(addr=SP, data=lsb(BC))
  ```,
  pseudocode: ```python
# M2
if IR == 0xC5: # example: PUSH BC
  SP = SP - 1
  # M3
  write_memory(addr=SP, data=msb(BC)); SP = SP - 1
  # M4
  write_memory(addr=SP, data=lsb(BC))
  # M5/M1
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== POP rr: Pop from stack <op:POP_rr>

    Pops to the 16-bit register `rr`, data from the stack memory.

    This instruction does not do calculations that affect flags, but POP AF completely replaces the F register value, so all flags are changed based on the 8-bit data that is read from memory.
  ],
  mnemonic: "POP rr",
  flags: [See the instruction description],
  opcode: [#bin("11xx0001")/various],
  operand_bytes: (),
  timing: (
    duration: 3,
    mem_rw: ([opcode], [R: lsb `rr`], [R: msb `rr`],),
    addr: ([SP], [SP], [PC],),
    data: ([Z ← mem], [W ← mem], [IR ← mem],),
    idu_op: ([SP ← SP + 1], [SP ← SP + 1], [PC ← PC + 1],),
    alu_op: ("U", "U", "U",),
    misc_op: ("U", "U", [`rr` ← WZ],),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xC1: # example: POP BC
  lsb = read_memory(addr=SP); SP = SP + 1
  msb = read_memory(addr=SP); SP = SP + 1
  BC = unsigned_16(lsb=lsb, msb=msb)
  ```,
  pseudocode: ```python
# M2
if IR == 0xC1: # example: POP BC
  Z = read_memory(addr=SP); SP = SP + 1
  # M3
  W = read_memory(addr=SP); SP = SP + 1
  # M4/M1
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1; BC = WZ
  ```
)

#instruction(
  [
    ==== LD HL, SP+e: Load HL from adjusted stack pointer <op:LD_hl_sp_e>

    Load to the HL register, 16-bit data calculated by adding the signed 8-bit operand `e` to the 16-bit value of the SP register.
  ],
  mnemonic: "LD HL, SP+e",
  flags: [Z = 0, N = 0, H = #flag-update, C = #flag-update],
  opcode: [#bin("11111000")/#hex("F8")],
  operand_bytes: ([`e`],),
  timing: (
    duration: 3,
    mem_rw: ([opcode], [R: `e`], "U",),
    addr: ([PC], [#hex("0000")], [PC],),
    data: ([Z ← mem], "U", [IR ← mem],),
    idu_op: ([PC ← PC + 1], "U", [PC ← PC + 1],),
    alu_op: ("U", [L ← SPL + Z], [H ← SPH +#sub[c] adj],),
    misc_op: ("U", "U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xF8:
  e = signed_8(read_memory(addr=PC)); PC = PC + 1
  result, carry_per_bit = SP + e
  HL = result
  flags.Z = 0
  flags.N = 0
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  ```,
  pseudocode: ```python
# M2
if IR == 0xF8:
  Z = read_memory(addr=PC); PC = PC + 1
  # M3
  result, carry_per_bit = lsb(SP) + Z
  L = result
  flags.Z = 0
  flags.N = 0
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  Z_sign = bit(7, Z)
  # M4/M1
  adj = 0xFF if Z_sign else 0x00
  result = msb(SP) + adj + flags.C
  H = result
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

=== 8-bit arithmetic and logical instructions

#instruction(
  [
    ==== ADD r: Add (register) <op:ADD_r>

    Adds to the 8-bit A register, the 8-bit register `r`, and stores the result back into the A register.
  ],
  mnemonic: "ADD r",
  flags: [Z = #flag-update, N = 0, H = #flag-update, C = #flag-update],
  opcode: [#bin("10000xxx")/various],
  operand_bytes: (),
  timing: (
    duration: 1,
    mem_rw: ([opcode],),
    addr: ([PC],),
    data: ([IR ← mem],),
    idu_op: ([PC ← PC + 1],),
    alu_op: ([A ← A + `r`],),
    misc_op: ("U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x80: # example: ADD B
  result, carry_per_bit = A + B
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  ```,
  pseudocode: ```python
# M2/M1
if IR == 0x80: # example: ADD B
  result, carry_per_bit = A + B
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== ADD (HL): Add (indirect HL) <op:ADD_hl>

    Adds to the 8-bit A register, data from the absolute address specified by the 16-bit register HL, and stores the result back into the A register.
  ],
  mnemonic: "ADD (HL)",
  flags: [Z = #flag-update, N = 0, H = #flag-update, C = #flag-update],
  opcode: [#bin("10000110")/#hex("86")],
  operand_bytes: (),
  timing: (
    duration: 2,
    mem_rw: ([opcode], [R: data],),
    addr: ([HL], [PC],),
    data: ([Z ← mem], [IR ← mem],),
    idu_op: ("U", [PC ← PC + 1],),
    alu_op: ("U", [A ← A + Z],),
    misc_op: ("U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x86:
  data = read_memory(addr=HL)
  result, carry_per_bit = A + data
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  ```,
  pseudocode: ```python
# M2
if IR == 0x86:
  Z = read_memory(addr=HL)
  # M3/M1
  result, carry_per_bit = A + Z
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== ADD n: Add (immediate) <op:ADD_n>

    Adds to the 8-bit A register, the immediate data `n`, and stores the result back into the A register.
  ],
  mnemonic: "ADD n",
  flags: [Z = #flag-update, N = 0, H = #flag-update, C = #flag-update],
  opcode: [#bin("11000110")/#hex("C6")],
  operand_bytes: ([`n`],),
  timing: (
    duration: 2,
    mem_rw: ([opcode], [R: `n`],),
    addr: ([PC], [PC],),
    data: ([Z ← mem], [IR ← mem],),
    idu_op: ([PC ← PC + 1], [PC ← PC + 1],),
    alu_op: ("U", [A ← A + Z],),
    misc_op: ("U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xC6:
  n = read_memory(addr=PC); PC = PC + 1
  result, carry_per_bit = A + n
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  ```,
  pseudocode: ```python
# M2
if IR == 0xC6:
  Z = read_memory(addr=PC); PC = PC + 1
  # M3/M1
  result, carry_per_bit = A + Z
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== ADC r: Add with carry (register) <op:ADC_r>

    Adds to the 8-bit A register, the carry flag and the 8-bit register `r`, and stores the result back into the A register.

  ],
  mnemonic: "ADC r",
  flags: [Z = #flag-update, N = 0, H = #flag-update, C = #flag-update],
  opcode: [#bin("10001xxx")/various],
  operand_bytes: (),
  timing: (
    duration: 1,
    mem_rw: ([opcode],),
    addr: ([PC],),
    data: ([IR ← mem],),
    idu_op: ([PC ← PC + 1],),
    alu_op: ([A ← A +#sub[c] `r`],),
    misc_op: ("U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x88: # example: ADC B
  result, carry_per_bit = A + B + flags.C
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  ```,
  pseudocode: ```python
# M2/M1
if IR == 0x88: # example: ADC B
  result, carry_per_bit = A + B + flags.C
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== ADC (HL): Add with carry (indirect HL) <op:ADC_hl>

    Adds to the 8-bit A register, the carry flag and data from the absolute address specified by the 16-bit register HL, and stores the result back into the A register.
  ],
  mnemonic: "ADC (HL)",
  flags: [Z = #flag-update, N = 0, H = #flag-update, C = #flag-update],
  opcode: [#bin("10001110")/#hex("8E")],
  operand_bytes: (),
  timing: (
    duration: 2,
    mem_rw: ([opcode], [R: data],),
    addr: ([HL], [PC],),
    data: ([Z ← mem], [IR ← mem],),
    idu_op: ("U", [PC ← PC + 1],),
    alu_op: ("U", [A ← A +#sub[c] Z],),
    misc_op: ("U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x8E:
  data = read_memory(addr=HL)
  result, carry_per_bit = A + data + flags.C
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  ```,
  pseudocode: ```python
# M2
if IR == 0x8E:
  Z = read_memory(addr=HL)
  # M3/M1
  result, carry_per_bit = A + Z + flags.C
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== ADC n: Add with carry (immediate) <op:ADC_n>

    Adds to the 8-bit A register, the carry flag and the immediate data `n`, and stores the result back into the A register.
  ],
  mnemonic: "ADC n",
  flags: [Z = #flag-update, N = 0, H = #flag-update, C = #flag-update],
  opcode: [#bin("11001110")/#hex("CE")],
  operand_bytes: ([`n`],),
  timing: (
    duration: 2,
    mem_rw: ([opcode], [R: `n`],),
    addr: ([PC], [PC],),
    data: ([Z ← mem], [IR ← mem],),
    idu_op: ([PC ← PC + 1], [PC ← PC + 1],),
    alu_op: ("U", [A ← A +#sub[c] Z],),
    misc_op: ("U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xCE:
  n = read_memory(addr=PC); PC = PC + 1
  result, carry_per_bit = A + n + flags.C
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  ```,
  pseudocode: ```python
# M2
if IR == 0xCE:
  Z = read_memory(addr=PC); PC = PC + 1
  # M3/M1
  result, carry_per_bit = A + Z + flags.C
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== SUB r: Subtract (register) <op:SUB_r>

    Subtracts from the 8-bit A register, the 8-bit register `r`, and stores the result back into the A register.
  ],
  mnemonic: "SUB r",
  flags: [Z = #flag-update, N = 1, H = #flag-update, C = #flag-update],
  opcode: [#bin("10010xxx")/various],
  operand_bytes: (),
  timing: (
    duration: 1,
    mem_rw: ([opcode],),
    addr: ([PC],),
    data: ([IR ← mem],),
    idu_op: ([PC ← PC + 1],),
    alu_op: ([A ← A - `r`],),
    misc_op: ("U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x90: # example: SUB B
  result, carry_per_bit = A - B
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 1
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  ```,
  pseudocode: ```python
# M2/M1
if IR == 0x90: # example: SUB B
  result, carry_per_bit = A - B
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 1
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== SUB (HL): Subtract (indirect HL) <op:SUB_hl>

    Subtracts from the 8-bit A register, data from the absolute address specified by the 16-bit register HL, and stores the result back into the A register.
  ],
  mnemonic: "SUB (HL)",
  flags: [Z = #flag-update, N = 1, H = #flag-update, C = #flag-update],
  opcode: [#bin("10010110")/#hex("96")],
  operand_bytes: (),
  timing: (
    duration: 2,
    mem_rw: ([opcode], [R: data],),
    addr: ([HL], [PC],),
    data: ([Z ← mem], [IR ← mem],),
    idu_op: ("U", [PC ← PC + 1],),
    alu_op: ("U", [A ← A - Z],),
    misc_op: ("U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x96:
  data = read_memory(addr=HL)
  result, carry_per_bit = A - data
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 1
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  ```,
  pseudocode: ```python
# M2
if IR == 0x96:
  Z = read_memory(addr=HL)
  # M3/M1
  result, carry_per_bit = A - Z
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 1
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== SUB n: Subtract (immediate) <op:SUB_n>

    Subtracts from the 8-bit A register, the immediate data `n`, and stores the result back into the A register.
  ],
  mnemonic: "SUB n",
  flags: [Z = #flag-update, N = 1, H = #flag-update, C = #flag-update],
  opcode: [#bin("11010110")/#hex("D6")],
  operand_bytes: ([`n`],),
  timing: (
    duration: 2,
    mem_rw: ([opcode], [R: `n`],),
    addr: ([PC], [PC],),
    data: ([Z ← mem], [IR ← mem],),
    idu_op: ([PC ← PC + 1], [PC ← PC + 1],),
    alu_op: ("U", [A ← A - Z],),
    misc_op: ("U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xD6:
  n = read_memory(addr=PC); PC = PC + 1
  result, carry_per_bit = A - n
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 1
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  ```,
  pseudocode: ```python
# M2
if IR == 0xD6:
  Z = read_memory(addr=PC); PC = PC + 1
  # M3/M1
  result, carry_per_bit = A - Z
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 1
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== SBC r: Subtract with carry (register) <op:SBC_r>

    Subtracts from the 8-bit A register, the carry flag and the 8-bit register `r`, and stores the result back into the A register.
  ],
  mnemonic: "SBC r",
  flags: [Z = #flag-update, N = 1, H = #flag-update, C = #flag-update],
  opcode: [#bin("10011xxx")/various],
  operand_bytes: (),
  timing: (
    duration: 1,
    mem_rw: ([opcode],),
    addr: ([PC],),
    data: ([IR ← mem],),
    idu_op: ([PC ← PC + 1],),
    alu_op: ([A ← A -#sub[c] `r`],),
    misc_op: ("U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x98: # example: SBC B
  result, carry_per_bit = A - B - flags.C
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 1
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  ```,
  pseudocode: ```python
# M2/M1
if IR == 0x98: # example: SBC B
  result, carry_per_bit = A - B - flags.C
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 1
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== SBC (HL): Subtract with carry (indirect HL) <op:SBC_hl>

    Subtracts from the 8-bit A register, the carry flag and data from the absolute address specified by the 16-bit register HL, and stores the result back into the A register.
  ],
  mnemonic: "SBC (HL)",
  flags: [Z = #flag-update, N = 1, H = #flag-update, C = #flag-update],
  opcode: [#bin("10011110")/#hex("9E")],
  operand_bytes: (),
  timing: (
    duration: 2,
    mem_rw: ([opcode], [R: data],),
    addr: ([HL], [PC],),
    data: ([Z ← mem], [IR ← mem],),
    idu_op: ("U", [PC ← PC + 1],),
    alu_op: ("U", [A ← A -#sub[c] Z],),
    misc_op: ("U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x9E:
  data = read_memory(addr=HL)
  result, carry_per_bit = A - data - flags.C
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 1
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  ```,
  pseudocode: ```python
# M2
if IR == 0x9E:
  Z = read_memory(addr=HL)
  # M3/M1
  result, carry_per_bit = A - Z - flags.C
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 1
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== SBC n: Subtract with carry (immediate) <op:SBC_n>

    Subtracts from the 8-bit A register, the carry flag and the immediate data `n`, and stores the result back into the A register.
  ],
  mnemonic: "SBC n",
  flags: [Z = #flag-update, N = 1, H = #flag-update, C = #flag-update],
  opcode: [#bin("11011110")/#hex("DE")],
  operand_bytes: ([`n`],),
  timing: (
    duration: 2,
    mem_rw: ([opcode], [R: `n`],),
    addr: ([PC], [PC],),
    data: ([Z ← mem], [IR ← mem],),
    idu_op: ([PC ← PC + 1], [PC ← PC + 1],),
    alu_op: ("U", [A ← A -#sub[c] Z],),
    misc_op: ("U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xDE:
  n = read_memory(addr=PC); PC = PC + 1
  result, carry_per_bit = A - n - flags.C
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 1
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  ```,
  pseudocode: ```python
# M2
if IR == 0xDE:
  Z = read_memory(addr=PC); PC = PC + 1
  # M3/M1
  result, carry_per_bit = A - Z - flags.C
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 1
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== CP r: Compare (register) <op:CP_r>

    Subtracts from the 8-bit A register, the 8-bit register `r`, and updates flags based on the result. This instruction is basically identical to #link(<op:SUB_r>)[SUB r], but does not update the A register.
  ],
  mnemonic: "CP r",
  flags: [Z = #flag-update, N = 1, H = #flag-update, C = #flag-update],
  opcode: [#bin("10111xxx")/various],
  operand_bytes: (),
  timing: (
    duration: 1,
    mem_rw: ([opcode],),
    addr: ([PC],),
    data: ([IR ← mem],),
    idu_op: ([PC ← PC + 1],),
    alu_op: ([A - `r`],),
    misc_op: ("U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xB8: # example: CP B
  result, carry_per_bit = A - B
  flags.Z = 1 if result == 0 else 0
  flags.N = 1
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  ```,
  pseudocode: ```python
# M2/M1
if IR == 0xB8: # example: CP B
  result, carry_per_bit = A - B
  flags.Z = 1 if result == 0 else 0
  flags.N = 1
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== CP (HL): Compare (indirect HL) <op:CP_hl>

    Subtracts from the 8-bit A register, data from the absolute address specified by the 16-bit register HL, and updates flags based on the result. This instruction is basically identical to #link(<op:SUB_hl>)[SUB (HL)], but does not update the A register.
  ],
  mnemonic: "CP (HL)",
  flags: [Z = #flag-update, N = 1, H = #flag-update, C = #flag-update],
  opcode: [#bin("10011110")/#hex("9E")],
  operand_bytes: (),
  timing: (
    duration: 2,
    mem_rw: ([opcode], [R: data],),
    addr: ([HL], [PC],),
    data: ([Z ← mem], [IR ← mem],),
    idu_op: ("U", [PC ← PC + 1],),
    alu_op: ("U", [A - Z],),
    misc_op: ("U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xBE:
  data = read_memory(addr=HL)
  result, carry_per_bit = A - data
  flags.Z = 1 if result == 0 else 0
  flags.N = 1
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  ```,
  pseudocode: ```python
# M2
if IR == 0xBE:
  Z = read_memory(addr=HL)
  # M3/M1
  result, carry_per_bit = A - Z
  flags.Z = 1 if result == 0 else 0
  flags.N = 1
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== CP n: Compare (immediate) <op:CP_n>

    Subtracts from the 8-bit A register, the immediate data `n`, and updates flags based on the result. This instruction is basically identical to #link(<op:SUB_n>)[SUB n], but does not update the A register.
  ],
  mnemonic: "CP n",
  flags: [Z = #flag-update, N = 1, H = #flag-update, C = #flag-update],
  opcode: [#bin("11111110")/#hex("FE")],
  operand_bytes: ([`n`],),
  timing: (
    duration: 2,
    mem_rw: ([opcode], [R: `n`],),
    addr: ([PC], [PC],),
    data: ([Z ← mem], [IR ← mem],),
    idu_op: ([PC ← PC + 1], [PC ← PC + 1],),
    alu_op: ("U", [A - Z],),
    misc_op: ("U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xFE:
  n = read_memory(addr=PC); PC = PC + 1
  result, carry_per_bit = A - n
  flags.Z = 1 if result == 0 else 0
  flags.N = 1
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  ```,
  pseudocode: ```python
# M2
if IR == 0xFE:
  Z = read_memory(addr=PC); PC = PC + 1
  # M3/M1
  result, carry_per_bit = A - Z
  flags.Z = 1 if result == 0 else 0
  flags.N = 1
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  ```
)

#instruction(
  [
    ==== INC r: Increment (register) <op:INC_r>

    Increments data in the 8-bit register `r`.
  ],
  mnemonic: "INC r",
  flags: [Z = #flag-update, N = 0, H = #flag-update],
  opcode: [#bin("00xxx100")/various],
  operand_bytes: (),
  timing: (
    duration: 1,
    mem_rw: ([opcode],),
    addr: ([PC],),
    data: ([IR ← mem],),
    idu_op: ([PC ← PC + 1],),
    alu_op: ([`r` ← `r` + 1],),
    misc_op: ("U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x04: # example: INC B
  result, carry_per_bit = B + 1
  B = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 1 if carry_per_bit[3] else 0
  ```,
  pseudocode: ```python
if opcode == 0x04: # example: INC B
  # M2/M1
  result, carry_per_bit = B + 1
  B = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 1 if carry_per_bit[3] else 0
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== INC (HL): Increment (indirect HL) <op:INC_hl>

    Increments data at the absolute address specified by the 16-bit register HL.
  ],
  mnemonic: "INC (HL)",
  flags: [Z = #flag-update, N = 0, H = #flag-update],
  opcode: [#bin("00110100")/#hex("34")],
  operand_bytes: (),
  timing: (
    duration: 3,
    mem_rw: ([opcode], [R: data], [W: data],),
    addr: ([HL], [HL], [PC],),
    data: ([Z ← mem], [mem ← ALU], [IR ← mem],),
    idu_op: ("U", "U", [PC ← PC + 1],),
    alu_op: ("U", [mem ← Z + 1], "U",),
    misc_op: ("U", "U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x34:
  data = read_memory(addr=HL)
  result, carry_per_bit = data + 1
  write_memory(addr=HL, data=result)
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 1 if carry_per_bit[3] else 0
  ```,
  pseudocode: ```python
# M2
if IR == 0x34:
  Z = read_memory(addr=HL)
  # M3
  result, carry_per_bit = Z + 1
  write_memory(addr=HL, data=result)
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 1 if carry_per_bit[3] else 0
  # M4/M1
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== DEC r: Decrement (register) <op:DEC_r>

    Increments data in the 8-bit register `r`.
  ],
  mnemonic: "DEC r",
  flags: [Z = #flag-update, N = 1, H = #flag-update],
  opcode: [#bin("00xxx101")/various],
  operand_bytes: (),
  timing: (
    duration: 1,
    mem_rw: ([opcode],),
    addr: ([PC],),
    data: ([IR ← mem],),
    idu_op: ([PC ← PC + 1],),
    alu_op: ([`r` ← `r` - 1],),
    misc_op: ("U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
# example: DEC B
if opcode == 0x05:
  result, carry_per_bit = B - 1
  B = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 1
  flags.H = 1 if carry_per_bit[3] else 0
  ```,
  pseudocode: ```python
# M2/M1
if IR == 0x05: # example: DEC B
  result, carry_per_bit = B - 1
  B = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 1
  flags.H = 1 if carry_per_bit[3] else 0
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== DEC (HL): Decrement (indirect HL) <op:DEC_hl>

    Decrements data at the absolute address specified by the 16-bit register HL.
  ],
  mnemonic: "DEC (HL)",
  flags: [Z = #flag-update, N = 1, H = #flag-update],
  opcode: [#bin("00110101")/#hex("35")],
  operand_bytes: (),
  timing: (
    duration: 3,
    mem_rw: ([opcode], [R: data], [W: data],),
    addr: ([HL], [HL], [PC],),
    data: ([Z ← mem], [mem ← ALU], [IR ← mem],),
    idu_op: ("U", "U", [PC ← PC + 1],),
    alu_op: ("U", [mem ← Z - 1], "U",),
    misc_op: ("U", "U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x35:
  data = read_memory(addr=HL)
  result, carry_per_bit = data - 1
  write_memory(addr=HL, data=result)
  flags.Z = 1 if result == 0 else 0
  flags.N = 1
  flags.H = 1 if carry_per_bit[3] else 0
  ```,
  pseudocode: ```python
# M2
if IR == 0x35:
  Z = read_memory(addr=HL)
  # M3
  result, carry_per_bit = Z - 1
  write_memory(addr=HL, data=result)
  flags.Z = 1 if result == 0 else 0
  flags.N = 1
  flags.H = 1 if carry_per_bit[3] else 0
  # M4/M1
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== AND r: Bitwise AND (register) <op:AND_r>

    Performs a bitwise AND operation between the 8-bit A register and the 8-bit register `r`, and stores the result back into the A register.
  ],
  mnemonic: "AND r",
  flags: [Z = #flag-update, N = 0, H = 1, C = 0],
  opcode: [#bin("10100xxx")/various],
  operand_bytes: (),
  timing: (
    duration: 1,
    mem_rw: ([opcode],),
    addr: ([PC],),
    data: ([IR ← mem],),
    idu_op: ([PC ← PC + 1],),
    alu_op: ([A ← A and `r`],),
    misc_op: ("U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xA0: # example: AND B
  result = A & B
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 1
  flags.C = 0
  ```,
  pseudocode: ```python
# M2/M1
if IR == 0xA0: # example: AND B
  result = A & B
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 1
  flags.C = 0
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== AND (HL): Bitwise AND (indirect HL) <op:AND_hl>

    Performs a bitwise AND operation between the 8-bit A register and data from the absolute address specified by the 16-bit register HL, and stores the result back into the A register.
  ],
  mnemonic: "AND (HL)",
  flags: [Z = #flag-update, N = 0, H = 1, C = 0],
  opcode: [#bin("10100110")/#hex("A6")],
  operand_bytes: (),
  timing: (
    duration: 2,
    mem_rw: ([opcode], [R: data],),
    addr: ([HL], [PC],),
    data: ([Z ← mem], [IR ← mem],),
    idu_op: ("U", [PC ← PC + 1],),
    alu_op: ("U", [A ← A and Z],),
    misc_op: ("U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xA6:
  data = read_memory(addr=HL)
  result = A & data
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 1
  flags.C = 0
  ```,
  pseudocode: ```python
# M2
if IR == 0xA6:
  Z = read_memory(addr=HL)
  # M3/M1
  result = A & Z
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 1
  flags.C = 0
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== AND n: Bitwise AND (immediate) <op:AND_n>

    Performs a bitwise AND operation between the 8-bit A register and immediate data `n`, and stores the result back into the A register.
  ],
  mnemonic: "AND n",
  flags: [Z = #flag-update, N = 0, H = 1, C = 0],
  opcode: [#bin("11100110")/#hex("E6")],
  operand_bytes: ([`n`],),
  timing: (
    duration: 2,
    mem_rw: ([opcode], [R: `n`],),
    addr: ([PC], [PC],),
    data: ([Z ← mem], [IR ← mem],),
    idu_op: ([PC ← PC + 1], [PC ← PC + 1],),
    alu_op: ("U", [A ← A and Z],),
    misc_op: ("U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xE6:
  n = read_memory(addr=PC); PC = PC + 1
  result = A & n
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 1
  flags.C = 0
  ```,
  pseudocode: ```python
# M2
if IR == 0xE6:
  Z = read_memory(addr=PC); PC = PC + 1
  # M3/M1
  result = A & Z
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 1
  flags.C = 0
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== OR r: Bitwise OR (register) <op:OR_r>

    Performs a bitwise OR operation between the 8-bit A register and the 8-bit register `r`, and stores the result back into the A register.
  ],
  mnemonic: "OR r",
  flags: [Z = #flag-update, N = 0, H = 0, C = 0],
  opcode: [#bin("10110xxx")/various],
  operand_bytes: (),
  timing: (
    duration: 1,
    mem_rw: ([opcode],),
    addr: ([PC],),
    data: ([IR ← mem],),
    idu_op: ([PC ← PC + 1],),
    alu_op: ([A ← A or `r`],),
    misc_op: ("U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xB0: # example: OR B
  result = A | B
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 0
  flags.C = 0
  ```,
  pseudocode: ```python
# M2/M1
if IR == 0xB0: # example: OR B
  result = A | B
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 0
  flags.C = 0
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== OR (HL): Bitwise OR (indirect HL) <op:OR_hl>

    Performs a bitwise OR operation between the 8-bit A register and data from the absolute address specified by the 16-bit register HL, and stores the result back into the A register.
  ],
  mnemonic: "OR (HL)",
  flags: [Z = #flag-update, N = 0, H = 0, C = 0],
  opcode: [#bin("10110110")/#hex("B6")],
  operand_bytes: (),
  timing: (
    duration: 2,
    mem_rw: ([opcode], [R: data],),
    addr: ([HL], [PC],),
    data: ([Z ← mem], [IR ← mem],),
    idu_op: ("U", [PC ← PC + 1],),
    alu_op: ("U", [A ← A or Z],),
    misc_op: ("U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xB6:
  data = read_memory(addr=HL)
  result = A | data
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 0
  flags.C = 0
  ```,
  pseudocode: ```python
# M2
if IR == 0xB6:
  Z = read_memory(addr=HL)
  # M3/M1
  result = A | Z
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 0
  flags.C = 0
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== OR n: Bitwise OR (immediate) <op:OR_n>

    Performs a bitwise OR operation between the 8-bit A register and immediate data `n`, and stores the result back into the A register.
  ],
  mnemonic: "OR n",
  flags: [Z = #flag-update, N = 0, H = 0, C = 0],
  opcode: [#bin("11110110")/#hex("F6")],
  operand_bytes: ([`n`],),
  timing: (
    duration: 2,
    mem_rw: ([opcode], [R: `n`],),
    addr: ([PC], [PC],),
    data: ([Z ← mem], [IR ← mem],),
    idu_op: ([PC ← PC + 1], [PC ← PC + 1],),
    alu_op: ("U", [A ← A or Z],),
    misc_op: ("U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xF6:
  n = read_memory(addr=PC); PC = PC + 1
  result = A | n
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 0
  flags.C = 0
  ```,
  pseudocode: ```python
# M2
if IR == 0xF6:
  Z = read_memory(addr=PC); PC = PC + 1
  # M3/M1
  result = A | Z
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 0
  flags.C = 0
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== XOR r: Bitwise XOR (register) <op:XOR_r>

    Performs a bitwise XOR operation between the 8-bit A register and the 8-bit register `r`, and stores the result back into the A register.
  ],
  mnemonic: "XOR r",
  flags: [Z = #flag-update, N = 0, H = 0, C = 0],
  opcode: [#bin("10101xxx")/various],
  operand_bytes: (),
  timing: (
    duration: 1,
    mem_rw: ([opcode],),
    addr: ([PC],),
    data: ([IR ← mem],),
    idu_op: ([PC ← PC + 1],),
    alu_op: ([A ← A xor `r`],),
    misc_op: ("U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xA8: # example: XOR B
  result = A ^ B
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 0
  flags.C = 0
  ```,
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xA8: # example: XOR B
  # M2/M1
  result = A ^ B
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 0
  flags.C = 0
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== XOR (HL): Bitwise XOR (indirect HL) <op:XOR_hl>

    Performs a bitwise XOR operation between the 8-bit A register and data from the absolute address specified by the 16-bit register HL, and stores the result back into the A register.
  ],
  mnemonic: "XOR (HL)",
  flags: [Z = #flag-update, N = 0, H = 0, C = 0],
  opcode: [#bin("10101110")/#hex("AE")],
  operand_bytes: (),
  timing: (
    duration: 2,
    mem_rw: ([opcode], [R: data],),
    addr: ([HL], [PC],),
    data: ([Z ← mem], [IR ← mem],),
    idu_op: ("U", [PC ← PC + 1],),
    alu_op: ("U", [A ← A xor Z],),
    misc_op: ("U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xAE:
  data = read_memory(addr=HL)
  result = A ^ data
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 0
  flags.C = 0
  ```,
  pseudocode: ```python
# M2
if IR == 0xAE:
  Z = read_memory(addr=HL)
  # M3/M1
  result = A ^ Z
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 0
  flags.C = 0
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== XOR n: Bitwise XOR (immediate) <op:XOR_n>

    Performs a bitwise XOR operation between the 8-bit A register and immediate data `n`, and stores the result back into the A register.
  ],
  mnemonic: "XOR n",
  flags: [Z = #flag-update, N = 0, H = 0, C = 0],
  opcode: [#bin("11101110")/#hex("EE")],
  operand_bytes: ([`n`],),
  timing: (
    duration: 2,
    mem_rw: ([opcode], [R: `n`],),
    addr: ([PC], [PC],),
    data: ([Z ← mem], [IR ← mem],),
    idu_op: ([PC ← PC + 1], [PC ← PC + 1],),
    alu_op: ("U", [A ← A xor Z],),
    misc_op: ("U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xEE:
  n = read_memory(addr=PC); PC = PC + 1
  result = A ^ n
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 0
  flags.C = 0
  ```,
  pseudocode: ```python
# M2
if IR == 0xEE:
  Z = read_memory(addr=PC); PC = PC + 1
  # M3/M1
  result = A ^ Z
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 0
  flags.C = 0
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== CCF: Complement carry flag <op:CCF>

    Flips the carry flag, and clears the N and H flags.
  ],
  mnemonic: "CCF",
  flags: [N = 0, H = 0, C = #flag-update],
  opcode: [#bin("00111111")/#hex("3F")],
  operand_bytes: (),
  timing: (
    duration: 1,
    mem_rw: ([opcode],),
    addr: ([PC],),
    data: ([IR ← mem],),
    idu_op: ([PC ← PC + 1],),
    alu_op: ([cf ← not cf],),
    misc_op: ("U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x3F:
  flags.N = 0
  flags.H = 0
  flags.C = ~flags.C
  ```,
  pseudocode: ```python
# M2/M1
if IR == 0x3F:
  flags.N = 0
  flags.H = 0
  flags.C = ~flags.C
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== SCF: Set carry flag <op:SCF>

    Sets the carry flag, and clears the N and H flags.
  ],
  mnemonic: "SCF",
  flags: [N = 0, H = 0, C = 1],
  opcode: [#bin("00110111")/#hex("37")],
  operand_bytes: (),
  timing: (
    duration: 1,
    mem_rw: ([opcode],),
    addr: ([PC],),
    data: ([IR ← mem],),
    idu_op: ([PC ← PC + 1],),
    alu_op: ([cf ← 1],),
    misc_op: ("U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x37:
  flags.N = 0
  flags.H = 0
  flags.C = 1
  ```,
  pseudocode: ```python
# M2/M1
if IR == 0x37:
  flags.N = 0
  flags.H = 0
  flags.C = 1
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== DAA: Decimal adjust accumulator <op:DAA>

    TODO
  ],
  mnemonic: "DAA",
  flags: [Z = #flag-update, H = 0, C = #flag-update],
  opcode: [#bin("00100111")/#hex("27")],
  operand_bytes: (),
  timing: (
    duration: 1,
    mem_rw: ([opcode],),
    addr: ([PC],),
    data: ([IR ← mem],),
    idu_op: ([PC ← PC + 1],),
    alu_op: ([A ← A + adj],),
    misc_op: ("U",),
  ),
  pseudocode: ```python
TODO
  ```
)

#instruction(
  [
    ==== CPL: Complement accumulator <op:CPL>

    Flips all the bits in the 8-bit A register, and sets the N and H flags.
  ],
  mnemonic: "CPL",
  flags: [N = 1, H = 1],
  opcode: [#bin("00101111")/#hex("2F")],
  operand_bytes: (),
  timing: (
    duration: 1,
    mem_rw: ([opcode],),
    addr: ([PC],),
    data: ([IR ← mem],),
    idu_op: ([PC ← PC + 1],),
    alu_op: ([A ← not A],),
    misc_op: ("U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x2F:
  A = ~A
  flags.N = 1
  flags.H = 1
  ```,
  pseudocode: ```python
# M2/M1
if IR == 0x2F:
  A = ~A
  flags.N = 1
  flags.H = 1
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

=== 16-bit arithmetic instructions

#instruction(
  [
    ==== INC rr: Increment 16-bit register <op:INC_rr>

    Increments data in the 16-bit register `rr`.
  ],
  mnemonic: "INC rr",
  opcode: [#bin("00xx0011")/various],
  operand_bytes: (),
  timing: (
    duration: 2,
    mem_rw: ([opcode], "U",),
    addr: ([`rr`], [PC],),
    data: ("U", [IR ← mem],),
    idu_op: ([`rr` ← `rr` + 1], [PC ← PC + 1],),
    alu_op: ("U", "U",),
    misc_op: ("U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x03: # example: INC BC
  BC = BC + 1
  ```,
  pseudocode: ```python
# M2
if IR == 0x03: # example: INC BC
  BC = BC + 1
  # M3/M1
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== DEC rr: Decrement 16-bit register <op:DEC_rr>

    Decrements data in the 16-bit register `rr`.
  ],
  mnemonic: "DEC rr",
  opcode: [#bin("00xx1011")/various],
  operand_bytes: (),
  timing: (
    duration: 2,
    mem_rw: ([opcode], "U",),
    addr: ([`rr`], [PC],),
    data: ("U", [IR ← mem],),
    idu_op: ([`rr` ← `rr` - 1], [PC ← PC + 1],),
    alu_op: ("U", "U",),
    misc_op: ("U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x0B: # example: DEC BC
  BC = BC - 1
  ```,
  pseudocode: ```python
# M2
if IR == 0x0B: # example: DEC BC
  BC = BC - 1
  # M3/M1
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== ADD HL, rr: Add (16-bit register) <op:ADD_hl_rr>

    Adds to the 16-bit HL register pair, the 16-bit register `rr`, and stores the result back into the HL register pair.
  ],
  mnemonic: "ADD HL, rr",
  flags: [N = 0, H = #flag-update, C = #flag-update],
  opcode: [#bin("00xx1001")/various],
  operand_bytes: (),
  timing: (
    duration: 2,
    mem_rw: ([opcode], "U",),
    addr: ([#hex("0000")], [PC],),
    data: ("U", [IR ← mem],),
    idu_op: ("U", [PC ← PC + 1],),
    alu_op: ([L ← L + lsb `rr`], [H ← H +#sub[c] msb `rr`],),
    misc_op: ("U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x09: # example: ADD HL, BC
  result, carry_per_bit = HL + BC
  HL = result
  flags.N = 0
  flags.H = 1 if carry_per_bit[11] else 0
  flags.C = 1 if carry_per_bit[15] else 0
  ```,
  pseudocode: ```python
# M2
if IR == 0x09: # example: ADD HL, BC
  result, carry_per_bit = L + C
  L = result
  flags.N = 0
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  # M3/M1
  result, carry_per_bit = H + B + flags.C
  H = result
  flags.N = 0
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== ADD SP, e: Add to stack pointer (relative) <op:ADD_sp_e>

    Loads to the 16-bit SP register, 16-bit data calculated by adding the signed 8-bit operand `e` to the 16-bit value of the SP register.
  ],
  mnemonic: "ADD SP, e",
  flags: [Z = 0, N = 0, H = #flag-update, C = #flag-update],
  opcode: [#bin("11101000")/#hex("E8")],
  operand_bytes: ([`e`],),
  timing: (
    duration: 4,
    mem_rw: ([opcode], [R: `e`], "U", "U",),
    addr: ([PC], [#hex("0000")], [#hex("0000")], [PC],),
    data: ([Z ← mem], [ALU], [ALU], [IR ← mem],),
    idu_op: ([PC ← PC + 1], "U", "U", [PC ← PC + 1],),
    alu_op: ("U", [Z ← SPL + Z], [W ← SPH +#sub[c] adj], "U",),
    misc_op: ("U", "U", "U", [SP ← WZ],),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xE8:
  e = signed_8(read_memory(addr=PC)); PC = PC + 1
  result, carry_per_bit = SP + e
  SP = result
  flags.Z = 0
  flags.N = 0
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  ```,
  pseudocode: ```python
# M2
if IR == 0xE8:
  Z = read_memory(addr=PC); PC = PC + 1
  # M3
  result, carry_per_bit = lsb(SP) + Z
  Z = result
  flags.Z = 0
  flags.N = 0
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  # M4
  result = msb(SP) + adj + flags.C
  W = result
  # M5/M1
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1; SP = WZ
  ```
)

#pagebreak()

=== Rotate, shift, and bit operation instructions

#instruction(
  [
    ==== RLCA: Rotate left circular (accumulator) <op:RLCA>

    TODO
  ],
  mnemonic: "RLCA",
  flags: [Z = 0, N = 0, H = 0, C = #flag-update],
  opcode: [#bin("00000111")/#hex("07")],
  operand_bytes: (),
  timing: (
    duration: 1,
    mem_rw: ([opcode],),
    addr: ([PC],),
    data: ([IR ← mem],),
    idu_op: ([PC ← PC + 1],),
    alu_op: ([A ← rlc A],),
    misc_op: ("U",),
  ),
  pseudocode: ```python
TODO
  ```
)

#instruction(
  [
    ==== RRCA: Rotate right circular (accumulator) <op:RRCA>

    TODO
  ],
  mnemonic: "RRCA",
  flags: [Z = 0, N = 0, H = 0, C = #flag-update],
  opcode: [#bin("00001111")/#hex("0F")],
  operand_bytes: (),
  timing: (
    duration: 1,
    mem_rw: ([opcode],),
    addr: ([PC],),
    data: ([IR ← mem],),
    idu_op: ([PC ← PC + 1],),
    alu_op: ([A ← rrc A],),
    misc_op: ("U",),
  ),
  pseudocode: ```python
TODO
  ```
)

#instruction(
  [
    ==== RLA: Rotate left (accumulator) <op:RLA>

    TODO
  ],
  mnemonic: "RLA",
  flags: [Z = 0, N = 0, H = 0, C = #flag-update],
  opcode: [#bin("00010111")/#hex("17")],
  operand_bytes: (),
  timing: (
    duration: 1,
    mem_rw: ([opcode],),
    addr: ([PC],),
    data: ([IR ← mem],),
    idu_op: ([PC ← PC + 1],),
    alu_op: ([A ← rl A],),
    misc_op: ("U",),
  ),
  pseudocode: ```python
TODO
  ```
)

#instruction(
  [
    ==== RRA: Rotate right (accumulator) <op:RRA>

    TODO
  ],
  mnemonic: "RRA",
  flags: [Z = 0, N = 0, H = 0, C = #flag-update],
  opcode: [#bin("00011111")/#hex("1F")],
  operand_bytes: (),
  timing: (
    duration: 1,
    mem_rw: ([opcode],),
    addr: ([PC],),
    data: ([IR ← mem],),
    idu_op: ([PC ← PC + 1],),
    alu_op: ([A ← rr A],),
    misc_op: ("U",),
  ),
  pseudocode: ```python
TODO
  ```
)

#instruction(
  [
    ==== RLC r: Rotate left circular (register) <op:RLC_r>

    TODO
  ],
  mnemonic: "RLC r",
  flags: [Z = #flag-update, N = 0, H = 0, C = #flag-update],
  opcode: [#bin("00000xxx")/various],
  operand_bytes: (),
  cb: true,
  timing: (
    duration: 2,
    mem_rw: ([CB prefix], [opcode],),
    addr: ([PC], [PC],),
    data: ([IR ← mem], [IR ← mem],),
    idu_op: ([PC ← PC + 1], [PC ← PC + 1],),
    alu_op: ("U", [`r` ← rlc `r`],),
    misc_op: ("U", "U",),
  ),
  pseudocode: ```python
TODO
  ```
)

#instruction(
  [
    ==== RLC (HL): Rotate left circular (indirect HL) <op:RLC_hl>

    TODO
  ],
  mnemonic: "RLC (HL)",
  flags: [Z = #flag-update, N = 0, H = 0, C = #flag-update],
  opcode: [#hex("06")],
  operand_bytes: (),
  cb: true,
  timing: (
    duration: 4,
    mem_rw: ([CB prefix], [opcode], [R: data], [W: data]),
    addr: ([PC], [HL], [HL], [PC],),
    data: ([IR ← mem], [Z ← mem], [mem ← ALU], [IR ← mem],),
    idu_op: ([PC ← PC + 1], "U", "U", [PC ← PC + 1],),
    alu_op: ("U", "U", [mem ← rlc Z], "U",),
    misc_op: ("U", "U", "U", "U",),
  ),
  pseudocode: ```python
TODO
  ```
)

#instruction(
  [
    ==== RRC r: Rotate right circular (register) <op:RRC_r>

    TODO
  ],
  mnemonic: "RRC r",
  flags: [Z = #flag-update, N = 0, H = 0, C = #flag-update],
  opcode: [#bin("00001xxx")/various],
  operand_bytes: (),
  cb: true,
  timing: (
    duration: 2,
    mem_rw: ([CB prefix], [opcode],),
    addr: ([PC], [PC],),
    data: ([IR ← mem], [IR ← mem],),
    idu_op: ([PC ← PC + 1], [PC ← PC + 1],),
    alu_op: ("U", [`r` ← rrc `r`],),
    misc_op: ("U", "U",),
  ),
  pseudocode: ```python
TODO
  ```
)

#instruction(
  [
    ==== RRC (HL): Rotate right circular (indirect HL) <op:RRC_hl>

    TODO
  ],
  mnemonic: "RRC (HL)",
  flags: [Z = #flag-update, N = 0, H = 0, C = #flag-update],
  opcode: [#hex("0E")],
  operand_bytes: (),
  cb: true,
  timing: (
    duration: 4,
    mem_rw: ([CB prefix], [opcode], [R: data], [W: data]),
    addr: ([PC], [HL], [HL], [PC],),
    data: ([IR ← mem], [Z ← mem], [mem ← ALU], [IR ← mem],),
    idu_op: ([PC ← PC + 1], "U", "U", [PC ← PC + 1],),
    alu_op: ("U", "U", [mem ← rrc Z], "U",),
    misc_op: ("U", "U", "U", "U",),
  ),
  pseudocode: ```python
TODO
  ```
)

#instruction(
  [
    ==== RL r: Rotate left (register) <op:RL_r>

    TODO
  ],
  mnemonic: "RL r",
  flags: [Z = #flag-update, N = 0, H = 0, C = #flag-update],
  opcode: [#bin("00010xxx")/various],
  operand_bytes: (),
  cb: true,
  timing: (
    duration: 2,
    mem_rw: ([CB prefix], [opcode],),
    addr: ([PC], [PC],),
    data: ([IR ← mem], [IR ← mem],),
    idu_op: ([PC ← PC + 1], [PC ← PC + 1],),
    alu_op: ("U", [`r` ← rl `r`],),
    misc_op: ("U", "U",),
  ),
  pseudocode: ```python
TODO
  ```
)

#instruction(
  [
    ==== RL (HL): Rotate left (indirect HL) <op:RL_hl>

    TODO
  ],
  mnemonic: "RL (HL)",
  flags: [Z = #flag-update, N = 0, H = 0, C = #flag-update],
  opcode: [#hex("16")],
  operand_bytes: (),
  cb: true,
  timing: (
    duration: 4,
    mem_rw: ([CB prefix], [opcode], [R: data], [W: data]),
    addr: ([PC], [HL], [HL], [PC],),
    data: ([IR ← mem], [Z ← mem], [mem ← ALU], [IR ← mem],),
    idu_op: ([PC ← PC + 1], "U", "U", [PC ← PC + 1],),
    alu_op: ("U", "U", [mem ← rl Z], "U",),
    misc_op: ("U", "U", "U", "U",),
  ),
  pseudocode: ```python
TODO
  ```
)

#instruction(
  [
    ==== RR r: Rotate right (register) <op:RR_r>

    TODO
  ],
  mnemonic: "RR r",
  flags: [Z = #flag-update, N = 0, H = 0, C = #flag-update],
  opcode: [#bin("00011xxx")/various],
  operand_bytes: (),
  cb: true,
  timing: (
    duration: 2,
    mem_rw: ([CB prefix], [opcode],),
    addr: ([PC], [PC],),
    data: ([IR ← mem], [IR ← mem],),
    idu_op: ([PC ← PC + 1], [PC ← PC + 1],),
    alu_op: ("U", [`r` ← rr `r`],),
    misc_op: ("U", "U",),
  ),
  pseudocode: ```python
TODO
  ```
)

#instruction(
  [
    ==== RR (HL): Rotate right (indirect HL) <op:RR_hl>

    TODO
  ],
  mnemonic: "RR (HL)",
  flags: [Z = #flag-update, N = 0, H = 0, C = #flag-update],
  opcode: [#hex("1E")],
  operand_bytes: (),
  cb: true,
  timing: (
    duration: 4,
    mem_rw: ([CB prefix], [opcode], [R: data], [W: data]),
    addr: ([PC], [HL], [HL], [PC],),
    data: ([IR ← mem], [Z ← mem], [mem ← ALU], [IR ← mem],),
    idu_op: ([PC ← PC + 1], "U", "U", [PC ← PC + 1],),
    alu_op: ("U", "U", [mem ← rr Z], "U",),
    misc_op: ("U", "U", "U", "U",),
  ),
  pseudocode: ```python
TODO
  ```
)

#instruction(
  [
    ==== SLA r: Shift left arithmetic (register) <op:SLA_r>

    TODO
  ],
  mnemonic: "SLA r",
  flags: [Z = #flag-update, N = 0, H = 0, C = #flag-update],
  opcode: [#bin("00100xxx")/various],
  operand_bytes: (),
  cb: true,
  timing: (
    duration: 2,
    mem_rw: ([CB prefix], [opcode],),
    addr: ([PC], [PC],),
    data: ([IR ← mem], [IR ← mem],),
    idu_op: ([PC ← PC + 1], [PC ← PC + 1],),
    alu_op: ("U", [`r` ← sla `r`],),
    misc_op: ("U", "U",),
  ),
  pseudocode: ```python
TODO
  ```
)

#instruction(
  [
    ==== SLA (HL): Shift left arithmetic (indirect HL) <op:SLA_hl>

    TODO
  ],
  mnemonic: "SLA (HL)",
  flags: [Z = #flag-update, N = 0, H = 0, C = #flag-update],
  opcode: [#hex("26")],
  operand_bytes: (),
  cb: true,
  timing: (
    duration: 4,
    mem_rw: ([CB prefix], [opcode], [R: data], [W: data]),
    addr: ([PC], [HL], [HL], [PC],),
    data: ([IR ← mem], [Z ← mem], [mem ← ALU], [IR ← mem],),
    idu_op: ([PC ← PC + 1], "U", "U", [PC ← PC + 1],),
    alu_op: ("U", "U", [mem ← sla Z], "U",),
    misc_op: ("U", "U", "U", "U",),
  ),
  pseudocode: ```python
TODO
  ```
)

#instruction(
  [
    ==== SRA r: Shift right arithmetic (register) <op:SRA_r>

    TODO
  ],
  mnemonic: "SRA r",
  flags: [Z = #flag-update, N = 0, H = 0, C = #flag-update],
  opcode: [#bin("00101xxx")/various],
  operand_bytes: (),
  cb: true,
  timing: (
    duration: 2,
    mem_rw: ([CB prefix], [opcode],),
    addr: ([PC], [PC],),
    data: ([IR ← mem], [IR ← mem],),
    idu_op: ([PC ← PC + 1], [PC ← PC + 1],),
    alu_op: ("U", [`r` ← sra `r`],),
    misc_op: ("U", "U",),
  ),
  pseudocode: ```python
TODO
  ```
)

#instruction(
  [
    ==== SRA (HL): Shift right arithmetic (indirect HL) <op:SRA_hl>

    TODO
  ],
  mnemonic: "SRA (HL)",
  flags: [Z = #flag-update, N = 0, H = 0, C = #flag-update],
  opcode: [#hex("2E")],
  operand_bytes: (),
  cb: true,
  timing: (
    duration: 4,
    mem_rw: ([CB prefix], [opcode], [R: data], [W: data]),
    addr: ([PC], [HL], [HL], [PC],),
    data: ([IR ← mem], [Z ← mem], [mem ← ALU], [IR ← mem],),
    idu_op: ([PC ← PC + 1], "U", "U", [PC ← PC + 1],),
    alu_op: ("U", "U", [mem ← sra Z], "U",),
    misc_op: ("U", "U", "U", "U",),
  ),
  pseudocode: ```python
TODO
  ```
)

#instruction(
  [
    ==== SWAP r: Swap nibbles (register) <op:SWAP_r>

    TODO
  ],
  mnemonic: "SWAP r",
  flags: [Z = #flag-update, N = 0, H = 0, C = 0],
  opcode: [#bin("00110xxx")/various],
  operand_bytes: (),
  cb: true,
  timing: (
    duration: 2,
    mem_rw: ([CB prefix], [opcode],),
    addr: ([PC], [PC],),
    data: ([IR ← mem], [IR ← mem],),
    idu_op: ([PC ← PC + 1], [PC ← PC + 1],),
    alu_op: ("U", [`r` ← swap `r`],),
    misc_op: ("U", "U",),
  ),
  pseudocode: ```python
TODO
  ```
)

#instruction(
  [
    ==== SWAP (HL): Swap nibbles (indirect HL) <op:SWAP_hl>

    TODO
  ],
  mnemonic: "SWAP (HL)",
  flags: [Z = #flag-update, N = 0, H = 0, C = 0],
  opcode: [#hex("36")],
  operand_bytes: (),
  cb: true,
  timing: (
    duration: 4,
    mem_rw: ([CB prefix], [opcode], [R: data], [W: data]),
    addr: ([PC], [HL], [HL], [PC],),
    data: ([IR ← mem], [Z ← mem], [mem ← ALU], [IR ← mem],),
    idu_op: ([PC ← PC + 1], "U", "U", [PC ← PC + 1],),
    alu_op: ("U", "U", [mem ← swap Z], "U",),
    misc_op: ("U", "U", "U", "U",),
  ),
  pseudocode: ```python
TODO
  ```
)

#instruction(
  [
    ==== SRL r: Shift right logical (register) <op:SRL_r>

    TODO
  ],
  mnemonic: "SRL r",
  flags: [Z = #flag-update, N = 0, H = 0, C = #flag-update],
  opcode: [#bin("00101xxx")/various],
  operand_bytes: (),
  cb: true,
  timing: (
    duration: 2,
    mem_rw: ([CB prefix], [opcode],),
    addr: ([PC], [PC],),
    data: ([IR ← mem], [IR ← mem],),
    idu_op: ([PC ← PC + 1], [PC ← PC + 1],),
    alu_op: ("U", [`r` ← srl `r`],),
    misc_op: ("U", "U",),
  ),
  pseudocode: ```python
TODO
  ```
)

#instruction(
  [
    ==== SRL (HL): Shift right logical (indirect HL) <op:SRL_hl>

    TODO
  ],
  mnemonic: "SRL (HL)",
  flags: [Z = #flag-update, N = 0, H = 0, C = #flag-update],
  opcode: [#hex("3E")],
  operand_bytes: (),
  cb: true,
  timing: (
    duration: 4,
    mem_rw: ([CB prefix], [opcode], [R: data], [W: data]),
    addr: ([PC], [HL], [HL], [PC],),
    data: ([IR ← mem], [Z ← mem], [mem ← ALU], [IR ← mem],),
    idu_op: ([PC ← PC + 1], "U", "U", [PC ← PC + 1],),
    alu_op: ("U", "U", [mem ← srl Z], "U",),
    misc_op: ("U", "U", "U", "U",),
  ),
  pseudocode: ```python
TODO
  ```
)

#instruction(
  [
    ==== BIT b, r: Test bit (register) <op:BIT_b_r>

    TODO
  ],
  mnemonic: "BIT b, r",
  flags: [Z = #flag-update, N = 0, H = 1],
  opcode: [#bin("01xxxxxx")/various],
  operand_bytes: (),
  cb: true,
  timing: (
    duration: 2,
    mem_rw: ([CB prefix], [opcode],),
    addr: ([PC], [PC],),
    data: ([IR ← mem], [IR ← mem],),
    idu_op: ([PC ← PC + 1], [PC ← PC + 1],),
    alu_op: ("U", [bit `b`, `r`],),
    misc_op: ("U", "U",),
  ),
  pseudocode: ```python
TODO
  ```
)

#instruction(
  [
    ==== BIT b, (HL): Test bit (indirect HL) <op:BIT_b_hl>

    TODO
  ],
  mnemonic: "BIT b, (HL)",
  flags: [Z = #flag-update, N = 0, H = 1],
  opcode: [#bin("01xxx110")/various],
  operand_bytes: (),
  cb: true,
  timing: (
    duration: 3,
    mem_rw: ([CB prefix], [opcode], [R: data]),
    addr: ([PC], [HL], [PC],),
    data: ([IR ← mem], [Z ← mem], [IR ← mem],),
    idu_op: ([PC ← PC + 1], "U", [PC ← PC + 1],),
    alu_op: ("U", "U", [bit `b`, Z],),
    misc_op: ("U", "U", "U",),
  ),
  pseudocode: ```python
TODO
  ```
)

#instruction(
  [
    ==== RES b, r: Reset bit (register) <op:RES_b_r>

    TODO
  ],
  mnemonic: "RES b, r",
  opcode: [#bin("10xxxxxx")/various],
  operand_bytes: (),
  cb: true,
  timing: (
    duration: 2,
    mem_rw: ([CB prefix], [opcode],),
    addr: ([PC], [PC],),
    data: ([IR ← mem], [IR ← mem],),
    idu_op: ([PC ← PC + 1], [PC ← PC + 1],),
    alu_op: ("U", [`r` ← res `b`, `r`],),
    misc_op: ("U", "U",),
  ),
  pseudocode: ```python
TODO
  ```
)

#instruction(
  [
    ==== RES b, (HL): Reset bit (indirect HL) <op:RES_b_hl>

    TODO
  ],
  mnemonic: "RES b, (HL)",
  opcode: [#bin("10xxx110")/various],
  operand_bytes: (),
  cb: true,
  timing: (
    duration: 4,
    mem_rw: ([CB prefix], [opcode], [R: data], [W: data]),
    addr: ([PC], [HL], [HL], [PC],),
    data: ([IR ← mem], [Z ← mem], [mem ← ALU], [IR ← mem],),
    idu_op: ([PC ← PC + 1], "U", "U", [PC ← PC + 1],),
    alu_op: ("U", "U", [mem ← res `b`, Z], "U",),
    misc_op: ("U", "U", "U", "U",),
  ),
  pseudocode: ```python
TODO
  ```
)

#instruction(
  [
    ==== SET b, r: Set bit (register) <op:SET_b_r>

    TODO
  ],
  mnemonic: "SET b, r",
  opcode: [#bin("11xxxxxx")/various],
  operand_bytes: (),
  cb: true,
  timing: (
    duration: 2,
    mem_rw: ([CB prefix], [opcode],),
    addr: ([PC], [PC],),
    data: ([IR ← mem], [IR ← mem],),
    idu_op: ([PC ← PC + 1], [PC ← PC + 1],),
    alu_op: ("U", [`r` ← set `b`, `r`],),
    misc_op: ("U", "U",),
  ),
  pseudocode: ```python
TODO
  ```
)

#instruction(
  [
    ==== SET b, (HL): Set bit (indirect HL) <op:SET_b_hl>

    TODO
  ],
  mnemonic: "SET b, (HL)",
  opcode: [#bin("11xxx110")/various],
  operand_bytes: (),
  cb: true,
  timing: (
    duration: 4,
    mem_rw: ([CB prefix], [opcode], [R: data], [W: data]),
    addr: ([PC], [HL], [HL], [PC],),
    data: ([IR ← mem], [Z ← mem], [mem ← ALU], [IR ← mem],),
    idu_op: ([PC ← PC + 1], "U", "U", [PC ← PC + 1],),
    alu_op: ("U", "U", [mem ← set `b`, Z], "U",),
    misc_op: ("U", "U", "U", "U",),
  ),
  pseudocode: ```python
TODO
  ```
)

#pagebreak()

=== Control flow instructions

#instruction(
  [
    ==== JP nn: Jump <op:JP>

    Unconditional jump to the absolute address specified by the 16-bit immediate operand `nn`.
  ],
  mnemonic: "JP nn",
  opcode: [#bin("11000011")/#hex("C3")],
  operand_bytes: ([LSB(`nn`)], [MSB(`nn`)]),
  timing: (
    duration: 4,
    mem_rw: ([opcode], [R: lsb(`nn`)], [R: msb(`nn`)], "U",),
    addr: ([PC], [PC], [#hex("0000")], [PC],),
    data: ([Z ← mem], [W ← mem], "U", [IR ← mem],),
    idu_op: ([PC ← PC + 1], [PC ← PC + 1], "U", [PC ← PC + 1],),
    alu_op: ("U", "U", "U", "U",),
    misc_op: ("U", "U", [PC ← WZ], "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xC3:
  nn_lsb = read_memory(addr=PC); PC = PC + 1
  nn_msb = read_memory(addr=PC); PC = PC + 1
  nn = unsigned_16(lsb=nn_lsb, msb=nn_msb)
  PC = nn
  ```,
  pseudocode: ```python
# M2
if IR == 0xC3:
  Z = read_memory(addr=PC); PC = PC + 1
  # M3
  W = read_memory(addr=PC); PC = PC + 1
  # M4
  PC = WZ
  # M5/M1
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== JP HL: Jump to HL <op:JP_hl>

    Unconditional jump to the absolute address specified by the 16-bit register HL.
  ],
  mnemonic: "JP HL",
  opcode: [#bin("11101001")/#hex("E9")],
  operand_bytes: (),
  timing: (
    duration: 1,
    mem_rw: ([opcode],),
    addr: ([HL],),
    data: ([IR ← mem],),
    idu_op: ([PC ← HL + 1],),
    alu_op: ("U",),
    misc_op: ("U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xE9:
  PC = HL
  ```,
  pseudocode: ```python
# M2/M1
if IR == 0xE9:
  IR, intr = fetch_cycle(addr=HL); PC = HL + 1
  ```
)

#warning[
  In some documentation this instruction is written as `JP [HL]`. This is very misleading, since brackets are usually used to indicate a memory read, and this instruction simply copies the value of HL to PC.
]

#instruction(
  [
    ==== JP cc, nn: Jump (conditional) <op:JP_cc>

    Conditional jump to the absolute address specified by the 16-bit operand `nn`, depending on the condition `cc`.

    Note that the operand (absolute address) is read even when the condition is false!
  ],
  mnemonic: "JP cc, nn",
  opcode: [#bin("110xx010")/various],
  operand_bytes: ([LSB(`nn`)], [MSB(`nn`)]),
  timing: (
    cc_true: (
      duration: 4,
      mem_rw: ([opcode], [R: lsb(`nn`)], [R: msb(`nn`)], "U",),
      addr: ([PC], [PC], [#hex("0000")], [PC],),
      data: ([Z ← mem], [W ← mem], "U", [IR ← mem],),
      idu_op: ([PC ← PC + 1], [PC ← PC + 1], "U", [PC ← PC + 1],),
      alu_op: ("U", "U", "U", "U",),
      misc_op: ("U", [cc check], [PC ← WZ], "U",),
    ),
    cc_false: (
      duration: 3,
      mem_rw: ([opcode], [R: lsb(`nn`)], [R: msb(`nn`)],),
      addr: ([PC], [PC], [PC],),
      data: ([Z ← mem], [W ← mem], [IR ← mem],),
      idu_op: ([PC ← PC + 1], [PC ← PC + 1], [PC ← PC + 1],),
      alu_op: ("U", "U", "U",),
      misc_op: ("U", [cc check], "U",),
    )
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xC2: # example: JP NZ, nn
  nn_lsb = read_memory(addr=PC); PC = PC + 1
  nn_msb = read_memory(addr=PC); PC = PC + 1
  nn = unsigned_16(lsb=nn_lsb, msb=nn_msb)
  if !flags.Z: # cc=true
    PC = nn
  ```,
  pseudocode: ```python
# M2
if IR == 0xC2: # example: JP NZ, nn
  Z = read_memory(addr=PC); PC = PC + 1
  # M3
  W = read_memory(addr=PC); PC = PC + 1
  if !flags.Z: # cc=true
    # M4
    PC = WZ
    # M5/M1
    IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  else: # cc=false
    # M4/M1
    IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== JR e: Relative jump <op:JR>

    Unconditional jump to the relative address specified by the signed 8-bit operand `e`.
  ],
  mnemonic: "JR e",
  opcode: [#bin("00011000")/#hex("18")],
  operand_bytes: ([`e`],),
  timing: (
    duration: 3,
    mem_rw: ([opcode], [R: `e`], "U",),
    addr: ([PC], [PCH], [WZ],),
    data: ([Z ← mem], [ALU], [IR ← mem],),
    idu_op: ([PC ← PC + 1], [W ← adj PCH], [PC ← WZ + 1],),
    alu_op: ("U", [Z ← PCL + Z], "U",),
    misc_op: ("U", "U", "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x18:
  e = signed_8(read_memory(addr=PC)); PC = PC + 1
  PC = PC + e
  ```,
  pseudocode: ```python
# M2
if IR == 0x18:
  Z = read_memory(addr=PC); PC = PC + 1
  # M3
  Z_sign = bit(7, Z)
  result, carry_per_bit = Z + lsb(PC)
  Z = result
  adj = 1 if carry_per_bit[7] and not Z_sign else
       -1 if not carry_per_bit[7] and Z_sign else
        0
  W = msb(PC) + adj
  # M4/M1
  IR, intr = fetch_cycle(addr=WZ); PC = WZ + 1
  ```
)

#instruction(
  [
    ==== JR cc, e: Relative jump (conditional) <op:JR_cc>

    Conditional jump to the relative address specified by the signed 8-bit operand `e`, depending on the condition `cc`.

    Note that the operand (relative address offset) is read even when the condition is false!
  ],
  mnemonic: "JR cc, e",
  opcode: [#bin("001xx000")/various],
  operand_bytes: ([`e`],),
  timing: (
    cc_true: (
      duration: 3,
      mem_rw: ([opcode], [R: `e`], "U",),
      addr: ([PC], [PCH], [WZ],),
      data: ([Z ← mem], [ALU], [IR ← mem],),
      idu_op: ([PC ← PC + 1], [W ← adj PCH], [PC ← WZ + 1],),
      alu_op: ("U", [Z ← PCL + Z], "U",),
      misc_op: ([cc check], "U", "U",),
    ),
    cc_false: (
      duration: 2,
      mem_rw: ([opcode], [R: `e`],),
      addr: ([PC], [PC],),
      data: ([Z ← mem], [IR ← mem],),
      idu_op: ([PC ← PC + 1], [PC ← PC + 1],),
      alu_op: ("U", "U",),
      misc_op: ([cc check], "U",),
    )
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x20:
  e = signed_8(read_memory(addr=PC)); PC = PC + 1
  if !flags.Z: # cc=true
    PC = PC + e
  ```,
  pseudocode: ```python
# M2
if IR == 0x20:
  Z = read_memory(addr=PC); PC = PC + 1
  if !flags.Z: # cc=true
    # M3
    Z_sign = bit(7, Z)
    result, carry_per_bit = Z + lsb(PC)
    Z = result
    adj = 1 if carry_per_bit[7] and not Z_sign else
         -1 if not carry_per_bit[7] and Z_sign else
          0
    W = msb(PC) + adj
    # M4/M1
    IR, intr = fetch_cycle(addr=WZ); PC = WZ + 1
  else: # cc=false
    # M3/M1
    IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== CALL nn: Call function <op:CALL>

    Unconditional function call to the absolute address specified by the 16-bit operand `nn`.
  ],
  mnemonic: "CALL nn",
  opcode: [#bin("11001101")/#hex("CD")],
  operand_bytes: ([LSB(`nn`)], [MSB(`nn`)]),
  timing: (
    duration: 6,
    mem_rw: ([opcode], [R: lsb(`nn`)], [R: msb(`nn`)], "U", [W: msb(PC#sub[0]+3)], [W: lsb(PC#sub[0]+3)],),
    addr: ([PC], [PC], [SP], [SP], [SP], [PC],),
    data: ([Z ← mem], [W ← mem], "U", [mem ← PCH], [mem ← PCL], [IR ← mem],),
    idu_op: ([PC ← PC + 1], [PC ← PC + 1], [SP ← SP - 1], [SP ← SP - 1], [SP ← SP], [PC ← PC + 1],),
    alu_op: ("U", "U", "U", "U", "U", "U",),
    misc_op: ("U", "U", "U", "U", [PC ← WZ], "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xCD:
  nn_lsb = read_memory(addr=PC); PC = PC + 1
  nn_msb = read_memory(addr=PC); PC = PC + 1
  nn = unsigned_16(lsb=nn_lsb, msb=nn_msb)
  SP = SP - 1
  write_memory(addr=SP, data=msb(PC)); SP = SP - 1
  write_memory(addr=SP, data=lsb(PC))
  PC = nn
  ```,
  pseudocode: ```python
# M2
if IR == 0xCD:
  Z = read_memory(addr=PC); PC = PC + 1
  # M3
  W = read_memory(addr=PC); PC = PC + 1
  # M4
  SP = SP - 1
  # M5
  write_memory(addr=SP, data=msb(PC)); SP = SP - 1
  # M6
  write_memory(addr=SP, data=lsb(PC)); PC = WZ
  # M7/M1
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== CALL cc, nn: Call function (conditional) <op:CALL_cc>

    Conditional function call to the absolute address specified by the 16-bit operand `nn`, depending on the condition `cc`.

    Note that the operand (absolute address) is read even when the condition is false!
  ],
  mnemonic: "CALL cc, nn",
  opcode: [#bin("110xx100")/various],
  operand_bytes: ([LSB(`nn`)], [MSB(`nn`)]),
  timing: (
    cc_true: (
      duration: 6,
      mem_rw: ([opcode], [R: lsb(`nn`)], [R: msb(`nn`)], "U", [W: msb(PC#sub[0]+3)], [W: lsb(PC#sub[0]+3)],),
      addr: ([PC], [PC], [SP], [SP], [SP], [PC],),
      data: ([Z ← mem], [W ← mem], "U", [mem ← PCH], [mem ← PCL], [IR ← mem],),
      idu_op: ([PC ← PC + 1], [PC ← PC + 1], [SP ← SP - 1], [SP ← SP - 1], [SP ← SP], [PC ← PC + 1],),
      alu_op: ("U", "U", "U", "U", "U", "U",),
      misc_op: ("U", [cc check], "U", "U", [PC ← WZ], "U",),
    ),
    cc_false: (
      duration: 3,
      mem_rw: ([opcode], [R: lsb(`nn`)], [R: msb(`nn`)]),
      addr: ([PC], [PC], [PC],),
      data: ([Z ← mem], [W ← mem], [IR ← mem],),
      idu_op: ([PC ← PC + 1], [PC ← PC + 1], [PC ← PC + 1],),
      alu_op: ("U", "U", "U",),
      misc_op: ("U", [cc check], "U",),
    )
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xC4: # example: CALL NZ, nn
  nn_lsb = read_memory(addr=PC); PC = PC + 1
  nn_msb = read_memory(addr=PC); PC = PC + 1
  nn = unsigned_16(lsb=nn_lsb, msb=nn_msb)
  if !flags.Z: # cc=true
    SP = SP - 1
    write_memory(addr=SP, data=msb(PC)); SP = SP - 1
    write_memory(addr=SP, data=lsb(PC))
    PC = nn
  ```,
  pseudocode: ```python
# M2
if IR == 0xC4: # example: CALL NZ, nn
  Z = read_memory(addr=PC); PC = PC + 1
  # M3
  W = read_memory(addr=PC); PC = PC + 1
  if !flags.Z: # cc=true
    # M4
    SP = SP - 1
    # M5
    write_memory(addr=SP, data=msb(PC)); SP = SP - 1
    # M6
    write_memory(addr=SP, data=lsb(PC)); PC = WZ
    # M7/M1
    IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  else: # cc=false
    # M4/M1
    IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== RET: Return from function <op:RET>

    Unconditional return from a function.
  ],
  mnemonic: "RET",
  opcode: [#bin("11001001")/#hex("C9")],
  operand_bytes: (),
  timing: (
    duration: 4,
    mem_rw: ([opcode], [R: lsb(PC)], [R: msb(PC)], "U",),
    addr: ([SP], [SP], [#hex("0000")], [PC],),
    data: ([Z ← mem], [W ← mem], "U", [IR ← mem],),
    idu_op: ([SP ← SP + 1], [SP ← SP + 1], "U", [PC ← PC + 1],),
    alu_op: ("U", "U", "U", "U",),
    misc_op: ("U", "U", [PC ← WZ], "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xC9:
  lsb = read_memory(addr=SP); SP = SP + 1
  msb = read_memory(addr=SP); SP = SP + 1
  PC = unsigned_16(lsb=lsb, msb=msb)
  ```,
  pseudocode: ```python
# M2
if IR == 0xC9:
  Z = read_memory(addr=SP); SP = SP + 1
  # M3
  W = read_memory(addr=SP); SP = SP + 1
  # M4
  PC = WZ
  # M5/M1
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== RET cc: Return from function (conditional) <op:RET_cc>

    Conditional return from a function, depending on the condition `cc`.
  ],
  mnemonic: "RET cc",
  opcode: [#bin("110xx000")/various],
  operand_bytes: (),
  timing: (
    cc_true: (
      duration: 5,
      mem_rw: ([opcode], "U", [R: lsb(PC)], [R: msb(PC)], "U",),
      addr: ([#hex("0000")], [SP], [SP], [#hex("0000")], [PC],),
      data: ("U", [Z ← mem], [W ← mem], "U", [IR ← mem],),
      idu_op: ("U", [SP ← SP + 1], [SP ← SP + 1], "U", [PC ← PC + 1],),
      alu_op: ("U", "U", "U", "U", "U",),
      misc_op: ([cc check], "U", "U", [PC ← WZ], "U",),
    ),
    cc_false: (
      duration: 2,
      mem_rw: ([opcode], "U",),
      addr: ([#hex("0000")], [PC],),
      data: ("U", [IR ← mem],),
      idu_op: ("U", [PC ← PC + 1],),
      alu_op: ("U", "U",),
      misc_op: ([cc check], "U",),
    )
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xC0: # example: RET NZ
  if !flags.Z: # cc=true
    lsb = read_memory(addr=SP); SP = SP + 1
    msb = read_memory(addr=SP); SP = SP + 1
    PC = unsigned_16(lsb=lsb, msb=msb)
  ```,
  pseudocode: ```python
# M2
if IR == 0xC0: # example: RET NZ
  if !flags.Z: # cc=true
    # M3
    Z = read_memory(addr=SP); SP = SP + 1
    # M4
    W = read_memory(addr=SP); SP = SP + 1
    # M5
    PC = WZ
    # M6/M1
    IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  else: # cc=false
    # M3
    IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== RETI: Return from interrupt handler <op:RETI>

    Unconditional return from a function. Also enables interrupts by setting IME=1.
  ],
  mnemonic: "RETI",
  opcode: [#bin("11011001")/#hex("D9")],
  operand_bytes: (),
  timing: (
    duration: 4,
    mem_rw: ([opcode], [R: lsb(PC)], [R: msb(PC)], "U",),
    addr: ([SP], [SP], [#hex("0000")], [PC],),
    data: ([Z ← mem], [W ← mem], "U", [IR ← mem],),
    idu_op: ([SP ← SP + 1], [SP ← SP + 1], "U", [PC ← PC + 1],),
    alu_op: ("U", "U", "U", "U",),
    misc_op: ("U", "U", [PC ← WZ, IME ← 1], "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xD9:
  lsb = read_memory(addr=SP); SP = SP + 1
  msb = read_memory(addr=SP); SP = SP + 1
  PC = unsigned_16(lsb=lsb, msb=msb)
  IME = 1
  ```,
  pseudocode: ```python
# M2
if IR == 0xD9:
  Z = read_memory(addr=SP); SP = SP + 1
  # M3
  W = read_memory(addr=SP); SP = SP + 1
  # M4
  PC = WZ; IME = 1
  # M5/M1
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== RST n: Restart / Call function (implied) <op:RST>

    Unconditional function call to the absolute fixed address defined by the opcode.
  ],
  mnemonic: "RST n",
  opcode: [#bin("11xxx111")/various],
  operand_bytes: (),
  timing: (
    duration: 4,
    mem_rw: ([opcode], "U", [W: msb PC], [W: lsb PC],),
    addr: ([SP], [SP], [SP], [PC],),
    data: ("U", [mem ← PCH], [mem ← PCL], [IR ← mem],),
    idu_op: ([SP ← SP - 1], [SP ← SP - 1], [SP ← SP], [PC ← PC + 1],),
    alu_op: ("U", "U", "U", "U",),
    misc_op: ("U", "U", [PC ← addr], "U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xDF: # example: RST 0x18
  n = 0x18
  SP = SP - 1
  write_memory(addr=SP, data=msb(PC)); SP = SP - 1
  write_memory(addr=SP, data=lsb(PC))
  PC = unsigned_16(lsb=n, msb=0x00)
  ```,
  pseudocode: ```python
# M2
if IR == 0xDF: # example: RST 0x18
  SP = SP - 1
  # M3
  write_memory(addr=SP, data=msb(PC)); SP = SP - 1
  # M4
  write_memory(addr=SP, data=lsb(PC)); PC = 0x0018
  # M5/M1
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)

=== Miscellaneous instructions

==== HALT: Halt system clock <op:HALT>

TODO

==== STOP: Stop system and main clocks <op:STOP>

TODO

#instruction(
  [
    ==== DI: Disable interrupts <op:DI>

    Disables interrupt handling by setting IME=0 and cancelling any scheduled effects of the EI instruction if any.
  ],
  mnemonic: "DI",
  opcode: [#bin("11110011")/#hex("F3")],
  operand_bytes: (),
  timing: (
    duration: 1,
    mem_rw: ([opcode],),
    addr: ([PC],),
    data: ([IR ← mem],),
    idu_op: ([PC ← PC + 1],),
    alu_op: ("U",),
    misc_op: ("IME ← 0",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xF3:
  IME = 0
  ```,
  pseudocode: ```python
# M2/M1
if IR == 0xF3:
  # interrupt checking is suppressed so fetch_cycle(..) is not used
  IR = read_memory(addr=PC); PC = PC + 1; IME = 0
  ```
)

#instruction(
  [
    ==== EI: Enable interrupts <op:EI>

    Schedules interrupt handling to be enabled after the next machine cycle.
  ],
  mnemonic: "EI",
  opcode: [#bin("11111011")/#hex("FB")],
  operand_bytes: (),
  timing: (
    duration: 1,
    mem_rw: ([opcode],),
    addr: ([PC],),
    data: ([IR ← mem],),
    idu_op: ([PC ← PC + 1],),
    alu_op: ("U",),
    misc_op: ("IME ← 1",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xFB:
  IME_next = 1
  ```,
  pseudocode: ```python
# M2/M1
if IR == 0xFB:
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1; IME = 1
  ```
)

#instruction(
  [
    ==== NOP: No operation <op:NOP>

    No operation. This instruction doesn't do anything, but can be used to add a delay of one machine cycle and increment PC by one.
  ],
  mnemonic: "NOP",
  opcode: [#bin("00000000")/#hex("00")],
  operand_bytes: (),
  timing: (
    duration: 1,
    mem_rw: ([opcode],),
    addr: ([PC],),
    data: ([IR ← mem],),
    idu_op: ([PC ← PC + 1],),
    alu_op: ("U",),
    misc_op: ("U",),
  ),
  simple-pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x00:
  # nothing
  ```,
  pseudocode: ```python
# M2/M1
if IR == 0x00:
  IR, intr = fetch_cycle(addr=PC); PC = PC + 1
  ```
)
