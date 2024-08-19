#import "../../common.typ": *

== Introduction

The CPU core in the Game Boy SoC is a custom Sharp design that hasn't publicly been given a name by either Sharp or Nintendo. However, using old Sharp datasheets and databooks as evidence, the core has been identified to be a Sharp *SM83* CPU core, or at least something that is 100% compatible with it. SM83 is a custom CPU core used in some custom Application Specific Integrated Chips (ASICs) manufactured by Sharp in the 1980s and 1990s.

#warning[
  Some sources claim Game Boy uses a "modified" Zilog Z80 or Intel 8080 CPU core. While the SM83 resembles both and has many identical instructions, it can't execute all Z80/8080 programs, and finer details such as timing of instructions often differ.
]

SM83 is an 8-bit CPU core with a 16-bit address bus. The Instruction Set Architecture (ISA) is based on both Z80 and 8080, and is close enough to Z80 that programmers familiar with Z80 assembly can quickly become productive with SM83 as well. Some Z80 programs may also work directly on SM83, assuming only opcodes supported by both are used and the program is not sensitive to timing differences.

#speculation[
  Sharp most likely designed SM83 to closely resemble Z80, so it would be easy for programmers already familiar with the widely popular Z80 to write programs for it. However, SM83 is not a "modified Z80" because the internal implementation is completely different. At the time Sharp also manufactured real Z80 chips such as LH0080 under a license from Zilog, so they were familiar with Z80 internals but did not directly copy the actual implementation of the CPU core. If you compare photos of a decapped Z80 chip and a GB SoC, you will see two very different-looking CPU cores.
]

=== History

The first known mention of the SM83 CPU core is in Sharp Microcomputers Data Book (1990), where it is listed as the CPU core used in the SM8320 8-bit microcomputer chip, intended for inverter air conditioners @sharp_microcomputers_1990. The data book describes some details of the CPU core, such as a high-level overview of the supported instructions, but precise details such as full opcode tables are not included. Another CPU core called SM82 is also mentioned, but based on the details it's clearly a completely different one.

The SM83 CPU core later appeared in Sharp Microcomputer Data Book (1996), where it is listed as the CPU core in the SM8311/SM8313/SM8314/SM8315 8-bit microcomputer chips, meant for home appliances @sharp_microcomputers_1996. This data book describes the CPU core in much more detailed manner, and other than some mistakes in the descriptions, the details seem to match what is known about the GB SoC CPU core from other sources.
