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
		$(MAKE) scm-update; \
	fi

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

.PHONY: toolchain-builder
toolchain-builder: $(ELDS)/toolchain/builder/ct-ng

$(ELDS)/toolchain/builder/ct-ng: scm
	@if ! [ -d $(shell dirname $@) ]; then \
		mkdir -p $(ELDS)/toolchain; \
		cp -a $(ELDS_SCM)/crosstool-ng $(ELDS)/toolchain/builder; \
		cd $(ELDS)/toolchain/builder; \
		for f in $(shell ls $(ELDS_PATCHES)/crosstool-ng/*.patch); do \
			patch -p1 < $$f; \
		done; \
		./bootstrap; \
		./configure --enable-local; \
		$(MAKE); \
	fi
	@if ! [ -f $@ ]; then \
		echo "***** crosstool-NG build FAILED! *****"; \
		exit 2; \
	fi

.PHONY: clean
clean:
	$(RM) $(ELDS)/doc/solution.pdf
