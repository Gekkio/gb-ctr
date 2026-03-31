#import "../../common.typ": *

== Introduction to game cartridges

Unlike more modern consoles, Game Boys do not have dedicated internal memory meant for storing digital copies of games. Instead, games were sold as physical cartridges that could be inserted into the console. A physical cartridge is essentially a pluggable daughterboard with its own electronics.

=== Cartridge address space areas

The Game Boy CPU has a 16-bit address bus, giving it a 64 KiB address space (= 65536 possible addresses). Two regions of this space are reserved for a connected cartridge:

- a 32 KiB range in lower address space at #hex-range("0000", "7FFF")
- an 8 KiB range in upper address space at #hex-range("A000", "BFFF")

#addr-space-figure(
  ticks: (0x0000, 0x8000, 0xA000, 0xC000, 0xFFFF),
  regions: (
    (start: 0x0000, end: 0x8000, color: rgb("#b3b3ff"), highlight: true,  label: [Cartridge lower \ 32 KiB range]),
    (start: 0x8000, end: 0xA000, color: rgb("#eee"),    highlight: false, label: []),
    (start: 0xA000, end: 0xC000, color: rgb("#b3b3ff"), highlight: true,  label: [Cartridge upper \ 8 KiB range]),
    (start: 0xC000, end: 0x10000, color: rgb("#eee"),   highlight: false, label: []),
  ),
  caption: [Cartridge address space areas],
)

The SoC makes no assumption about the practical purpose of these areas, and simply permits the cartridge to react to reads and writes from the CPU core when the target address is in these areas. If no cartridge is connected, reads from these areas return undefined values and writes have no effect. The same thing applies if a cartridge _is_ connected but it simply doesn't react to the read or write (for example, when attempting to read RAM on a RAM-less cartridge).

=== Standard cartridge address space conventions

All genuine cartridges follow these conventions with only minor differences between them:

- The lower range #hex-range("0000", "7FFF") is typically divided into two 16 KiB banks: a fixed bank at #hex-range("0000", "3FFF") and a switchable bank at #hex-range("4000", "7FFF"). Simple cartridges with at most 32 KiB of ROM need no bank switching at all.

- The upper range #hex-range("A000", "BFFF") is typically mapped to RAM or cartridge hardware registers. This 8 KiB range could be the entire RAM, or a switchable bank if the total RAM size is larger than it.

#addr-space-figure(
  ticks: (0x0000, 0x4000, 0x8000, 0xA000, 0xC000, 0xFFFF),
  regions: (
    (start: 0x0000, end: 0x4000, color: rgb("#b3ffff"), highlight: true,  label: [Fixed ROM bank \ 16 KiB]),
    (start: 0x4000, end: 0x8000, color: rgb("#b3ffff"), highlight: true,  label: [Switchable ROM bank \ 16 KiB]),
    (start: 0x8000, end: 0xA000, color: rgb("#eee"),    highlight: false, label: []),
    (start: 0xA000, end: 0xC000, color: rgb("#ffffb3"), highlight: true,  label: [RAM (if present) \ 8 KiB]),
    (start: 0xC000, end: 0x10000, color: rgb("#eee"),   highlight: false, label: []),
  ),
  caption: [Standard cartridge address space conventions],
)

Remember that these are just conventions. _A custom cartridge could do anything with the reads and writes it sees targeting these areas_: for example, it could use #hex-range("0000", "7FFF") for RAM, split ROM into tiny switchable 1 KiB banks, or map custom registers to any address. The only requirement is that the cartridge follows the simple parallel bus "protocol" of reacting to accesses in the cartridge areas and never responding to others.
