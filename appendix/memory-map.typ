#import "../common.typ": *

#let detail(..args) = text(7pt, ..args)

#let gbc-bit(content) = cellx(fill: rgb("#FFFFED"), content)
#let gbc-bits(length, content) = colspanx(length, fill: rgb("#FFFFED"), content)

#let unmapped-bit = cellx(fill: rgb("#D3D3D3"))[]
#let unmapped-bits(length) = range(length).map((_) => unmapped-bit)
#let unmapped-byte = colspanx(8, fill: rgb("D3D3D3"))[]
#let todo(length) = range(length).map((_) => [])
#set text(9pt)

== Memory map tables

#set page(flipped: true)

#figure(
  tablex(
    columns: (auto, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
    inset: (x: 5pt, y: 3.5pt),
    align: (left, center, center, center, center, center, center, center, center),
    [], [bit 7], [6], [5], [4], [3], [2], [1], [bit 0],
    [#hex("FF00") P1], ..unmapped-bits(2), [P15 #detail[buttons]], [P14 #detail[d-pad]], [P13 #detail[#awesome("\u{f358}") start]], [P12 #detail[#awesome("\u{f35b}") select]], [P11 #detail[#awesome("\u{f359}") B]], [P10 #detail[#awesome("\u{f35a}") A]],
    [#hex("FF01") SB], colspanx(8)[SB\<7:0\>],
    [#hex("FF02") SC], [SIO_EN], ..unmapped-bits(5), gbc-bit[SIO_FAST], [SIO_CLK],
    hex("FF03"), unmapped-byte,
    [#hex("FF04") DIV], colspanx(8)[DIVH\<7:0\>],
    [#hex("FF05") TIMA], colspanx(8)[TIMA\<7:0\>],
    [#hex("FF06") TMA], colspanx(8)[TMA\<7:0\>],
    [#hex("FF07") TAC], ..unmapped-bits(5), [TAC_EN], colspanx(2)[TAC_CLK\<1:0\>],
    hex("FF08"), unmapped-byte,
    hex("FF09"), unmapped-byte,
    hex("FF0A"), unmapped-byte,
    hex("FF0B"), unmapped-byte,
    hex("FF0C"), unmapped-byte,
    hex("FF0D"), unmapped-byte,
    hex("FF0E"), unmapped-byte,
    [#hex("FF0F") IF], ..unmapped-bits(3), [IF_JOYPAD], [IF_SERIAL], [IF_TIMER], [IF_STAT], [IF_VBLANK],
    [#hex("FF10") NR10], ..todo(8),
    [#hex("FF11") NR11], ..todo(8),
    [#hex("FF12") NR12], ..todo(8),
    [#hex("FF13") NR13], ..todo(8),
    [#hex("FF14") NR14], ..todo(8),
    hex("FF15"), unmapped-byte,
    [#hex("FF16") NR21], ..todo(8),
    [#hex("FF17") NR22], ..todo(8),
    [#hex("FF18") NR23], ..todo(8),
    [#hex("FF19") NR24], ..todo(8),
    [#hex("FF1A") NR30], ..todo(8),
    [#hex("FF1B") NR31], ..todo(8),
    [#hex("FF1C") NR32], ..todo(8),
    [#hex("FF1D") NR33], ..todo(8),
    [#hex("FF1E") NR34], ..todo(8),
    hex("FF1F"), unmapped-byte,
    [], [bit 7], [6], [5], [4], [3], [2], [1], [bit 0],
  ),
  kind: table,
  caption: [#hex[FFxx] registers: #hex-range("FF00", "FF1F")]
)

#pagebreak()

#figure(
  tablex(
    columns: (auto, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
    inset: (x: 5pt, y: 3.5pt),
    align: (left, center, center, center, center, center, center, center, center),
    [], [bit 7], [6], [5], [4], [3], [2], [1], [bit 0],
    [#hex("FF20") NR41], ..todo(8),
    [#hex("FF21") NR42], ..todo(8),
    [#hex("FF22") NR43], ..todo(8),
    [#hex("FF23") NR44], ..todo(8),
    [#hex("FF24") NR50], ..todo(8),
    [#hex("FF25") NR51], ..todo(8),
    [#hex("FF26") NR52], ..todo(8),
    hex("FF27"), unmapped-byte,
    hex("FF28"), unmapped-byte,
    hex("FF29"), unmapped-byte,
    hex("FF2A"), unmapped-byte,
    hex("FF2B"), unmapped-byte,
    hex("FF2C"), unmapped-byte,
    hex("FF2D"), unmapped-byte,
    hex("FF2E"), unmapped-byte,
    hex("FF2F"), unmapped-byte,
    [#hex("FF30") WAV00], ..todo(8),
    [#hex("FF31") WAV01], ..todo(8),
    [#hex("FF32") WAV02], ..todo(8),
    [#hex("FF33") WAV03], ..todo(8),
    [#hex("FF34") WAV04], ..todo(8),
    [#hex("FF35") WAV05], ..todo(8),
    [#hex("FF36") WAV06], ..todo(8),
    [#hex("FF37") WAV07], ..todo(8),
    [#hex("FF38") WAV08], ..todo(8),
    [#hex("FF39") WAV09], ..todo(8),
    [#hex("FF3A") WAV10], ..todo(8),
    [#hex("FF3B") WAV11], ..todo(8),
    [#hex("FF3C") WAV12], ..todo(8),
    [#hex("FF3D") WAV13], ..todo(8),
    [#hex("FF3E") WAV14], ..todo(8),
    [#hex("FF3F") WAV15], ..todo(8),
    [], [bit 7], [6], [5], [4], [3], [2], [1], [bit 0],
  ),
  kind: table,
  caption: [#hex[FFxx] registers: #hex-range("FF20", "FF3F")]
)

#pagebreak()

#figure(
  tablex(
    columns: (auto, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
    inset: (x: 5pt, y: 3.5pt),
    align: (left, center, center, center, center, center, center, center, center),
    [], [bit 7], [6], [5], [4], [3], [2], [1], [bit 0],
    [#hex("FF40") LCDC], [LCD_EN], [WIN_MAP], [WIN_EN], [TILE_SEL], [BG_MAP], [OBJ_SIZE], [OBJ_EN], [BG_EN],
    [#hex("FF41") STAT], unmapped-bit, [INTR_LYC], [INTR_M2], [INTR_M1], [INTR_M0], [LYC_STAT], colspanx(2)[LCD_MODE\<1:0\>],
    [#hex("FF42") SCY], ..todo(8),
    [#hex("FF43") SCX], ..todo(8),
    [#hex("FF44") LY], ..todo(8),
    [#hex("FF45") LYC], ..todo(8),
    [#hex("FF46") DMA], colspanx(8)[DMA\<7:0\>],
    [#hex("FF47") BGP], ..todo(8),
    [#hex("FF48") OBP0], ..todo(8),
    [#hex("FF49") OBP1], ..todo(8),
    [#hex("FF4A") WY], ..todo(8),
    [#hex("FF4B") WX], ..todo(8),
    gbc-bit[#hex("FF4C") ????], ..todo(8),
    gbc-bit[#hex("FF4D") KEY1], gbc-bit[KEY1_FAST], ..unmapped-bits(6), gbc-bit[KEY1_EN],
    hex("FF4E"), unmapped-byte,
    gbc-bit[#hex("FF4F") VBK], ..unmapped-bits(6), gbc-bits(2)[VBK\<1:0\>],
    [#hex("FF50") BOOT], ..unmapped-bits(7), [BOOT_OFF],
    gbc-bit[#hex("FF51") HDMA1], ..todo(8),
    gbc-bit[#hex("FF52") HDMA2], ..todo(8),
    gbc-bit[#hex("FF53") HDMA3], ..todo(8),
    gbc-bit[#hex("FF54") HDMA4], ..todo(8),
    gbc-bit[#hex("FF55") HDMA5], ..todo(8),
    gbc-bit[#hex("FF56") RP], ..todo(8),
    hex("FF57"), unmapped-byte,
    hex("FF58"), unmapped-byte,
    hex("FF59"), unmapped-byte,
    hex("FF5A"), unmapped-byte,
    hex("FF5B"), unmapped-byte,
    hex("FF5C"), unmapped-byte,
    hex("FF5D"), unmapped-byte,
    hex("FF5E"), unmapped-byte,
    hex("FF5F"), unmapped-byte,
    [], [bit 7], [6], [5], [4], [3], [2], [1], [bit 0],
  ),
  kind: table,
  caption: [#hex[FFxx] registers: #hex-range("FF40", "FF5F")]
)

#pagebreak()

#figure(
  tablex(
    columns: (auto, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
    inset: (x: 5pt, y: 3.5pt),
    align: (left, center, center, center, center, center, center, center, center),
    [], [bit 7], [6], [5], [4], [3], [2], [1], [bit 0],
    [#hex("FF60") ????], ..unmapped-bits(6), [], [],
    hex("FF61"), unmapped-byte,
    hex("FF62"), unmapped-byte,
    hex("FF63"), unmapped-byte,
    hex("FF64"), unmapped-byte,
    hex("FF65"), unmapped-byte,
    hex("FF66"), unmapped-byte,
    hex("FF67"), unmapped-byte,
    gbc-bit[#hex("FF68") BCPS], ..todo(8),
    gbc-bit[#hex("FF69") BPCD], ..todo(8),
    gbc-bit[#hex("FF6A") OCPS], ..todo(8),
    gbc-bit[#hex("FF6B") OCPD], ..todo(8),
    gbc-bit[#hex("FF6C") ????], ..todo(8),
    hex("FF6D"), unmapped-byte,
    hex("FF6E"), unmapped-byte,
    hex("FF6F"), unmapped-byte,
    gbc-bit[#hex("FF70") SVBK], ..unmapped-bits(6), gbc-bits(2)[SVBK\<1:0\>],
    hex("FF71"), unmapped-byte,
    gbc-bit[#hex("FF72") ????], ..todo(8),
    gbc-bit[#hex("FF73") ????], ..todo(8),
    gbc-bit[#hex("FF74") ????], ..todo(8),
    gbc-bit[#hex("FF75") ????], ..todo(8),
    gbc-bit[#hex("FF76") PCM12], gbc-bits(4)[PCM12_CH2], gbc-bits(4)[PCM12_CH1],
    gbc-bit[#hex("FF77") PCM34], gbc-bits(4)[PCM34_CH4], gbc-bits(4)[PCM34_CH3],
    hex("FF78"), unmapped-byte,
    hex("FF79"), unmapped-byte,
    hex("FF7A"), unmapped-byte,
    hex("FF7B"), unmapped-byte,
    hex("FF7C"), unmapped-byte,
    hex("FF7D"), unmapped-byte,
    hex("FF7E"), unmapped-byte,
    hex("FF7F"), unmapped-byte,
    [#hex("FFFF") IE], colspanx(3)[IE_UNUSED\<2:0\>], [IE_JOYPAD], [IE_SERIAL], [IE_TIMER], [IE_STAT], [IE_VBLANK],
    [], [bit 7], [6], [5], [4], [3], [2], [1], [bit 0],
  ),
  kind: table,
  caption: [#hex[FFxx] registers: #hex-range("FF60", "FF7F"), #hex("FFFF")]
)
