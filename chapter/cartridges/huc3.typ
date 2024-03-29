#import "../../common.typ": *

== HuC-3 mapper chip

HuC-3 supports ROM sizes up to 16 Mbit (128 banks of #hex("4000") bytes), and RAM
sizes up to 1 Mbit (16 banks of #hex("2000") bytes). Like HuC-1, it includes
support for infrared communication, but also includes a real-time-clock (RTC)
and output pins used to control a piezoelectric buzzer. The information in this
section is based on my HuC-3 research.
