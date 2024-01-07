#import "../../common.typ": *

== MBC30 mapper chip

MBC30 is a variant of MBC3 used by Japanese Pokemon Crystal to support a larger ROM chip and a larger RAM chip. Featurewise MBC30 is almost identical to MBC3, but supports ROM sizes up to 32 Mbit (256 banks of #hex("4000") bytes), and RAM sizes up to 512 Kbit (8 banks of #hex("2000") bytes).  Information in this section is based on my MBC30 research.

#warning[
  The circuit board of Japanese Pokemon Crystal includes a 1 Mbit RAM chip, but MBC30 is limited to 512 Kbit RAM. One of the RAM address pins is unused, so half of the RAM is wasted and is inaccessible without modifications. So, the game only uses 512 Kbit and there is a mismatch between accessible and the physical amounts of RAM.
]
