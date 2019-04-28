TARGET := gbctr
PDFLATEX ?= xelatex -shell-escape -halt-on-error

ifeq ($(TRAVIS_BRANCH),master)
REVISION := "$(shell git rev-list --count master)"
DRAFT := 0
else
REVISION := "$(shell git symbolic-ref --short HEAD)-$(shell git rev-list --count HEAD)[$(shell git rev-parse --short HEAD)]"
DRAFT := 1
endif

REVDEPS += config.tex

include third-party/pdflatex-makefile/Makefile.include

config.tex:
	@echo '\\newcount\\draft\\draft='"${DRAFT}" > config.tex
