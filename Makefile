TARGET := gbctr

ifeq ($(TRAVIS_BRANCH),master)
REVISION := "$(shell git rev-list --count master)"
else
REVISION := "$(shell git symbolic-ref --short HEAD)-$(shell git rev-list --count HEAD)[$(shell git rev-parse --short HEAD)]"
endif


include third-party/pdflatex-makefile/Makefile.include
