#import "../../common.typ": *

== Introduction

The original Game Boy and its successors were the most popular and financially successful handheld consoles in the 1990s and early 2000s with several millions units sold and a large catalogue of officially published games. Unlike many older consoles, Game Boys use only a single integrated System-on-a-Chip (SoC) for almost everything, and this SoC includes the processor (CPU) core, some memories, and various peripherals.

#caveat[
  The Game Boy SoC is sometimes called the "CPU", even though it has a large amount of other peripherals as well. For example, the Game Boy Pocket SoC literally has the text "CPU MGB" on it, even though the CPU core takes only a small fraction of the entire chip area. This terminology is therefore misleading, and is like calling a computer motherboard and all connected expansion cards and storage devices the "CPU".

  This document always makes a clear distiction between the entire chip (SoC) and the processor inside it (the CPU _core_).
]

Most Game Boy consoles are handhelds, starting from the original Game Boy in 1989, ending with the Game Boy Micro in 2005. In addition to handheld devices, Game Boy SoCs are also used in some accessories meant for other consoles, such as the Super Game Boy for the SNES/SFC.

Game Boy consoles and their SoCs can be categorized based on three supported technical architectures:

- GB: the original Game Boy architecture with a Sharp SM83 CPU core and 4-level grayscale graphics
- GBC: a mostly backwards compatible extension to the GB architecture that adds color graphics and small improvements
- GBA: a completely different architecture based on the ARM processor instruction set and a completely redesigned set of peripherals. *This document does not cover GBA architecture, because it has little in common with GB/GBC*. GBA-based consoles and chips are only mentioned for their backwards compatibility with GB/GBC architectures.

@console-summary lists all officially released Game Boy consoles, including handhelds and accessories for other consoles. Every model has an internal codename, such as original Game Boy's codename Dot Matrix Game (DMG), that is also present on the mainboard.

#caveat[
  This document refers to different console models usually by their unique codename to prevent confusion. For example, using the abbreviation GBP could refer to either Game Boy Pocket or Game Boy Player, but there's no confusion when MGB and GBS are used instead.

  In this document GBC refers to the technical architecture, while CGB refers to Game Boy Color consoles specifically. Likewise, GBA refers to the architecture and AGB to exactly one console model.
]

#figure(
  table(
    columns: 6,
    align: left,
    table.header(
      [*Console name*], [*Codename*], [*SoC type*], [*GB*], [*GBC*], [*GBA*],
    ),
    table.cell(colspan: 6)[_Handhelds_],
    [Game Boy], [DMG], [DMG-CPU], [✓], [], [],
    [Game Boy Pocket], [MGB], [CPU MGB], [✓], [], [],
    [Game Boy Light], [MGL], [CPU MGB], [✓], [], [],
    [Game Boy Color], [CGB], [CPU CGB], [✓], [✓], [],
    [Game Boy Advance], [AGB], [CPU AGB], [✓], [✓], [✓],
    [Game Boy Advance SP], [AGS], [CPU AGB], [✓], [✓], [✓],
    [Game Boy Micro], [OXY], [CPU AGB], [], [], [✓],
    table.cell(colspan: 6)[_Accessories_],
    [Super Game Boy], [SGB], [SGB-CPU], [✓], [], [],
    [Super Game Boy 2], [SGB2], [CPU SGB2], [✓], [], [],
    [Game Boy Player], [GBS], [CPU AGB], [✓], [✓], [✓],
  ),
  caption: "Summary of Game Boy consoles"
) <console-summary>
