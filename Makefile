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
	@printf "USAGE: make <solution|usage|[...]>\n"

.PHONY: solution
solution: toolchain

.PHONY: restore
restore:
	@mkdir -p $(ELDS)/toolchain/tarballs
	@if [ -d $(ELDS_ARCHIVE)/toolchain/tarballs ]; then \
		for f in $(ELDS_TOOLCHAIN_SOURCES); do \
			if [ -f $(ELDS_ARCHIVE)/toolchain/tarballs/$$f ]; then \
				rsync -a $(ELDS_ARCHIVE)/toolchain/tarballs/$$f $(ELDS)/toolchain/tarballs/; \
			fi; \
		done; \
	fi

.PHONY: archive
archive:
	@mkdir -p $(ELDS_ARCHIVE)/toolchain
	@if [ -d $(ELDS)/toolchain/tarballs ]; then \
		for f in $(ELDS_TOOLCHAIN_SOURCES); do \
			rsync -a $(ELDS)/toolchain/tarballs/$$f $(ELDS_ARCHIVE)/toolchain/; \
		done; \
	fi

.PHONY: scm
scm:
	@git submodule init
	@git submodule update

%-check:
	$(call scm-check)

.PHONY: doc
doc: $(ELDS)/doc/solution.pdf

$(ELDS)/doc/solution.pdf: $(ELDS)/doc/solution.txt
	@if [ -f "$(shell which a2x)" ]; then \
		a2x -v -f pdf -L $(ELDS)/doc/solution.txt; \
	else \
		printf "***** AsciiDoc is NOT installed! *****\n"; \
		exit 1; \
	fi

.PHONY: toolchain-builder
toolchain-builder: $(ELDS)/toolchain/builder/ct-ng

$(ELDS)/toolchain/builder/ct-ng:
	@$(MAKE) crosstool-ng-check
	@if ! [ -d $(shell dirname $@) ]; then \
		mkdir -p $(ELDS)/toolchain; \
		cp -a $(ELDS_SCM)/crosstool-ng $(ELDS)/toolchain/builder; \
	fi
	@cd $(ELDS)/toolchain/builder; \
	if ! [ -f .crosstool-ng-patched ]; then \
		for f in $(shell ls $(ELDS_PATCHES)/crosstool-ng/*.patch); do \
			patch -p1 < $$f; \
		done; \
		touch .crosstool-ng-patched; \
	fi; \
	./bootstrap; \
	./configure --enable-local; \
	$(MAKE)
	@if ! [ -f $@ ]; then \
		printf "***** crosstool-NG build FAILED! *****\n"; \
		exit 2; \
	fi

.PHONY: toolchain-config
toolchain-config: $(ELDS_TOOLCHAIN_CONFIG)

$(ELDS_TOOLCHAIN_CONFIG): $(BOARD_TOOLCHAIN_CONFIG)
	@mkdir -p $(ELDS_TOOLCHAIN_BUILD)
	@rsync -a $(BOARD_TOOLCHAIN_CONFIG) $(ELDS_TOOLCHAIN_CONFIG)

.PHONY: toolchain
toolchain: $(ELDS_TOOLCHAIN_TARGETS)

$(ELDS_TOOLCHAIN_TARGETS):
	@$(MAKE) linux-check
	@if ! [ "$(ELDS_KERNEL_VERSION)" = "$(ELDS_KERNEL_SCM_VERSION)" ]; then \
		printf "***** WARNING KERNEL HAS DIFFERENT VERSION *****"; \
		sleep 3; \
	fi
	@$(MAKE) toolchain-builder
	@$(MAKE) toolchain-build
	@$(MAKE) archive

toolchain-%: restore $(ELDS_TOOLCHAIN_CONFIG)
	@cd $(ELDS_TOOLCHAIN_BUILD) && CT_ARCH=$(ELDS_ARCH) ct-ng $(*F)
	@rsync -a $(ELDS_TOOLCHAIN_CONFIG) $(BOARD_TOOLCHAIN_CONFIG)

.PHONY: clean
clean: archive
	$(RM) $(ELDS)/doc/solution.pdf

.PHONY: distclean
distclean: clean
	$(RM) $(ELDS)/toolchain/$(ELDS_CROSS_TUPLE)
	$(RM) $(ELDS)/toolchain/build/$(ELDS_CROSS_TUPLE)
