#import "../../common.typ": *
#import "../../timing.typ"

#let ops = toml("../../opcodes.toml")

#let instruction-block(body, ..grid-args) = block(breakable: false)[
  #body
  #grid(
    columns: (6em, auto),
    gutter: 8pt,
    ..grid-args
  )
]

#let instruction-timing(mnemonic: str, duration: int, mem_rw: array, mem_addr: array, next_addr: content) = timing.diagram(w_scale: 0.75, ..{
  import timing: *
  (
    (label: "M-cycle", wave: (
      x(1),
      ..range(1 + duration).map((cycle) => {
        let m_cycle = cycle + 1
        if m_cycle == duration + 1 {
          d(8, "M" + str(m_cycle) + "/M1")
        } else {
          d(8, "M" + str(m_cycle))
        }
      }),
      x(1),
    )),
    (label: "Instruction", wave: (
      d(9, [Previous], opacity: 40%),
      d(duration * 8, mnemonic),
      x(1, opacity: 40%),
    )),
    (label: "Mem R/W", wave: (
      x(1),
      timing.d(8, [R: opcode]),
      ..mem_rw.map((label) => if label == "U" { timing.u(8) } else { timing.d(8, label) }),
      timing.d(8, [R: next op], opacity: 40%),
      x(1, opacity: 40%),
    )),
    (label: "Mem addr", wave: (
      x(1),
      timing.d(8, [PC#sub[0]]),
      ..mem_addr.map((label) => if label == "U" { timing.u(8) } else { timing.d(8, label) }),
      timing.d(8, next_addr, opacity: 40%),
      x(1, opacity: 40%),
    )),
  )
})

#let instruction = (body, mnemonic: str, length: int, duration: int, opcode: content, flags: [-], mem_rw: array, mem_addr: array, next_addr: [], pseudocode: content) => instruction-block(
  body,
  [*Opcode*], opcode,
  [*Length*], if length > 1 { str(length) + " bytes" } else { "1 byte" },
  [*Duration*], if duration > 1 { str(duration) + " machine cycles" } else { "1 machine cycle" },
  [*Flags*], flags,
  [*Timing*], instruction-timing(mnemonic: mnemonic, duration: duration, mem_rw: mem_rw, mem_addr: mem_addr, next_addr: if next_addr == [] { [PC#sub[0]+#length] } else { next_addr }),
  [*Pseudocode*], pseudocode,
)

#let flag-update = awesome[\u{f005}]

== Sharp SM83 instruction set

=== Overview

==== CB opcode prefix <op:CB>
==== Undefined opcodes <op:undefined>

=== 8-bit load instructions

#instruction(
  [
    ==== LD r, r': Load register (register) <op:LD_r_r>

    Load to the 8-bit register `r`, data from the 8-bit register `r'`.
  ],
  mnemonic: "LD r, r'",
  length: 1,
  duration: 1,
  opcode: [#bin("01xxxyyy")/various],
  mem_rw: (),
  mem_addr: (),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
# example: LD B, C
if opcode == 0x41:
  B = C
    ```
)

#instruction(
  [
    ==== LD r, n: Load register (immediate) <op:LD_r_n>

    Load to the 8-bit register `r`, the immediate data `n`.
  ],
  mnemonic: "LD r, n",
  length: 2,
  duration: 2,
  opcode: [#bin("00xxx110")/various + `n`],
  mem_rw: ([R: `n`],),
  mem_addr: ([PC#sub[0]+1],),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
# example: LD B, n
if opcode == 0x06:
  B = read_memory(addr=PC); PC = PC + 1
  ```
)

#instruction(
  [
    ==== LD r, (HL): Load register (indirect HL) <op:LD_r_hl>

    Load to the 8-bit register `r`, data from the absolute address specified by the 16-bit register HL.
  ],
  mnemonic: "LD r, (HL)",
  length: 1,
  duration: 2,
  opcode: [#bin("01xxx110")/various],
  mem_rw: ([R: data],),
  mem_addr: ([HL],),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
# example: LD B, (HL)
if opcode == 0x46:
  B = read_memory(addr=HL)
  ```
)

#instruction(
  [
    ==== LD (HL), r: Load from register (indirect HL) <op:LD_hl_r>

    Load to the absolute address specified by the 16-bit register HL, data from the 8-bit register `r`.
  ],
  mnemonic: "LD (HL), r",
  length: 1,
  duration: 2,
  opcode: [#bin("01110xxx")/various],
  mem_rw: ([W: data],),
  mem_addr: ([HL],),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
# example: LD (HL), B
if opcode == 0x70:
  write_memory(addr=HL, data=B)
  ```
)

#instruction(
  [
    ==== LD (HL), n: Load from immediate data (indirect HL) <op:LD_hl_n>

    Load to the absolute address specified by the 16-bit register HL, the immediate data `n`.
  ],
  mnemonic: "LD (HL), n",
  length: 2,
  duration: 3,
  opcode: [#bin("00110110")/#hex("36") + `n`],
  mem_rw: ([R: `n`], [W: `n`],),
  mem_addr: ([PC#sub[0]+1], [HL],),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x36:
  n = read_memory(addr=PC); PC = PC + 1
  write_memory(addr=HL, data=n)
  ```
)

#instruction(
  [
    ==== LD A, (BC): Load accumulator (indirect BC) <op:LD_a_bc>

    Load to the 8-bit A register, data from the absolute address specified by the 16-bit register BC.
  ],
  mnemonic: "LD A, (BC)",
  length: 1,
  duration: 2,
  opcode: [#bin("00001010")/#hex("0A")],
  mem_rw: ([R: data],),
  mem_addr: ([BC],),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x0A:
  A = read_memory(addr=BC)
  ```
)

#instruction(
  [
    ==== LD A, (DE): Load accumulator (indirect DE) <op:LD_a_de>

    Load to the 8-bit A register, data from the absolute address specified by the 16-bit register DE.
  ],
  mnemonic: "LD A, (DE)",
  length: 1,
  duration: 2,
  opcode: [#bin("00011010")/#hex("1A")],
  mem_rw: ([R: data],),
  mem_addr: ([DE],),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x1A:
  A = read_memory(addr=DE)
  ```
)

#instruction(
  [
    ==== LD (BC), A: Load from accumulator (indirect BC) <op:LD_bc_a>

    Load to the absolute address specified by the 16-bit register BC, data from the 8-bit A register.
  ],
  mnemonic: "LD (BC), A",
  length: 1,
  duration: 2,
  opcode: [#bin("00000010")/#hex("02")],
  mem_rw: ([W: data],),
  mem_addr: ([BC],),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x02:
  write_memory(addr=BC, data=A)
  ```
)

#instruction(
  [
    ==== LD (DE), A: Load from accumulator (indirect DE) <op:LD_de_a>

    Load to the absolute address specified by the 16-bit register DE, data from the 8-bit A register.
  ],
  mnemonic: "LD (DE), A",
  length: 1,
  duration: 2,
  opcode: [#bin("00010010")/#hex("12")],
  mem_rw: ([W: data],),
  mem_addr: ([DE],),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x12:
  write_memory(addr=DE, data=A)
  ```
)

#instruction(
  [
    ==== LD A, (nn): Load accumulator (direct) <op:LD_a_nn>

    Load to the 8-bit A register, data from the absolute address specified by the 16-bit operand `nn`.
  ],
  mnemonic: "LD A, (nn)",
  length: 3,
  duration: 4,
  opcode: [#bin("11111010")/#hex("FA") + LSB of `n` + MSB of `n`],
  mem_rw: ([R: lsb(`nn`)], [R: msb(`nn`)], [R: data],),
  mem_addr: ([PC#sub[0]+1], [PC#sub[0]+2], [`nn`]),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xFA:
  nn_lsb = read_memory(addr=PC); PC = PC + 1
  nn_msb = read_memory(addr=PC); PC = PC + 1
  nn = unsigned_16(lsb=nn_lsb, msb=nn_msb)
  A = read_memory(addr=nn)
  ```
)

#instruction(
  [
    ==== LD (nn), A: Load from accumulator (direct) <op:LD_nn_a>

    Load to the absolute address specified by the 16-bit operand `nn`, data from the 8-bit A register.
  ],
  mnemonic: "LD (nn), A",
  length: 3,
  duration: 4,
  opcode: [#bin("11101010")/#hex("EA") + LSB of `n` + MSB of `n`],
  mem_rw: ([R: lsb(`nn`)], [R: msb(`nn`)], [W: data],),
  mem_addr: ([PC#sub[0]+1], [PC#sub[0]+2], [`nn`]),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xEA:
  nn_lsb = read_memory(addr=PC); PC = PC + 1
  nn_msb = read_memory(addr=PC); PC = PC + 1
  nn = unsigned_16(lsb=nn_lsb, msb=nn_msb)
  write_memory(addr=nn, data=A)
  ```
)

#instruction(
  [
    ==== LDH A, (C): Load accumulator (indirect #hex("FF00")+C) <op:LDH_a_c>

    Load to the 8-bit A register, data from the address specified by the 8-bit C register. The full 16-bit absolute address is obtained by setting the most significant byte to #hex("FF") and the least significant byte to the value of C, so the possible range is #hex-range("FF00", "FFFF").
  ],
  mnemonic: "LDH A, (C)",
  length: 1,
  duration: 2,
  opcode: [#bin("11110010")/#hex("F2")],
  mem_rw: ([R: A],),
  mem_addr: ([#hex("FF00")+C],),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xE2:
  A = read_memory(addr=unsigned_16(lsb=C, msb=0xFF))
  ```
)

#instruction(
  [
    ==== LDH (C), A: Load from accumulator (indirect #hex("FF00")+C) <op:LDH_c_a>

    Load to the address specified by the 8-bit C register, data from the 8-bit A register. The full 16-bit absolute address is obtained by setting the most significant byte to #hex("FF") and the least significant byte to the value of C, so the possible range is #hex-range("FF00", "FFFF").
  ],
  mnemonic: "LDH (C), A",
  length: 1,
  duration: 2,
  opcode: [#bin("11100010")/#hex("E2")],
  mem_rw: ([W: A],),
  mem_addr: ([#hex("FF00")+C],),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xE2:
  write_memory(addr=unsigned_16(lsb=C, data=msb=0xFF), A)
  ```
)

#instruction(
  [
    ==== LDH A, (n): Load accumulator (direct #hex("FF00")+n) <op:LDH_a_n>

    Load to the 8-bit A register, data from the address specified by the 8-bit immediate data `n`. The full 16-bit absolute address is obtained by setting the most significant byte to #hex("FF") and the least significant byte to the value of `n`, so the possible range is #hex-range("FF00", "FFFF").
  ],
  mnemonic: "LDH A, (n)",
  length: 2,
  duration: 3,
  opcode: [#bin("11110000")/#hex("F0")],
  mem_rw: ([R: `n`], [R: A],),
  mem_addr: ([PC#sub[0]+1], [#hex("FF00")+`n`],),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xF0:
  n = read_memory(addr=PC); PC = PC + 1
  A = read_memory(addr=unsigned_16(lsb=n, msb=0xFF))
  ```
)

#instruction(
  [
    ==== LDH (n), A: Load from accumulator (direct #hex("FF00")+n) <op:LDH_n_a>

    Load to the address specified by the 8-bit immediate data `n`, data from the 8-bit A register. The full 16-bit absolute address is obtained by setting the most significant byte to #hex("FF") and the least significant byte to the value of `n`, so the possible range is #hex-range("FF00", "FFFF").
  ],
  mnemonic: "LDH (n), A",
  length: 2,
  duration: 3,
  opcode: [#bin("11100000")/#hex("E0")],
  mem_rw: ([R: `n`], [W: A],),
  mem_addr: ([PC#sub[0]+1], [#hex("FF00")+C],),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xE0:
  n = read_memory(addr=PC); PC = PC + 1
  write_memory(addr=unsigned_16(lsb=n, data=msb=0xFF), A)
  ```
)

#instruction(
  [
    ==== LD A, (HL-): Load accumulator (indirect HL, decrement) <op:LD_a_hld>

    Load to the 8-bit A register, data from the absolute address specified by the 16-bit register HL. The value of HL is decremented after the memory read.
  ],
  mnemonic: "LD A, (HL-)",
  length: 1,
  duration: 2,
  opcode: [#bin("00111010")/#hex("3A")],
  mem_rw: ([R: A],),
  mem_addr: ([HL],),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x3A:
  A = read_memory(addr=HL); HL = HL - 1
  ```
)

#instruction(
  [
    ==== LD (HL-), A: Load from accumulator (indirect HL, decrement) <op:LD_hld_a>

    Load to the absolute address specified by the 16-bit register HL, data from the 8-bit A register. The value of HL is decremented after the memory write.
  ],
  mnemonic: "LD (HL-), A",
  length: 1,
  duration: 2,
  opcode: [#bin("00110010")/#hex("32")],
  mem_rw: ([W: A],),
  mem_addr: ([HL],),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x32:
  write_memory(addr=HL, data=A); HL = HL - 1
  ```
)

#instruction(
  [
    ==== LD A, (HL+): Load accumulator (indirect HL, increment) <op:LD_a_hli>

    Load to the 8-bit A register, data from the absolute address specified by the 16-bit register HL. The value of HL is incremented after the memory read.
  ],
  mnemonic: "LD A, (HL+)",
  length: 1,
  duration: 2,
  opcode: [#bin("00101010")/#hex("2A")],
  mem_rw: ([R: A],),
  mem_addr: ([HL],),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x2A:
  A = read_memory(addr=HL); HL = HL + 1
  ```
)

#instruction(
  [
    ==== LD (HL+), A: Load from accumulator (indirect HL, increment) <op:LD_hli_a>

    Load to the absolute address specified by the 16-bit register HL, data from the 8-bit A register. The value of HL is decremented after the memory write.
  ],
  mnemonic: "LD (HL+), A",
  length: 1,
  duration: 2,
  opcode: [#bin("00100010")/#hex("22")],
  mem_rw: ([W: A],),
  mem_addr: ([HL],),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x32:
  write_memory(addr=HL, data=A); HL = HL + 1
  ```
)

=== 16-bit load instructions

#instruction(
  [
    ==== LD rr, nn: Load 16-bit register / register pair <op:LD_rr_nn>

    Load to the 16-bit register `rr`, the immediate 16-bit data `nn`.
  ],
  mnemonic: "LD rr, nn",
  length: 3,
  duration: 3,
  opcode: [#bin("00xx0001")/various + LSB of `nn` + MSB of `nn`],
  mem_rw: ([R: lsb(`nn`)], [R: msb(`nn`)],),
  mem_addr: ([PC#sub[0]+1], [PC#sub[0]+2],),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
# example: LD BC, nn
if opcode == 0x01:
  nn_lsb = read_memory(addr=PC); PC = PC + 1
  nn_msb = read_memory(addr=PC); PC = PC + 1
  nn = unsigned_16(lsb=nn_lsb, msb=nn_msb)
  BC = nn
  ```
)

#instruction(
  [
    ==== LD (nn), SP: Load from stack pointer (direct) <op:LD_nn_sp>

    Load to the absolute address specified by the 16-bit operand `nn`, data from the 16-bit SP register.
  ],
  mnemonic: "LD (nn), SP",
  length: 3,
  duration: 5,
  opcode: [#bin("00001000")/#hex("08") + LSB of `nn` + MSB of `nn`],
  mem_rw: ([R: lsb(`nn`)], [R: msb(`nn`)], [W: lsb(SP)], [W: msb(SP)],),
  mem_addr: ([PC#sub[0]+1], [PC#sub[0]+2], [`nn`], [`nn`+1]),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x08:
  nn_lsb = read_memory(addr=PC); PC = PC + 1
  nn_msb = read_memory(addr=PC); PC = PC + 1
  nn = unsigned_16(lsb=nn_lsb, msb=nn_msb)
  write_memory(addr=nn, data=lsb(SP))
  write_memory(addr=nn+1, data=msb(SP))
  ```
)

#instruction(
  [
    ==== LD SP, HL: Load stack pointer from HL <op:LD_sp_hl>

    Load to the 16-bit SP register, data from the 16-bit HL register.
  ],
  mnemonic: "LD SP, HL",
  length: 1,
  duration: 2,
  opcode: [#bin("11111001")/#hex("F9")],
  mem_rw: ("U",),
  mem_addr: ("U",),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xF9:
  SP = HL
  ```
)

#instruction(
  [
    ==== PUSH rr: Push to stack <op:PUSH_rr>

    Push to the stack memory, data from the 16-bit register `rr`.
  ],
  mnemonic: "PUSH rr",
  length: 1,
  duration: 4,
  opcode: [#bin("11xx0101")/various],
  mem_rw: ("U", [W: msb(`rr`)], [W: lsb(`rr`)],),
  mem_addr: ([SP#sub[0]], [SP#sub[0]-1], [SP#sub[0]-2],),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
# example: PUSH BC
if opcode == 0xC5:
  SP = SP - 1
  write_memory(addr=SP, data=msb(BC)); SP = SP - 1
  write_memory(addr=SP, data=lsb(BC))
  ```
)

#instruction(
  [
    ==== POP rr: Pop from stack <op:POP_rr>

    Pops to the 16-bit register `rr`, data from the stack memory.

    This instruction does not do calculations that affect flags, but POP AF completely replaces the F register value, so all flags are changed based on the 8-bit data that is read from memory.
  ],
  mnemonic: "POP rr",
  length: 1,
  duration: 3,
  flags: [See the instruction description],
  opcode: [#bin("11xx0001")/various],
  mem_rw: ([R: lsb(`rr`)], [R: msb(`rr`)],),
  mem_addr: ([SP#sub[0]], [SP#sub[0]-1], [SP#sub[0]-2],),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
# example: POP BC
if opcode == 0xC1:
  lsb = read_memory(addr=SP); SP = SP + 1
  msb = read_memory(addr=SP); SP = SP + 1
  BC = unsigned_16(lsb=lsb, msb=msb)
  ```
)

==== LD HL,SP+e <op:LD_hl_sp_e>

TODO

=== 8-bit arithmetic and logical instructions

#instruction(
  [
    ==== ADD r: Add (register) <op:ADD_r>

    Adds to the 8-bit A register, the 8-bit register `r`, and stores the result back into the A register.
  ],
  mnemonic: "ADD r",
  length: 1,
  duration: 1,
  flags: [Z = #flag-update, N = 0, H = #flag-update, C = #flag-update],
  opcode: [#bin("10000xxx")/various],
  mem_rw: (),
  mem_addr: (),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
# example: ADD B
if opcode == 0x80:
  result, carry_per_bit = A + B
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  ```
)

#instruction(
  [
    ==== ADD (HL): Add (indirect HL) <op:ADD_hl>

    Adds to the 8-bit A register, data from the absolute address specified by the 16-bit register HL, and stores the result back into the A register.
  ],
  mnemonic: "ADD (HL)",
  length: 1,
  duration: 2,
  flags: [Z = #flag-update, N = 0, H = #flag-update, C = #flag-update],
  opcode: [#bin("10000110")/#hex("86")],
  mem_rw: ([R: data],),
  mem_addr: ([HL],),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x86:
  data = read_memory(addr=HL)
  result, carry_per_bit = A + data
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  ```
)

#instruction(
  [
    ==== ADD n: Add (immediate) <op:ADD_n>

    Adds to the 8-bit A register, the immediate data `n`, and stores the result back into the A register.
  ],
  mnemonic: "ADD n",
  length: 1,
  duration: 2,
  flags: [Z = #flag-update, N = 0, H = #flag-update, C = #flag-update],
  opcode: [#bin("11000110")/#hex("C6")],
  mem_rw: ([R: `n`],),
  mem_addr: ([PC#sub[0]+1],),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xC6:
  n = read_memory(addr=PC); PC = PC + 1
  result, carry_per_bit = A + n
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  ```
)

#instruction(
  [
    ==== ADC r: Add with carry (register) <op:ADC_r>

    Adds to the 8-bit A register, the carry flag and the 8-bit register `r`, and stores the result back into the A register.

  ],
  mnemonic: "ADC r",
  length: 1,
  duration: 1,
  flags: [Z = #flag-update, N = 0, H = #flag-update, C = #flag-update],
  opcode: [#bin("10001xxx")/various],
  mem_rw: (),
  mem_addr: (),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
# example: ADC B
if opcode == 0x88:
  result, carry_per_bit = A + flags.C + B
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  ```
)

#instruction(
  [
    ==== ADC (HL): Add with carry (indirect HL) <op:ADC_hl>

    Adds to the 8-bit A register, the carry flag and data from the absolute address specified by the 16-bit register HL, and stores the result back into the A register.
  ],
  mnemonic: "ADC (HL)",
  length: 1,
  duration: 2,
  flags: [Z = #flag-update, N = 0, H = #flag-update, C = #flag-update],
  opcode: [#bin("10001110")/#hex("8E")],
  mem_rw: ([R: data],),
  mem_addr: ([HL],),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x8E:
  data = read_memory(addr=HL)
  result, carry_per_bit = A + flags.C + data
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  ```
)

#instruction(
  [
    ==== ADC n: Add with carry (immediate) <op:ADC_n>

    Adds to the 8-bit A register, the carry flag and the immediate data `n`, and stores the result back into the A register.
  ],
  mnemonic: "ADC n",
  length: 1,
  duration: 2,
  flags: [Z = #flag-update, N = 0, H = #flag-update, C = #flag-update],
  opcode: [#bin("11001110")/#hex("CE") + `n`],
  mem_rw: ([R: `n`],),
  mem_addr: ([PC#sub[0]+1],),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xCE:
  n = read_memory(addr=PC); PC = PC + 1
  result, carry_per_bit = A + flags.C + n
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  ```
)

#instruction(
  [
    ==== SUB r: Subtract (register) <op:SUB_r>

    Subtracts from the 8-bit A register, the 8-bit register `r`, and stores the result back into the A register.
  ],
  mnemonic: "SUB r",
  length: 1,
  duration: 1,
  flags: [Z = #flag-update, N = 1, H = #flag-update, C = #flag-update],
  opcode: [#bin("10010xxx")/various],
  mem_rw: (),
  mem_addr: (),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
# example: SUB B
if opcode == 0x90:
  result, carry_per_bit = A - B
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 1
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  ```
)

#instruction(
  [
    ==== SUB (HL): Subtract (indirect HL) <op:SUB_hl>

    Subtracts from the 8-bit A register, data from the absolute address specified by the 16-bit register HL, and stores the result back into the A register.
  ],
  mnemonic: "SUB (HL)",
  length: 1,
  duration: 2,
  flags: [Z = #flag-update, N = 1, H = #flag-update, C = #flag-update],
  opcode: [#bin("10010110")/#hex("96")],
  mem_rw: ([R: data],),
  mem_addr: ([HL],),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x96:
  data = read_memory(addr=HL)
  result, carry_per_bit = A - data
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 1
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  ```
)

#instruction(
  [
    ==== SUB n: Subtract (immediate) <op:SUB_n>

    Subtracts from the 8-bit A register, the immediate data `n`, and stores the result back into the A register.
  ],
  mnemonic: "SUB n",
  length: 1,
  duration: 2,
  flags: [Z = #flag-update, N = 1, H = #flag-update, C = #flag-update],
  opcode: [#bin("11010110")/#hex("D6") + `n`],
  mem_rw: ([R: `n`],),
  mem_addr: ([PC#sub[0]+1],),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xD6:
  n = read_memory(addr=PC); PC = PC + 1
  result, carry_per_bit = A - n
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 1
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  ```
)

#instruction(
  [
    ==== SBC r: Subtract with carry (register) <op:SBC_r>

    Subtracts from the 8-bit A register, the carry flag and the 8-bit register `r`, and stores the result back into the A register.
  ],
  mnemonic: "SBC r",
  length: 1,
  duration: 1,
  flags: [Z = #flag-update, N = 1, H = #flag-update, C = #flag-update],
  opcode: [#bin("10011xxx")/various],
  mem_rw: (),
  mem_addr: (),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
# example: SBC B
if opcode == 0x98:
  result, carry_per_bit = A - flags.C - B
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 1
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  ```
)

#instruction(
  [
    ==== SBC (HL): Subtract with carry (indirect HL) <op:SBC_hl>

    Subtracts from the 8-bit A register, the carry flag and data from the absolute address specified by the 16-bit register HL, and stores the result back into the A register.
  ],
  mnemonic: "SBC (HL)",
  length: 1,
  duration: 2,
  flags: [Z = #flag-update, N = 1, H = #flag-update, C = #flag-update],
  opcode: [#bin("10011110")/#hex("9E")],
  mem_rw: ([R: data],),
  mem_addr: ([HL],),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x9E:
  data = read_memory(addr=HL)
  result, carry_per_bit = A - flags.C - data
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 1
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  ```
)

#instruction(
  [
    ==== SBC n: Subtract with carry (immediate) <op:SBC_n>

    Subtracts from the 8-bit A register, the carry flag and the immediate data `n`, and stores the result back into the A register.
  ],
  mnemonic: "SBC n",
  length: 1,
  duration: 2,
  flags: [Z = #flag-update, N = 1, H = #flag-update, C = #flag-update],
  opcode: [#bin("11011110")/#hex("DE") + `n`],
  mem_rw: ([R: `n`],),
  mem_addr: ([HL],),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xDE:
  n = read_memory(addr=PC); PC = PC + 1
  result, carry_per_bit = A - flags.C - n
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 1
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  ```
)

#instruction(
  [
    ==== CP r: Compare (register) <op:CP_r>

    Subtracts from the 8-bit A register, the 8-bit register `r`, and updates flags based on the result. This instruction is basically identical to #link(<op:SUB_r>)[SUB r], but does not update the A register.
  ],
  mnemonic: "CP r",
  length: 1,
  duration: 1,
  flags: [Z = #flag-update, N = 1, H = #flag-update, C = #flag-update],
  opcode: [#bin("10111xxx")/various],
  mem_rw: (),
  mem_addr: (),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
# example: CP B
if opcode == 0xB8:
  result, carry_per_bit = A - B
  flags.Z = 1 if result == 0 else 0
  flags.N = 1
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  ```
)

#instruction(
  [
    ==== CP (HL): Compare (indirect HL) <op:CP_hl>

    Subtracts from the 8-bit A register, data from the absolute address specified by the 16-bit register HL, and updates flags based on the result. This instruction is basically identical to #link(<op:SUB_hl>)[SUB (HL)], but does not update the A register.
  ],
  mnemonic: "CP (HL)",
  length: 1,
  duration: 2,
  flags: [Z = #flag-update, N = 1, H = #flag-update, C = #flag-update],
  opcode: [#bin("10011110")/#hex("9E")],
  mem_rw: ([R: data],),
  mem_addr: ([HL],),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xBE:
  data = read_memory(addr=HL)
  result, carry_per_bit = A - data
  flags.Z = 1 if result == 0 else 0
  flags.N = 1
  flags.H = 1 if carry_per_bit[3] else 0
  flags.C = 1 if carry_per_bit[7] else 0
  ```
)

#instruction(
  [
    ==== CP n: Compare (immediate) <op:CP_n>

    Subtracts from the 8-bit A register, the immediate data `n`, and updates flags based on the result. This instruction is basically identical to #link(<op:SUB_n>)[SUB n], but does not update the A register.
  ],
  mnemonic: "CP n",
  length: 1,
  duration: 2,
  flags: [Z = #flag-update, N = 1, H = #flag-update, C = #flag-update],
  opcode: [#bin("11111110")/#hex("FE") + `n`],
  mem_rw: ([R: `n`],),
  mem_addr: ([PC#sub[0]+1],),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xFE:
  n = read_memory(addr=PC); PC = PC + 1
  result, carry_per_bit = A - n
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
  length: 1,
  duration: 1,
  flags: [Z = #flag-update, N = 0, H = #flag-update],
  opcode: [#bin("00xxx100")/various],
  mem_rw: (),
  mem_addr: (),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
# example: INC B
if opcode == 0x04:
  result, carry_per_bit = B + 1
  B = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 1 if carry_per_bit[3] else 0
  ```
)

#instruction(
  [
    ==== INC (HL): Increment (indirect HL) <op:INC_hl>

    Increments data at the absolute address specified by the 16-bit register HL.
  ],
  mnemonic: "INC (HL)",
  length: 1,
  duration: 3,
  flags: [Z = #flag-update, N = 0, H = #flag-update],
  opcode: [#bin("00110100")/#hex("34")],
  mem_rw: ([R: data], [W: data],),
  mem_addr: ([HL], [HL],),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x34:
  data = read_memory(addr=HL)
  result, carry_per_bit = data + 1
  write_memory(addr=HL, data=result)
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 1 if carry_per_bit[3] else 0
  ```
)

#instruction(
  [
    ==== DEC r: Decrement (register) <op:DEC_r>

    Increments data in the 8-bit register `r`.
  ],
  mnemonic: "DEC r",
  length: 1,
  duration: 1,
  flags: [Z = #flag-update, N = 1, H = #flag-update],
  opcode: [#bin("00xxx101")/various],
  mem_rw: (),
  mem_addr: (),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
# example: DEC B
if opcode == 0x05:
  result, carry_per_bit = B - 1
  B = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 1
  flags.H = 1 if carry_per_bit[3] else 0
  ```
)

#instruction(
  [
    ==== DEC (HL): Decrement (indirect HL) <op:DEC_hl>

    Decrements data at the absolute address specified by the 16-bit register HL.
  ],
  mnemonic: "DEC (HL)",
  length: 1,
  duration: 3,
  flags: [Z = #flag-update, N = 1, H = #flag-update],
  opcode: [#bin("00110101")/#hex("35")],
  mem_rw: ([R: data], [W: data],),
  mem_addr: ([HL], [HL],),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x35:
  data = read_memory(addr=HL)
  result, carry_per_bit = data - 1
  write_memory(addr=HL, data=result)
  flags.Z = 1 if result == 0 else 0
  flags.N = 1
  flags.H = 1 if carry_per_bit[3] else 0
  ```
)

#instruction(
  [
    ==== AND r: Bitwise AND (register) <op:AND_r>

    Performs a bitwise AND operation between the 8-bit A register and the 8-bit register `r`, and stores the result back into the A register.
  ],
  mnemonic: "AND r",
  length: 1,
  duration: 1,
  flags: [Z = #flag-update, N = 0, H = 1, C = 0],
  opcode: [#bin("10100xxx")/various],
  mem_rw: (),
  mem_addr: (),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
# example: AND B
if opcode == 0xA0:
  result = A & B
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 1
  flags.C = 0
  ```
)

#instruction(
  [
    ==== AND (HL): Bitwise AND (indirect HL) <op:AND_hl>

    Performs a bitwise AND operation between the 8-bit A register and data from the absolute address specified by the 16-bit register HL, and stores the result back into the A register.
  ],
  mnemonic: "AND (HL)",
  length: 1,
  duration: 2,
  flags: [Z = #flag-update, N = 0, H = 1, C = 0],
  opcode: [#bin("10100110")/#hex("A6")],
  mem_rw: ([R: data],),
  mem_addr: ([HL],),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xA6:
  data = read_memory(addr=HL)
  result = A & data
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 1
  flags.C = 0
  ```
)

#instruction(
  [
    ==== AND n: Bitwise AND (immediate) <op:AND_n>

    Performs a bitwise AND operation between the 8-bit A register and immediate data `n`, and stores the result back into the A register.
  ],
  mnemonic: "AND n",
  length: 1,
  duration: 2,
  flags: [Z = #flag-update, N = 0, H = 1, C = 0],
  opcode: [#bin("11100110")/#hex("E6") + `n`],
  mem_rw: ([R: `n`],),
  mem_addr: ([PC#sub[0]+1],),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xE6:
  n = read_memory(addr=PC); PC = PC + 1
  result = A & n
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 1
  flags.C = 0
  ```
)

#instruction(
  [
    ==== OR r: Bitwise OR (register) <op:OR_r>

    Performs a bitwise OR operation between the 8-bit A register and the 8-bit register `r`, and stores the result back into the A register.
  ],
  mnemonic: "OR r",
  length: 1,
  duration: 1,
  flags: [Z = #flag-update, N = 0, H = 0, C = 0],
  opcode: [#bin("10110xxx")/various],
  mem_rw: (),
  mem_addr: (),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
# example: OR B
if opcode == 0xB0:
  result = A | B
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 0
  flags.C = 0
  ```
)

#instruction(
  [
    ==== OR (HL): Bitwise OR (indirect HL) <op:OR_hl>

    Performs a bitwise OR operation between the 8-bit A register and data from the absolute address specified by the 16-bit register HL, and stores the result back into the A register.
  ],
  mnemonic: "OR (HL)",
  length: 1,
  duration: 2,
  flags: [Z = #flag-update, N = 0, H = 0, C = 0],
  opcode: [#bin("10110110")/#hex("B6")],
  mem_rw: ([R: data],),
  mem_addr: ([HL],),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xB6:
  data = read_memory(addr=HL)
  result = A | data
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 0
  flags.C = 0
  ```
)

#instruction(
  [
    ==== OR n: Bitwise OR (immediate) <op:OR_n>

    Performs a bitwise OR operation between the 8-bit A register and immediate data `n`, and stores the result back into the A register.
  ],
  mnemonic: "OR n",
  length: 1,
  duration: 2,
  flags: [Z = #flag-update, N = 0, H = 0, C = 0],
  opcode: [#bin("11110110")/#hex("F6") + `n`],
  mem_rw: ([R: `n`],),
  mem_addr: ([PC#sub[0]+1],),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xF6:
  n = read_memory(addr=PC); PC = PC + 1
  result = A | n
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 0
  flags.C = 0
  ```
)

#instruction(
  [
    ==== XOR r: Bitwise XOR (register) <op:XOR_r>

    Performs a bitwise XOR operation between the 8-bit A register and the 8-bit register `r`, and stores the result back into the A register.
  ],
  mnemonic: "XOR r",
  length: 1,
  duration: 1,
  flags: [Z = #flag-update, N = 0, H = 0, C = 0],
  opcode: [#bin("10101xxx")/various],
  mem_rw: (),
  mem_addr: (),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
# example: XOR B
if opcode == 0xB8:
  result = A ^ B
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 0
  flags.C = 0
  ```
)

#instruction(
  [
    ==== XOR (HL): Bitwise XOR (indirect HL) <op:XOR_hl>

    Performs a bitwise XOR operation between the 8-bit A register and data from the absolute address specified by the 16-bit register HL, and stores the result back into the A register.
  ],
  mnemonic: "XOR (HL)",
  length: 1,
  duration: 2,
  flags: [Z = #flag-update, N = 0, H = 0, C = 0],
  opcode: [#bin("10101110")/#hex("AE")],
  mem_rw: ([R: data],),
  mem_addr: ([HL],),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xBE:
  data = read_memory(addr=HL)
  result = A ^ data
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 0
  flags.C = 0
  ```
)

#instruction(
  [
    ==== XOR n: Bitwise XOR (immediate) <op:XOR_n>

    Performs a bitwise XOR operation between the 8-bit A register and immediate data `n`, and stores the result back into the A register.
  ],
  mnemonic: "XOR n",
  length: 1,
  duration: 2,
  flags: [Z = #flag-update, N = 0, H = 0, C = 0],
  opcode: [#bin("11101110")/#hex("EE") + `n`],
  mem_rw: ([R: `n`],),
  mem_addr: ([PC#sub[0]+1],),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xEE:
  n = read_memory(addr=PC); PC = PC + 1
  result = A ^ n
  A = result
  flags.Z = 1 if result == 0 else 0
  flags.N = 0
  flags.H = 0
  flags.C = 0
  ```
)

#instruction(
  [
    ==== CCF: Complement carry flag <op:CCF>

    Flips the carry flag, and clears the N and H flags.
  ],
  mnemonic: "CCF",
  length: 1,
  duration: 1,
  flags: [N = 0, H = 0, C = #flag-update],
  opcode: [#bin("00111111")/#hex("3F")],
  mem_rw: (),
  mem_addr: (),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x3F:
  flags.N = 0
  flags.H = 0
  flags.C = ~flags.C
  ```
)

#instruction(
  [
    ==== SCF: Set carry flag <op:SCF>

    Sets the carry flag, and clears the N and H flags.
  ],
  mnemonic: "SCF",
  length: 1,
  duration: 1,
  flags: [N = 0, H = 0, C = 1],
  opcode: [#bin("00110111")/#hex("37")],
  mem_rw: (),
  mem_addr: (),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x37:
  flags.N = 0
  flags.H = 0
  flags.C = 1
  ```
)

#instruction(
  [
    ==== DAA: Decimal adjust accumulator <op:DAA>

    TODO
  ],
  mnemonic: "DAA",
  length: 1,
  duration: 1,
  flags: [Z = #flag-update, H = 0, C = #flag-update],
  opcode: [#bin("00100111")/#hex("27")],
  mem_rw: (),
  mem_addr: (),
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
  length: 1,
  duration: 1,
  flags: [N = 1, H = 1],
  opcode: [#bin("00101111")/#hex("2F")],
  mem_rw: (),
  mem_addr: (),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x2F:
  A = ~A
  flags.N = 1
  flags.H = 1
  ```
)

=== 16-bit arithmetic instructions

==== INC rr <op:INC_rr>

TODO

==== DEC rr <op:DEC_rr>

TODO

==== ADD HL,rr <op:ADD_hl_rr>

TODO

==== ADD SP, e <op:ADD_sp_e>

TODO

=== Rotate, shift, and bit operation instructions

==== RLCA <op:RLCA>

TODO

==== RRCA <op:RRCA>

TODO

==== RLA <op:RLA>

TODO

==== RRA <op:RRA>

TODO

==== RLC r <op:RLC_r>

TODO

==== RLC (HL) <op:RLC_hl>

TODO

==== RRC r <op:RRC_r>

TODO

==== RRC (HL) <op:RRC_hl>

TODO

==== RL r <op:RL_r>

TODO

==== RL (HL) <op:RL_hl>

TODO

==== RR r <op:RR_r>

TODO

==== RR (HL) <op:RR_hl>

TODO

==== SLA r <op:SLA_r>

TODO

==== SLA (HL) <op:SLA_hl>

TODO

==== SRA r <op:SRA_r>

TODO

==== SRA (HL) <op:SRA_hl>

TODO

==== SWAP r <op:SWAP_r>

TODO

==== SWAP (HL) <op:SWAP_hl>

TODO

==== SRL r <op:SRL_r>

TODO

==== SRL (HL) <op:SRL_hl>

TODO

==== BIT b, r <op:BIT_b_r>

TODO

==== BIT b, (HL) <op:BIT_b_hl>

TODO

==== RES b, r <op:RES_b_r>

TODO

==== RES b, (HL) <op:RES_b_hl>

TODO

==== SET b, r <op:SET_b_r>

TODO

==== SET b, (HL) <op:SET_b_hl>

TODO

=== Control flow instructions

#instruction(
  [
    ==== JP nn: Jump <op:JP>

    Unconditional jump to the absolute address specified by the 16-bit immediate operand `nn`.
  ],
  mnemonic: "JP nn",
  length: 3,
  duration: 4,
  opcode: [#bin("11000011")/#hex("C3") + LSB of `nn` + MSB of `nn`],
  mem_rw: ([R: lsb(`nn`)], [R: msb(`nn`)], "U",),
  mem_addr: ([PC#sub[0]+1], [PC#sub[0]+2], "U",),
  next_addr: [`nn`],
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xC3:
  nn_lsb = read_memory(addr=PC); PC = PC + 1
  nn_msb = read_memory(addr=PC); PC = PC + 1
  nn = unsigned_16(lsb=nn_lsb, msb=nn_msb)
  PC = nn
  ```
)

#instruction(
  [
    ==== JP HL: Jump to HL <op:JP_hl>

    Unconditional jump to the absolute address specified by the 16-bit register HL.
  ],
  mnemonic: "JP HL",
  length: 1,
  duration: 1,
  opcode: [#bin("11101001")/#hex("E9")],
  mem_rw: (),
  mem_addr: (),
  next_addr: [HL],
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xE9:
  PC = HL
  ```
)

#warning[
  In some documentation this instruction is written as `JP [HL]`. This is very misleading, since brackets are usually used to indicate a memory read, and this instruction simply copies the value of HL to PC.
]

#instruction-block(
  [
    ==== JP cc, nn: Jump (conditional) <op:JP_cc>

    Conditional jump to the absolute address specified by the 16-bit operand `nn`, depending on the condition `cc`.

    Note that the operand (absolute address) is read even when the condition is false!
  ],
  [*Opcode*], [#bin("110xx010")/various + LSB of `n` + MSB of `n`],
  [*Length*], [3 bytes],
  [*Duration*], [3 machine cycles (cc=false), or 4 machine cycles (cc=true)],
  [*Flags*], [-],
  [*Timing\ _cc=false_*], instruction-timing(
    mnemonic: "JP cc, nn",
    duration: 3,
    mem_rw: ([R: lsb(`nn`)], [R: msb(`nn`)]),
    mem_addr: ([PC#sub[0]+1], [PC#sub[0]+2],),
    next_addr: [PC#sub[0]+3],
  ),
  [*Timing\ _cc=true_*], instruction-timing(
    mnemonic: "JP cc, nn",
    duration: 4,
    mem_rw: ([R: lsb(`nn`)], [R: msb(`nn`)], "U",),
    mem_addr: ([PC#sub[0]+1], [PC#sub[0]+2], "U",),
    next_addr: [`nn`],
  ),
  [*Pseudocode*], ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode in [0xC2, 0xD2, 0xCA, 0xDA]:
  nn_lsb = read_memory(addr=PC); PC = PC + 1
  nn_msb = read_memory(addr=PC); PC = PC + 1
  nn = unsigned_16(lsb=nn_lsb, msb=nn_msb)
  if F.check_condition(cc):
    PC = nn
  ```,
)

#instruction(
  [
    ==== JR e: Relative jump <op:JR>

    Unconditional jump to the relative address specified by the signed 8-bit operand `e`.
  ],
  mnemonic: "JR e",
  length: 2,
  duration: 3,
  opcode: [#bin("00011000")/#hex("18") + offset `e`],
  mem_rw: ([R: `e`], "U",),
  mem_addr: ([PC#sub[0]+1], "U",),
  next_addr: [PC#sub[0]+2+`e`],
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x18:
  e = signed_8(read_memory(addr=PC); PC = PC + 1)
  PC = PC + e
  ```
)

#instruction-block(
  [
    ==== JR cc, e: Relative jump (conditional) <op:JR_cc>

    Conditional jump to the relative address specified by the signed 8-bit operand `e`, depending on the condition `cc`.

    Note that the operand (relative address offset) is read even when the condition is false!
  ],
  [*Opcode*], [#bin("001xx000")/various + offset `e`],
  [*Length*], [2 bytes],
  [*Duration*], [2 machine cycles (cc=false), or 3 machine cycles (cc=true)],
  [*Flags*], [-],
  [*Timing\ _cc=false_*], instruction-timing(
    mnemonic: "JR cc, e",
    duration: 2,
    mem_rw: ([R: `e`],),
    mem_addr: ([PC#sub[0]+1],),
    next_addr: [PC#sub[0]+2],
  ),
  [*Timing\ _cc=true_*], instruction-timing(
    mnemonic: "JR cc, e",
    duration: 3,
    mem_rw: ([R: `e`], "U",),
    mem_addr: ([PC#sub[0]+1], "U",),
    next_addr: [PC#sub[0]+2+`e`],
  ),
  [*Pseudocode*], ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode in [0x20, 0x30, 0x28, 0x38]:
  e = signed_8(read_memory(addr=PC); PC = PC + 1)
  if F.check_condition(cc):
    PC = PC + e
  ```,
)

#instruction(
  [
    ==== CALL nn: Call function <op:CALL>

    Unconditional function call to the absolute address specified by the 16-bit operand `nn`.
  ],
  mnemonic: "CALL nn",
  length: 3,
  duration: 6,
  opcode: [#bin("11001101")/#hex("CD") + LSB of `nn` + MSB of `nn`],
  mem_rw: ([R: lsb(`nn`)], [R: msb(`nn`)], "U", [W: msb(PC#sub[0]+3)], [W: lsb(PC#sub[0]+3)],),
  mem_addr: ([PC#sub[0]+1], [PC#sub[0]+2], [SP#sub[0]], [SP#sub[0]-1], [SP#sub[0]-2],),
  next_addr: [`nn`],
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xCD:
  nn_lsb = read_memory(addr=PC); PC = PC + 1
  nn_msb = read_memory(addr=PC); PC = PC + 1
  nn = unsigned_16(lsb=nn_lsb, msb=nn_msb)
  SP = SP - 1
  write_memory(addr=SP, data=msb(PC)); SP = SP - 1
  write_memory(addr=SP, data=lsb(PC))
  PC = nn
  ```
)

#instruction-block(
  [
    ==== CALL cc, nn: Call function (conditional) <op:CALL_cc>

    Conditional function call to the absolute address specified by the 16-bit operand `nn`, depending on the condition `cc`.

    Note that the operand (absolute address) is read even when the condition is false!
  ],
  [*Opcode*], [#bin("110xx100")/various + LSB of `nn` + MSB of `nn`],
  [*Length*], [3 bytes],
  [*Duration*], [3 machine cycles (cc=false), or 6 machine cycles (cc=true)],
  [*Flags*], [-],
  [*Timing\ _cc=false_*], instruction-timing(
    mnemonic: "CALL cc, nn",
    duration: 3,
    mem_rw: ([R: lsb(`nn`)], [R: msb(`nn`)],),
    mem_addr: ([PC#sub[0]+1], [PC#sub[0]+2],),
    next_addr: [PC#sub[0]+3],
  ),
  [*Timing\ _cc=true_*], instruction-timing(
    mnemonic: "CALL cc, nn",
    duration: 6,
    mem_rw: ([R: lsb(`nn`)], [R: msb(`nn`)], "U", [W: msb(PC#sub[0]+3)], [W: lsb(PC#sub[0]+3)],),
    mem_addr: ([PC#sub[0]+1], [PC#sub[0]+2], [SP#sub[0]], [SP#sub[0]-1], [SP#sub[0]-2],),
    next_addr: [`nn`],
  ),
  [*Pseudocode*], ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode in [0xC4, 0xD4, 0xCC, 0xDC]:
  nn_lsb = read_memory(addr=PC); PC = PC + 1
  nn_msb = read_memory(addr=PC); PC = PC + 1
  nn = unsigned_16(lsb=nn_lsb, msb=nn_msb)
  if F.check_condition(cc):
    SP = SP - 1
    write_memory(addr=SP, data=msb(PC)); SP = SP - 1
    write_memory(addr=SP, data=lsb(PC))
    PC = nn
  ```,
)

#instruction(
  [
    ==== RET: Return from function <op:RET>

    Unconditional return from a function.
  ],
  mnemonic: "RET",
  length: 1,
  duration: 4,
  opcode: [#bin("11001001")/#hex("C9")],
  mem_rw: ([R: lsb(PC)], [R: msb(PC)], "U",),
  mem_addr: ([SP#sub[0]], [SP#sub[0]+1], "U",),
  next_addr: [PC from stack],
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xC9:
  lsb = read_memory(addr=SP); SP = SP + 1
  msb = read_memory(addr=SP); SP = SP + 1
  PC = unsigned_16(lsb=lsb, msb=msb)
  ```
)

#instruction-block(
  [
    ==== RET cc: Return from function (conditional) <op:RET_cc>

    Conditional return from a function, depending on the condition `cc`.
  ],
  [*Opcode*], [#bin("110xx000")/various],
  [*Length*], [1 byte],
  [*Duration*], [2 machine cycles (cc=false), or 5 machine cycles (cc=true)],
  [*Flags*], [-],
  [*Timing\ _cc=false_*], instruction-timing(
    mnemonic: "RET cc",
    duration: 2,
    mem_rw: ("U",),
    mem_addr: ("U",),
    next_addr: [PC#sub[0]+1],
  ),
  [*Timing\ _cc=true_*], instruction-timing(
    mnemonic: "RET cc",
    duration: 5,
    mem_rw: ("U", [R: lsb(PC)], [R: msb(PC)], "U",),
    mem_addr: ("U", [SP#sub[0]], [SP#sub[0]+1], "U",),
    next_addr: [PC from stack],
  ),
  [*Pseudocode*], ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode in [0xC0, 0xD0, 0xC8, 0xD8]:
  if F.check_condition(cc):
    lsb = read_memory(addr=SP); SP = SP + 1
    msb = read_memory(addr=SP); SP = SP + 1
    PC = unsigned_16(lsb=lsb, msb=msb)
  ```,
)

#instruction(
  [
    ==== RETI: Return from interrupt handler <op:RETI>

    Unconditional return from a function. Also enables interrupts by setting IME=1.
  ],
  mnemonic: "RETI",
  length: 1,
  duration: 4,
  opcode: [#bin("11011001")/#hex("D9")],
  mem_rw: ([R: lsb(PC)], [R: msb(PC)], "U",),
  mem_addr: ([SP#sub[0]], [SP#sub[0]+1], "U",),
  next_addr: [PC from stack],
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xD9:
  lsb = read_memory(addr=SP); SP = SP + 1
  msb = read_memory(addr=SP); SP = SP + 1
  PC = unsigned_16(lsb=lsb, msb=msb)
  IME = 1
  ```
)

#instruction(
  [
    ==== RST n: Restart / Call function (implied) <op:RST>

    Unconditional function call to the absolute fixed address defined by the opcode.
  ],
  mnemonic: "RST n",
  length: 1,
  duration: 4,
  opcode: [#bin("11xxx111")/various],
  mem_rw: ("U", [W: msb(PC#sub[0]+1)], [W: lsb(PC#sub[0]+1)],),
  mem_addr: ([SP#sub[0]], [SP#sub[0]-1], [SP#sub[0]-2],),
  next_addr: [`n`],
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode in [0xC7, 0xCF, 0xD7, 0xDF, 0xE7, 0xEF, 0xF7, 0xFF]:
  #   address 0x00, 0x08, 0x10, 0x18, 0x20, 0x28, 0x30, 0x38
  n = rst_address(opcode)
  SP = SP - 1
  write_memory(addr=SP, data=msb(PC)); SP = SP - 1
  write_memory(addr=SP, data=lsb(PC))
  PC = unsigned_16(lsb=n, msb=0x00)
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
  length: 1,
  duration: 1,
  opcode: [#bin("11110011")/#hex("F3")],
  mem_rw: (),
  mem_addr: (),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xF3:
  IME = 0
  ```
)

#instruction-block(
  [
    ==== EI: Enable interrupts <op:EI>

    Schedules interrupt handling to be enabled after the next machine cycle.
  ],
  [*Opcode*], [#bin("11111011")/#hex("FB")],
  [*Length*], [1 byte],
  [*Duration*], [2 machine cycles (cc=false), or 5 machine cycles (cc=true)],
  [*Flags*], [-],
  [*Timing*], instruction-timing(
    mnemonic: "EI",
    duration: 1,
    mem_rw: (),
    mem_addr: (),
    next_addr: [PC#sub[0]+1],
  ),
  [*Pseudocode*], ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0xFB:
  IME_scheduled = true
  ```,
)

#instruction(
  [
    ==== NOP: No operation <op:NOP>

    No operation. This instruction doesn't do anything, but can be used to add a delay of one machine cycle and increment PC by one.
  ],
  mnemonic: "NOP",
  length: 1,
  duration: 1,
  opcode: [#bin("00000000")/#hex("00")],
  mem_rw: (),
  mem_addr: (),
  pseudocode: ```python
opcode = read_memory(addr=PC); PC = PC + 1
if opcode == 0x00:
  // nothing
  ```
)
