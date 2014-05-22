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
solution: toolchain

.PHONY: restore
restore:
	@mkdir -p $(ELDS)/toolchain/tarballs
	@if [ -d $(ELDS_ARCHIVE)/toolchain/tarballs ]; then \
		for f in $(ELDS_TOOLCHAIN_SOURCES); do \
			if ! [ -f $(ELDS)/toolchain/tarballs/$$f ]; then \
				rsync -a $(ELDS_ARCHIVE)/toolchain/tarballs/$$f $(ELDS)/toolchain/tarballs/; \
			fi; \
		done; \
	fi

.PHONY: archive
archive:
	@mkdir -p $(ELDS_ARCHIVE)/toolchain
	@if [ -d $(ELDS)/toolchain/tarballs ]; then \
		rsync -a $(ELDS)/toolchain/tarballs $(ELDS_ARCHIVE)/toolchain/; \
	fi

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

.PHONY: toolchain-config
toolchain-config: $(ELDS_TOOLCHAIN_CONFIG)

$(ELDS_TOOLCHAIN_CONFIG):
	@mkdir -p $(ELDS_TOOLCHAIN_BUILD)
	@if ! [ -f $(ELDS_TOOLCHAIN_CONFIG) ]; then \
		rsync -a $(BOARD_TOOLCHAIN_CONFIG) $(ELDS_TOOLCHAIN_CONFIG); \
	fi

.PHONY: toolchain
toolchain: $(ELDS_TOOLCHAIN)/bin/$(ELDS_CROSS_COMPILE)gcc \
	$(ELDS_TOOLCHAIN)/bin/$(ELDS_CROSS_COMPILE)gdb \
	$(ELDS_TOOLCHAIN)/$(ELDS_CROSS_TUPLE)/debug-root/usr/bin/gdbserver \
	$(ELDS_TOOLCHAIN)/$(ELDS_CROSS_TUPLE)/debug-root/usr/bin/strace

$(ELDS_TOOLCHAIN)/bin/$(ELDS_CROSS_COMPILE)gcc \
$(ELDS_TOOLCHAIN)/bin/$(ELDS_CROSS_COMPILE)gdb \
$(ELDS_TOOLCHAIN)/$(ELDS_CROSS_TUPLE)/debug-root/usr/bin/gdbserver \
$(ELDS_TOOLCHAIN)/$(ELDS_CROSS_TUPLE)/debug-root/usr/bin/strace: restore toolchain-config
	@$(MAKE) toolchain-build
	@$(MAKE) archive

toolchain-%: toolchain-builder toolchain-config
	@cd $(ELDS_TOOLCHAIN_BUILD) && CT_ARCH=$(ELDS_ARCH) ct-ng $(*F)
	@rsync -a $(ELDS_TOOLCHAIN_CONFIG) $(BOARD_TOOLCHAIN_CONFIG)

.PHONY: clean
clean: archive
	$(RM) $(ELDS)/doc/solution.pdf
