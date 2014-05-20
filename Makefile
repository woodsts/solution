#
# This is the GNU Make Makefile for 'solution'
#
# Copyright (C) 2014 Derald D. Woods
#
# This file is part of the solution project, and is made available
# under the terms of the GNU General Public License version 2
#

include solution.mk

.PHONY: all
all: usage

.PHONY: usage
usage:
	@echo "USAGE: make <solution|usage|[...]>"

.PHONY: solution
solution:

.PHONY: scm
scm:
	@if ! [ -f $(ELDS_SCM)/linux/.git ]; then \
		$(MAKE) scm-init; \
	fi
	@$(MAKE) scm-update

scm-%:
	@git submodule $(*F)

.PHONY: doc
doc: $(ELDS)/doc/solution.pdf

$(ELDS)/doc/solution.pdf: $(ELDS)/doc/solution.txt
	@if [ -f "$(shell which a2x)" ]; then \
		a2x -v -f pdf -L $(ELDS)/doc/solution.txt; \
	else \
		echo "***** AsciiDoc is NOT installed! *****"; \
		exit 1; \
	fi

.PHONY: clean
clean:
	$(RM) $(ELDS)/doc/solution.pdf
