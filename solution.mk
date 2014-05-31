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

# Root Filesystem Definitions
ELDS_ROOTFS := $(ELDS)/rootfs/$(ELDS_BOARD)/$(ELDS_CROSS_TUPLE)
ELDS_ROOTFS_SCM := $(ELDS_SCM)/buildroot
ELDS_ROOTFS_SCM_VERSION := $(shell cd $(ELDS_ROOTFS_SCM) && git describe --long 2>/dev/null)
ELDS_ROOTFS_VERSION := $(shell cat $(ELDS_SCM)/.buildroot 2>/dev/null)
ELDS_ROOTFS_BUILD := $(ELDS_ROOTFS)
ELDS_ROOTFS_CONFIG := $(ELDS_ROOTFS)/.config
ELDS_ROOTFS_SOURCES := $(shell cat $(ELDS)/boards/$(ELDS_BOARD)/target.txt)
ELDS_ROOTFS_TARGETS := $(ELDS_ROOTFS)/images/rootfs.tar.xz \
	$(ELDS_ROOTFS)/images/rootfs.cpio.xz

# Kernel Definitions
ELDS_KERNEL_SCM := $(ELDS_SCM)/linux
ELDS_KERNEL_SCM_VERSION := $(shell cd $(ELDS_KERNEL_SCM) && git describe --long 2>/dev/null)
ELDS_KERNEL_VERSION := $(shell cat $(ELDS_SCM)/.linux 2>/dev/null)

# Misc.
ELDS_ISSUE := "Solution [$(ELDS_BOARD)]"

# Store build information
CMD := $(shell printf $(ELDS) > $(ELDS)/.solution)
CMD := $(shell printf $(ELDS_BOARD) > $(ELDS)/.board)
CMD := $(shell printf $(ELDS_CROSS_TUPLE) > $(ELDS)/.cross-tuple)

# PATH Environment
PATH := $(PATH):$(ELDS)/toolchain/builder:$(ELDS_TOOLCHAIN)/bin

# Makefile functions
define scm-check
	@if ! [ -f $(ELDS_SCM)/$(*F)/.git ]; then \
		printf "***** MISSING GIT SUBMODULES *****\n"; \
		printf "*****     RUN 'make scm'     *****\n"; \
		sleep 3; \
		exit 2; \
	fi
endef

define solution-env
	@printf "ELDS                   : $(ELDS)\n"
	@printf "ELDS_BRANCH            : $(ELDS_BRANCH)\n"
	@printf "ELDS_BOARD             : $(ELDS_BOARD)\n"
	@printf "ELDS_ISSUE             : $(ELDS_ISSUE)\n"
	$(call $(ELDS_BOARD)-env)
	@printf "ELDS_CROSS_TUPLE       : $(ELDS_CROSS_TUPLE)\n"
	@printf "ELDS_TOOLCHAIN         : $(ELDS_TOOLCHAIN)\n"
	@printf "ELDS_TOOLCHAIN_BUILD   : $(ELDS_TOOLCHAIN_BUILD)\n"
	@printf "ELDS_TOOLCHAIN_SOURCES : $(ELDS_TOOLCHAIN_SOURCES)\n"
	@printf "ELDS_TOOLCHAIN_TARGETS : $(ELDS_TOOLCHAIN_TARGETS)\n"
	@printf "ELDS_ROOTFS            : $(ELDS_ROOTFS)\n"
	@printf "ELDS_ROOTFS_BUILD      : $(ELDS_ROOTFS_BUILD)\n"
	@printf "ELDS_ROOTFS_SOURCES    : $(ELDS_ROOTFS_SOURCES)\n"
	@printf "ELDS_ROOTFS_TARGETS    : $(ELDS_ROOTFS_TARGETS)\n"
	@printf "ELDS_ARCHIVE           : $(ELDS_ARCHIVE)\n"
	@printf "PATH                   : $(PATH)\n"
endef

export ELDS
export ELDS_BOARD
export ELDS_ISSUE
export ELDS_CROSS_TUPLE

