#import "../../common.typ": *

== Memory buses

=== Undriven bus values <undriven-bus>

In a memory bus, a read request might not get any response and some or all data bits are *undriven* because no device on the bus is strongly driving them to any value. For example, maybe no cartridge is inserted, or the SoC is attempting to read a disabled cartridge RAM or a register that does not exist in the system. This raises the question: what does the device initiating the read see for each undriven bit?

==== External system bus

The Game Boy SoC has pull-up resistors on the external system bus data lines, so each data bit gets pulled towards a #bit[1] bit when undriven. However, this change is not instant and the different data bits change independently, so in scenarios where some data bus bits are driven low and then become no longer driven, there's a period of time when non-deterministic values can be read. This does not mean the values are completely random, since a #bit[0] bit gets pulled towards #bit[1], but bits that are already #bit[1] do not change. Therefore an undriven read returns 1 bits unless some bits were driven low shortly before, and those previously low bits can be seen as 0 or 1.

==== Internal system bus

The Game Boy SoC uses a precharge mechanism to raise each internal system bus data line to a #bit[1] bit at the start of each M-cycle, so if a data bit is undriven during a read later during the same M-cycle, each bit will read as #bit[1]. Small leakage currents cause every bit to slowly decay to #bit[0] when undriven, but bus capacitance in the SoC makes this so slow that under normal clock speeds it does not decay enough before the next M-cycle precharges the bus again. In special circumstances, for example if the system clock is lowered greatly by a hardware modification, or if the SoC test pins are being used, it's possible that a precharged bit has been drained into a #bit[0] bit when a read happens.
