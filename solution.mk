#
# This is the GNU Make include file for 'solution'
#
# Copyright (C) 2014 Derald D. Woods
#
# This file is part of the solution project, and is made available
# under the terms of the GNU General Public License version 2
#
# References:
#
# ARM Linux [http://www.arm.linux.org.uk/docs/kerncomp.php]
#

ELDS := $(shell readlink -e $(CURDIR))
ELDS_BRANCH := $(shell git branch|grep '*'|cut -d ' ' -f 2)

# Directory Definitions
ELDS_SCM := $(ELDS)/scm
ELDS_PATCHES := $(ELDS)/patches
ELDS_ARCHIVE ?= $(HOME)/Public

# Read the Embedded Board Definitions
ifeq ($(ELDS_BRANCH),master)
ELDS_BOARD ?= versatile-pb
else
ELDS_BOARD := $(ELDS_BRANCH)
endif
include $(ELDS)/boards/$(ELDS_BOARD)/solution.mk

# Toolchain Definitions
ELDS_CROSS_TUPLE := $(ELDS_ARCH)$(ELDS_VENDOR)-$(ELDS_OS)-$(ELDS_ABI)
ELDS_CROSS_COMPILE := $(ELDS_CROSS_TUPLE)-
ELDS_CROSS_PARAMS := ARCH=$(ELDS_ARCH) CROSS_COMPILE=$(ELDS_CROSS_COMPILE)
ELDS_TOOLCHAIN := $(ELDS)/toolchain/$(ELDS_CROSS_TUPLE)
ELDS_TOOLCHAIN_BUILD := $(ELDS)/toolchain/build/$(ELDS_CROSS_TUPLE)
ELDS_TOOLCHAIN_CONFIG := $(ELDS_TOOLCHAIN_BUILD)/.config
ELDS_TOOLCHAIN_SOURCES := $(shell cat $(ELDS)/common/toolchain.txt)
ELDS_TOOLCHAIN_TARGETS := $(ELDS_TOOLCHAIN)/bin/$(ELDS_CROSS_COMPILE)gcc \
	$(ELDS_TOOLCHAIN)/bin/$(ELDS_CROSS_COMPILE)gdb \
	$(ELDS_TOOLCHAIN)/$(ELDS_CROSS_TUPLE)/debug-root/usr/bin/gdbserver \
	$(ELDS_TOOLCHAIN)/$(ELDS_CROSS_TUPLE)/debug-root/usr/bin/strace

# Kernel Definitions
ELDS_KERNEL_SCM := $(ELDS_SCM)/linux
ELDS_KERNEL_SCM_VERSION := $(shell cd $(ELDS_KERNEL_SCM) && git describe --long 2>/dev/null)
ELDS_KERNEL_VERSION := $(shell cat $(ELDS_SCM)/.linux 2>/dev/null)

# Store build information
CMD := $(shell printf $(ELDS) > $(ELDS)/.solution)
CMD := $(shell printf $(ELDS_BOARD) > $(ELDS)/.board)
CMD := $(shell printf $(ELDS_CROSS_TUPLE) > $(ELDS)/.cross-tuple)

# Makefile functions
define scm-check
	@if ! [ -f $(ELDS_SCM)/$(*F)/.git ]; then \
		printf "***** MISSING GIT SUBMODULES *****\n"; \
		printf "*****     RUN 'make scm'     *****\n"; \
		sleep 3; \
		exit 2; \
	fi
endef

PATH := $(PATH):$(ELDS)/toolchain/builder:$(ELDS_TOOLCHAIN)/bin

export ELDS
export ELDS_BOARD
export ELDS_CROSS_TUPLE
