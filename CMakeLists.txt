cmake_minimum_required(VERSION 2.8.4)

project(gbctr)

set(LATEX_OUTPUT_PATH build)
set(PDFLATEX_COMPILER xelatex)
set(LATEX_COMPILER_FLAGS "-interaction=batchmode -file-line-error -shell-escape" CACHE STRING "Flags passed to latex")

find_package(Git QUIET REQUIRED)

set(DRAFT 1)
if(DEFINED ENV{TRAVIS_BRANCH})
  if($ENV{TRAVIS_BRANCH} STREQUAL "master")
    set(DRAFT 0)
  endif()
endif()

if(${DRAFT} EQUAL 1)
  execute_process(
      COMMAND "${GIT_EXECUTABLE}" symbolic-ref --short HEAD
      WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
      OUTPUT_VARIABLE REVISION_SYMBOLIC
      OUTPUT_STRIP_TRAILING_WHITESPACE)
  execute_process(
      COMMAND "${GIT_EXECUTABLE}" rev-list --count HEAD
      WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
      OUTPUT_VARIABLE REVISION_COUNT
      OUTPUT_STRIP_TRAILING_WHITESPACE)
  execute_process(
      COMMAND "${GIT_EXECUTABLE}" rev-parse --short HEAD
      WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
      OUTPUT_VARIABLE REVISION_HASH
      OUTPUT_STRIP_TRAILING_WHITESPACE)
  set(REVISION ${REVISION_SYMBOLIC}-${REVISION_COUNT}[${REVISION_HASH}])
else()
  execute_process(
      COMMAND "${GIT_EXECUTABLE}" rev-list --count master
      WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
      OUTPUT_VARIABLE REVISION
      OUTPUT_STRIP_TRAILING_WHITESPACE)
endif()

include(third-party/UseLATEX.cmake)

add_latex_document(gbctr.tex
  INPUTS
    config.tex
    chapter/cpu/instruction-set.tex
    chapter/peripherals/boot-rom.tex
    chapter/peripherals/dma.tex
    chapter/peripherals/ppu.tex
    chapter/peripherals/p1.tex
    chapter/peripherals/serial.tex
    chapter/cartridges/huc1.tex
    chapter/cartridges/huc3.tex
    chapter/cartridges/mbc1.tex
    chapter/cartridges/mbc2.tex
    chapter/cartridges/mbc3.tex
    chapter/cartridges/mbc30.tex
    chapter/cartridges/mbc5.tex
    chapter/cartridges/mbc6.tex
    chapter/cartridges/mbc7.tex
    chapter/cartridges/mmm01.tex
    chapter/cartridges/tama5.tex
    appendix/external-bus.tex
    appendix/memory-map.tex
    appendix/opcode-tables.tex
    appendix/pinouts.tex
    code-snippets/mbc1_rom_dump.py
    code-snippets/mbc2_rom_dump.py
    images/DMG-CPU-pinout.pdf
    images/MGB-CPU-pinout.pdf
    images/MBC1-pinout.pdf
    images/MBC2-pinout.pdf
    images/MBC5-pinout.pdf
  CONFIGURE config.tex
  BIBFILES gbctr.bib)
