#import "../../common.typ": *
#import "../../timing.typ"

== DMA (Direct Memory Access)

=== Object Attribute Memory (OAM) DMA

OAM DMA is a high-throughput mechanism for copying data to the OAM area (a.k.a. Object Attribute Memory, a.k.a. sprite memory). It can copy one byte per machine cycle without involving the CPU at all, which is much faster than the fastest possible `memcpy` routine that can be written with the SM83 instruction set. However, a transfer cannot be cancelled and the transfer length cannot be controlled, so the DMA transfer always updates the entire OAM area (= 160 bytes) even if you actually want to just update the first couple of bytes.

The Game Boy CPU chip contains a DMA controller that coordinates transfers between a *source area* and the *OAM area* independently of the CPU. While a transfer is in progress, it takes control of the source bus and the OAM area, so some precaution is needed with memory accesses (including instruction fetches) to avoid OAM DMA bus conflicts. OAM DMA uses a different address decoding scheme than normal memory accesses, so the source bus is always either the external bus or the video RAM bus, and the contents normally visible to the CPU in the #hex-range("FE00", "FFFF") address range cannot be used as a source for OAM DMA transfers.

The upper 8 bits of the OAM DMA source address are stored in the DMA register, while the lower 8 bits used by both the source and target address are stored in the DMA controller and are not accessible directly. A transfer always begins with #hex("00") in the lower bits and copies exactly 160 bytes, so the lower bits are never in the #hex-range("A0", "FF") range.

Writing to the DMA register updates the upper bits of the DMA source address and also triggers an OAM DMA transfer request, although the DMA transfer does not begin immediately.

#reg-figure(
  caption: [#hex("FF46") - DMA - OAM DMA control register]
)[
  #reg-table(
    [R/W-x], [R/W-x], [R/W-x], [R/W-x], [R/W-x], [R/W-x], [R/W-x], [R/W-x],
    table.cell(colspan: 8)[DMA\<7:0\>],
    [bit 7], [6], [5], [4], [3], [2], [1], [bit 0]
  )
  #set align(left)
  #grid(
    columns: (auto, 1fr),
    gutter: 1em,
    [*bit 7-0*], [
      *DMA\<7:0\>*: OAM DMA source address\
      Specifies the top 8 bits of the OAM DMA source address.

      Writing to this register requests an OAM DMA transfer, but it's just a request and the actual DMA transfer starts with a delay.

Reading this register returns the value that was previously written to the register. The stored value is not cleared on reset, so the initial value before the first write is unknown and should not be relied on.
    ],
  )
]

#warning[
  Avoid writing #hex-range("E0", "FF") to the DMA register, because some poorly designed flash carts can trigger bus conflicts or other dangerous behaviour.
]

==== OAM DMA address decoding

The OAM DMA controller uses a simplified address decoding scheme, which leads to some addresses being unusable as source addresses. Unlike normal memory accesses, OAM DMA transfers interpret all accesses in the #hex-range("A000", "FFFF") range as external RAM transfers. For example, if the OAM DMA wants to read #hex("FF00"), it will output #hex("FF00") on the external address bus and will assert the external RAM chip select signal. The P1 register which is normally at #hex("FF00") is not involved at all, because OAM DMA address decoding only uses the external bus and the video RAM bus. Instead, the resulting behaviour depends on several factors, including the connected cartridge. Some flash carts are not prepared for this unexpected scenario, and a bus conflict or worse behaviour can happen.

#figure(
  table(
    columns: 3,
    align: left + horizon,
    [DMA register value], [Used bus], [Asserted chip select signal],
    hex-range("00", "7F"), [external bus], [external ROM (A15)],
    hex-range("80", "9F"), [video RAM bus], [video RAM (MCS)],
    hex-range("A0", "FF"), [external bus], [external RAM (CS)],
  ),
  caption: "OAM DMA address decoding scheme"
)

==== OAM DMA transfer timing

#figure({
  import timing: diagram, clock as c, data as d, either as e, high as h, low as l, unknown as u, undefined as x, high_impedance as z, skip as s
  diagram(
    w_scale: 0.9,
    (label: "CLK 4 MiHz", wave: (
      l(1),
      ..range(40).map(_ => c(1)),
      s(),
      ..range(8).map(_ => c(1)),
      c(1),
    )),
    (label: "PHI 1 MiHz", wave: (
      l(1),
      ..range(5).map(_ => (c(4), c(4))).flatten(),
      s(),
      ..range(1).map(_ => (c(4), c(4))).flatten(),
      c(1),
    )),
    (label: "CPU activity", wave: (
      u(1),
      d(8, "W: DMA register"),
      u(32),
      s(),
      u(8),
      x(1),
    )),
    (label: "DMA activity", wave: (
      u(9),
      d(8, "Counter reset"),
      d(8, [Copy byte 0]),
      d(8, [Copy byte 1]),
      d(8, [Copy byte 2]),
      s(),
      d(8, [Copy byte 159]),
      x(1),
    )),
    (label: "Source", wave: (
      u(17),
      d(8, hex("XX00")),
      d(8, hex("XX01")),
      d(8, hex("XX02")),
      s(),
      d(8, hex("XX9F")),
      x(1),
    )),
    (label: "Destination", wave: (
      u(17),
      d(8, [#hex("FE00") OAM 0 LSB]),
      d(8, [#hex("FE01") OAM 0 MSB]),
      d(8, [#hex("FE02") OAM 1 LSB]),
      s(),
      d(8, [#hex("FE9F") OAM 39 MSB]),
      x(1),
    )),
  )},
  caption: "OAM DMA transfer timing"
)


==== OAM DMA bus conflicts

TODO
