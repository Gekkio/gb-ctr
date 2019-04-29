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
  INPUTS config.tex xx-dma.tex xx-external-bus.tex xx-instruction-set.tex xx-mbc1.tex xx-mbc2.tex xx-mbc3.tex xx-mbc30.tex xx-mbc5.tex xx-memory-map.tex xx-opcode-tables.tex code-snippets/mbc1_dump.py
  CONFIGURE config.tex
  BIBFILES gbctr.bib)
