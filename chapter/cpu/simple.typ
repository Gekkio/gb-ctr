#import "../../common.typ": *

== Simple model

#figure(
  image(width: 70%, "../../images/SM83-simple.svg"),
  caption: "Simple model of the SM83 CPU core"
) <sm83-simple>

@sm83-simple shows a simplified model of the SM83 CPU core. The core interacts with the rest of the SoC using interrupt signals, an 8-bit bidirectional data bus, and a 16-bit address bus controlled by the CPU core.

The main subsystems of the CPU core are as follows:

#grid(columns: 2, gutter: 12pt,
  [*Control unit*], [
    The control unit decodes the executed instructions and generates control signals for the rest of the CPU core. It is also responsible for checking and dispatching interrupts.
  ],
  [*Register file*], [
    The register file holds most of the state of the CPU inside registers. It contains the 16-bit Program Counter (PC), the 16-bit Stack Pointer (SP), the 8-bit Accumulator (A), the Flags register (F), general-purpose register pairs consisting of two 8-bit halves such as BC, DE, HL, and the special-purpose 8-bit registers Instruction Register (IR) and Interrupt Enable (IE).
  ],
  [*ALU*], [
    An 8-bit Arithmetic Logic Unit (ALU) has two 8-bit input ports and is capable of performing various calculations. The ALU outputs its result either to the register file or the CPU data bus.
  ],
  [*IDU*], [
    A dedicated 16-bit Increment/Decrement Unit (IDU) is capable of performing only simple increment/decrement operations on the 16-bit address bus value, but they can be performed independently of the ALU, improving maximum performance of the CPU core. The IDU always outputs its result back to the register file, where it can be written to a register pair or a 16-bit register.
  ]
)
