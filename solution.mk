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
ELDS_BOARD ?= versatile-pb

# Directory Definitions
ELDS_SCM := $(ELDS)/scm
ELDS_PATCHES := $(ELDS)/patches
ELDS_ARCHIVE ?= $(HOME)/Public

# Read the Embedded Board Definitions
include $(ELDS)/boards/$(ELDS_BOARD)/solution.mk

# Cross-Compilation Definitions
ELDS_CROSS_TUPLE := $(BOARD_ARCH)$(BOARD_VENDOR)-$(BOARD_OS)-$(BOARD_ABI)
ELDS_CROSS_COMPILE := $(ELDS_CROSS_TUPLE)-
ELDS_CROSS_PARAMS := ARCH=$(BOARD_ARCH) CROSS_COMPILE=$(ELDS_CROSS_COMPILE)

# Toolchain Definitions
ELDS_TOOLCHAIN := crosstool-NG
ELDS_TOOLCHAIN_SCM := $(ELDS_SCM)/crosstool-ng
ELDS_TOOLCHAIN_SCM_VERSION := $(shell cat $(ELDS_SCM)/.crosstool-ng 2>/dev/null)
ELDS_TOOLCHAIN_GIT_VERSION := $(shell cd $(ELDS_TOOLCHAIN_SCM) 2>/dev/null && git describe --tags --long 2>/dev/null)
ELDS_TOOLCHAIN_VERSION := $(shell cd $(ELDS_TOOLCHAIN_SCM) 2>/dev/null && git describe --tags 2>/dev/null)
ELDS_TOOLCHAIN_PATH := $(ELDS)/toolchain/$(ELDS_CROSS_TUPLE)
ELDS_TOOLCHAIN_BUILD := $(ELDS)/toolchain/build/$(ELDS_CROSS_TUPLE)
ELDS_TOOLCHAIN_BUILDER := $(ELDS)/toolchain/builder
ELDS_TOOLCHAIN_CONFIG := $(ELDS_TOOLCHAIN_BUILD)/.config
ELDS_TOOLCHAIN_SOURCES := $(shell cat $(ELDS)/common/toolchain.txt)
ELDS_TOOLCHAIN_TARGETS := $(ELDS_TOOLCHAIN_PATH)/bin/$(ELDS_CROSS_COMPILE)gcc \
	$(ELDS_TOOLCHAIN_PATH)/bin/$(ELDS_CROSS_COMPILE)gdb \
	$(ELDS_TOOLCHAIN_PATH)/$(ELDS_CROSS_TUPLE)/debug-root/usr/bin/gdbserver \
	$(ELDS_TOOLCHAIN_PATH)/$(ELDS_CROSS_TUPLE)/debug-root/usr/bin/strace

# Root Filesystem Definitions
ELDS_ROOTFS := Buildroot
ELDS_ROOTFS_SCM := $(ELDS_SCM)/buildroot
ELDS_ROOTFS_SCM_VERSION := $(shell cat $(ELDS_SCM)/.buildroot 2>/dev/null)
ELDS_ROOTFS_GIT_VERSION := $(shell make --quiet -C $(ELDS_ROOTFS_SCM) print-version 2>/dev/null)
ELDS_ROOTFS_VERSION := $(shell cd $(ELDS_ROOTFS_SCM) 2>/dev/null && make print-version 2>/dev/null)
ELDS_ROOTFS_BUILD := $(ELDS)/rootfs/$(BOARD_TYPE)/$(ELDS_CROSS_TUPLE)
ELDS_ROOTFS_CONFIG := $(ELDS_ROOTFS_BUILD)/.config
ELDS_ROOTFS_SOURCES := $(shell cat $(ELDS)/common/rootfs.txt)
ELDS_ROOTFS_TARGETS := $(BOARD_ROOTFS_TARGETS)

# Kernel Definitions
ELDS_KERNEL := Linux
ifeq ($(BOARD_KERNEL_TREE),)
ELDS_KERNEL_TREE := linux
else
ELDS_KERNEL_TREE := $(BOARD_KERNEL_TREE)
endif
ELDS_KERNEL_BUILD := $(ELDS_ROOTFS_BUILD)/build/$(ELDS_KERNEL_TREE)
ELDS_KERNEL_SCM := $(ELDS_SCM)/$(ELDS_KERNEL_TREE)
ELDS_KERNEL_SCM_VERSION := $(shell cat $(ELDS_SCM)/.$(ELDS_KERNEL_TREE) 2>/dev/null)
ELDS_KERNEL_GIT_VERSION := $(shell cd $(ELDS_KERNEL_SCM) 2>/dev/null && git describe --long 2>/dev/null)
ELDS_KERNEL_VERSION := $(shell cd $(ELDS_KERNEL_SCM) 2>/dev/null && git describe 2>/dev/null | cut -d v -f 2)
ELDS_KERNEL_LOCALVERSION := -$(shell printf "$(ELDS_KERNEL_VERSION)" | cut -d '-' -f 2-3)
ifeq ($(ELDS_KERNEL_LOCALVERSION),-$(ELDS_KERNEL_VERSION))
ELDS_KERNEL_LOCALVERSION :=
endif
ifeq ($(shell printf "$(ELDS_KERNEL_VERSION)" | cut -d '-' -f 1),next)
ELDS_KERNEL_LOCALVERSION :=
endif
ELDS_KERNEL_CONFIG := $(ELDS_KERNEL_BUILD)/.config
ELDS_KERNEL_SYSMAP := $(ELDS_KERNEL_BUILD)/System.map
ELDS_KERNEL_BOOT := $(ELDS_KERNEL_BUILD)/arch/$(BOARD_ARCH)/boot
ifdef BOARD_KERNEL_DT
ELDS_KERNEL_DTB := $(ELDS_KERNEL_BOOT)/dts/$(BOARD_KERNEL_DT).dtb
ELDS_KERNEL_TARGETS := $(ELDS_KERNEL_DTB)
endif
ELDS_KERNEL_TARGETS += $(ELDS_KERNEL_BOOT)/Image $(ELDS_KERNEL_BOOT)/zImage \
		       $(ELDS)/rootfs/$(ELDS_BOARD)/$(ELDS_CROSS_TUPLE)/target/boot/zImage

# Misc.
ELDS_ISSUE := $(shell printf "$(ELDS_BOARD) Solution @ $(shell git describe --always)")

# Store build information
CMD := $(shell printf $(ELDS) > $(ELDS)/.solution)
CMD := $(shell printf $(ELDS_BOARD) > $(ELDS)/.board)
CMD := $(shell printf $(ELDS_CROSS_TUPLE) > $(ELDS)/.cross-tuple)

# PATH Environment
PATH := $(PATH):$(ELDS)/toolchain/builder:$(ELDS_TOOLCHAIN_PATH)/bin

# Makefile functions
define scm-check
	@if [ -d $(ELDS_SCM)/$(*F) ]; then \
		if ! [ "`ls -A $(ELDS_SCM)/$(*F)`" ]; then \
			printf "*****   MISSING GIT SOURCES  *****\n"; \
			printf "*****     RUN 'make scm'     *****\n"; \
			sleep 3; \
			exit 2; \
		fi; \
	else \
		printf "***** MISSING $(ELDS_SCM)/$(*F) DIRECTORY *****\n"; \
		printf "*****     PLEASE ADD SOURCES      *****\n"; \
		sleep 3; \
		exit 2; \
	fi
	@printf "***** USING $(ELDS_SCM)/$(*F) SOURCES *****\n"
endef

define solution-env
	@printf "========================================================================\n"
	@printf "ELDS                         : $(ELDS)\n"
	@printf "ELDS_ISSUE                   : $(ELDS_ISSUE)\n"
	@printf "ELDS_BOARD                   : $(ELDS_BOARD)\n"
	@printf "========================================================================\n"
	$(call $(ELDS_BOARD)-env)
	@printf "========================================================================\n"
	@printf "ELDS_TOOLCHAIN               : $(ELDS_TOOLCHAIN)\n"
	@printf "ELDS_TOOLCHAIN_VERSION       : $(ELDS_TOOLCHAIN_VERSION)\n"
	@printf "ELDS_TOOLCHAIN_SCM_VERSION   : $(ELDS_TOOLCHAIN_SCM_VERSION)\n"
	@printf "ELDS_TOOLCHAIN_GIT_VERSION   : $(ELDS_TOOLCHAIN_GIT_VERSION)\n"
	@printf "ELDS_TOOLCHAIN_PATH          : $(ELDS_TOOLCHAIN_PATH)\n"
	@printf "ELDS_TOOLCHAIN_BUILD         : $(ELDS_TOOLCHAIN_BUILD)\n"
	@printf "ELDS_TOOLCHAIN_SOURCES       : $(ELDS_TOOLCHAIN_SOURCES)\n"
	@printf "ELDS_TOOLCHAIN_TARGETS       : $(ELDS_TOOLCHAIN_TARGETS)\n"
	@printf "========================================================================\n"
	@printf "ELDS_ROOTFS                  : $(ELDS_ROOTFS)\n"
	@printf "ELDS_ROOTFS_VERSION          : $(ELDS_ROOTFS_VERSION)\n"
	@printf "ELDS_ROOTFS_SCM_VERSION      : $(ELDS_ROOTFS_SCM_VERSION)\n"
	@printf "ELDS_ROOTFS_GIT_VERSION      : $(ELDS_ROOTFS_GIT_VERSION)\n"
	@printf "ELDS_ROOTFS_BUILD            : $(ELDS_ROOTFS_BUILD)\n"
	@printf "ELDS_ROOTFS_SOURCES          : $(ELDS_ROOTFS_SOURCES)\n"
	@printf "ELDS_ROOTFS_TARGETS          : $(ELDS_ROOTFS_TARGETS)\n"
	@printf "========================================================================\n"
	@printf "ELDS_KERNEL                  : $(ELDS_KERNEL)\n"
	@printf "ELDS_KERNEL_VERSION          : $(ELDS_KERNEL_VERSION)\n"
	@printf "ELDS_KERNEL_SCM_VERSION      : $(ELDS_KERNEL_SCM_VERSION)\n"
	@printf "ELDS_KERNEL_GIT_VERSION      : $(ELDS_KERNEL_GIT_VERSION)\n"
	@printf "ELDS_KERNEL_LOCALVERSION     : $(ELDS_KERNEL_LOCALVERSION)\n"
	@printf "ELDS_KERNEL_BUILD            : $(ELDS_KERNEL_BUILD)\n"
	@printf "ELDS_KERNEL_BOOT             : $(ELDS_KERNEL_BOOT)\n"
	@printf "ELDS_KERNEL_TARGETS          : $(ELDS_KERNEL_TARGETS)\n"
	@printf "========================================================================\n"
	@printf "ELDS_ARCHIVE                 : $(ELDS_ARCHIVE)\n"
	@printf "PATH                         : $(PATH)\n"
	@printf "========================================================================\n"
endef

export ELDS
export ELDS_BOARD
export ELDS_ISSUE
export ELDS_CROSS_TUPLE
