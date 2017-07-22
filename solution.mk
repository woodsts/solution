#
# This is the GNU Make include file for 'solution'
#
# Copyright (C) 2017 Derald D. Woods
#
# This file is part of the solution project, and is made available
# under the terms of the GNU General Public License version 2
#
# References:
#
# ARM Linux [http://www.arm.linux.org.uk/docs/kerncomp.php]
#

ELDS_BUILD_OS_ID = Ubuntu
ELDS_BUILD_OS_CODENAME = xenial
ELDS_BUILD_OS_MESSAGE = [ 'solution' requires $(ELDS_BUILD_OS_ID) 16.04 LTS ] ***
ifneq ($(shell lsb_release -i|cut -d : -f 2|tr -d '\t'),$(ELDS_BUILD_OS_ID))
$(error $(ELDS_BUILD_OS_MESSAGE))
else
ifneq ($(shell lsb_release -c|cut -d : -f 2|tr -d '\t'),$(ELDS_BUILD_OS_CODENAME))
$(error $(ELDS_BUILD_OS_MESSAGE))
endif
endif

ELDS := $(shell readlink -e $(CURDIR))
ELDS_BOARD ?= omap3-evm

# Directory Definitions
ELDS_SCM := $(ELDS)/scm
ELDS_PATCHES := $(ELDS)/patches
ELDS_ARCHIVE ?= $(HOME)/Public

# Read the Embedded Board Definitions
include $(ELDS)/boards/$(ELDS_BOARD)/solution.mk

# Cross-Compilation Definitions
ELDS_CROSS_TUPLE := $(BOARD_CROSS_TUPLE)
ELDS_CROSS_COMPILE := $(ELDS_CROSS_TUPLE)-
ELDS_CROSS_PARAMS := ARCH=$(BOARD_ARCH) CROSS_COMPILE=$(ELDS_CROSS_COMPILE)

# Toolchain Definitions
ELDS_TOOLCHAIN := crosstool-NG
ELDS_TOOLCHAIN_TREE := $(BOARD_TOOLCHAIN_TREE)
ELDS_TOOLCHAIN_SCM := $(ELDS_SCM)/$(ELDS_TOOLCHAIN_TREE)
ELDS_TOOLCHAIN_VERSION := $(shell cd $(ELDS_TOOLCHAIN_SCM) 2>/dev/null && git describe --tags 2>/dev/null)
ELDS_TOOLCHAIN_PATH := $(ELDS)/toolchain/$(ELDS_CROSS_TUPLE)
ELDS_TOOLCHAIN_BUILD := $(ELDS)/toolchain/build/$(ELDS_CROSS_TUPLE)
ELDS_TOOLCHAIN_BUILDER := $(ELDS)/toolchain/builder
ELDS_TOOLCHAIN_TARBALLS := $(ELDS)/toolchain/tarballs
ELDS_TOOLCHAIN_CONFIG := $(ELDS_TOOLCHAIN_BUILD)/.config
ELDS_TOOLCHAIN_TARGETS := $(ELDS_TOOLCHAIN_PATH)/bin/$(ELDS_CROSS_COMPILE)gcc \
	$(ELDS_TOOLCHAIN_PATH)/bin/$(ELDS_CROSS_COMPILE)g++ \
	$(ELDS_TOOLCHAIN_PATH)/$(ELDS_CROSS_TUPLE)/debug-root/usr/bin/gdbserver \
	$(ELDS_TOOLCHAIN_PATH)/$(ELDS_CROSS_TUPLE)/debug-root/usr/bin/ltrace \
	$(ELDS_TOOLCHAIN_PATH)/$(ELDS_CROSS_TUPLE)/debug-root/usr/bin/strace
ELDS_TOOLCHAIN_TARGET_FINAL := $(ELDS_TOOLCHAIN_PATH)/$(ELDS_CROSS_TUPLE)/debug-root/usr/bin/gdbserver

# Bootloader Definitions
ELDS_BOOTLOADER := $(BOARD_BOOTLOADER)
ELDS_BOOTLOADER_TREE := $(BOARD_BOOTLOADER_TREE)
ELDS_BOOTLOADER_BUILD := $(BOARD_BOOTLOADER_BUILD)
ELDS_BOOTLOADER_CONFIG := $(BOARD_BOOTLOADER_BUILD)/.config
ELDS_BOOTLOADER_TARGETS := $(BOARD_BOOTLOADER_TARGETS)
ELDS_BOOTLOADER_TARGET_FINAL := $(BOARD_ROOTFS_FINAL)/target/boot/u-boot.img

# Root Filesystem Definitions
ELDS_ROOTFS := Buildroot
ELDS_ROOTFS_TREE := $(BOARD_ROOTFS_TREE)
ELDS_ROOTFS_SCM := $(ELDS_SCM)/$(ELDS_ROOTFS_TREE)
ELDS_ROOTFS_VERSION := $(shell cd $(ELDS_ROOTFS_SCM) 2>/dev/null && make print-version 2>/dev/null)
ELDS_ROOTFS_BUILD := $(ELDS)/rootfs/$(BOARD_TYPE)/$(ELDS_CROSS_TUPLE)
ELDS_ROOTFS_TARBALLS := $(ELDS)/rootfs/tarballs
ELDS_ROOTFS_CONFIG := $(ELDS_ROOTFS_BUILD)/.config
ELDS_ROOTFS_TARGETS := $(BOARD_ROOTFS_TARGETS)
ELDS_ROOTFS_TARGET_FINAL := $(BOARD_ROOTFS_FINAL)/images/rootfs.tar

# Kernel Definitions
ELDS_KERNEL := Linux
ELDS_KERNEL_TREE := $(BOARD_KERNEL_TREE)
ELDS_KERNEL_BUILD := $(ELDS_ROOTFS_BUILD)/build/$(ELDS_KERNEL_TREE)
ELDS_KERNEL_SCM := $(ELDS_SCM)/$(ELDS_KERNEL_TREE)
ELDS_KERNEL_VERSION := $(shell cd $(ELDS_KERNEL_SCM) 2>/dev/null && git describe 2>/dev/null | cut -d v -f 2)
ELDS_KERNEL_LOCALVERSION := -$(shell printf "$(ELDS_KERNEL_VERSION)" | cut -d '-' -f 2-3)
ifeq ($(ELDS_KERNEL_LOCALVERSION),-$(ELDS_KERNEL_VERSION))
ELDS_KERNEL_LOCALVERSION :=
endif
ifeq ($(shell printf "$(ELDS_KERNEL_VERSION)" | cut -d '-' -f 1),next)
ELDS_KERNEL_LOCALVERSION :=
endif
ifneq ($(shell printf "$(ELDS_KERNEL_VERSION)" | grep -e "-rc"),)
ELDS_KERNEL_LOCALVERSION :=
endif
ELDS_KERNEL_CONFIG := $(ELDS_KERNEL_BUILD)/.config
ELDS_KERNEL_SYSMAP := $(ELDS_KERNEL_BUILD)/System.map
ELDS_KERNEL_BOOT := $(ELDS_KERNEL_BUILD)/arch/$(BOARD_ARCH)/boot
ELDS_KERNEL_DTB := $(ELDS_KERNEL_BOOT)/dts/$(BOARD_KERNEL_DT).dtb
ifdef BOARD_KERNEL_DT_OTHER
ELDS_KERNEL_DTB_OTHER := $(ELDS_KERNEL_BOOT)/dts/$(BOARD_KERNEL_DT_OTHER).dtb
endif
ELDS_KERNEL_TARGETS := $(ELDS)/rootfs/$(ELDS_BOARD)/$(ELDS_CROSS_TUPLE)/target/boot/uImage \
	$(ELDS)/rootfs/$(ELDS_BOARD)/$(ELDS_CROSS_TUPLE)/target/boot/zImage \
	$(ELDS)/rootfs/$(ELDS_BOARD)/$(ELDS_CROSS_TUPLE)/target/boot/System.map \
	$(ELDS)/rootfs/$(ELDS_BOARD)/$(ELDS_CROSS_TUPLE)/target/boot/$(BOARD_KERNEL_DT).dtb
ifdef BOARD_KERNEL_DT_OTHER
ELDS_KERNEL_TARGETS += $(ELDS)/rootfs/$(ELDS_BOARD)/$(ELDS_CROSS_TUPLE)/target/boot/$(BOARD_KERNEL_DT_OTHER).dtb
endif
ELDS_KERNEL_TARGET_FINAL := $(BOARD_ROOTFS_FINAL)/target/boot/$(BOARD_KERNEL_DT).dtb

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
	@if ! [ -d $(ELDS_SCM)/$(*F) ]; then \
		printf "\n"; \
		printf "***** MISSING $(ELDS_SCM)/$(*F) DIRECTORY *****\n"; \
		printf "*****     PLEASE ADD SOURCES      *****\n"; \
		printf "\n"; \
		sleep 3; \
		exit 2; \
	fi
	@printf "\n***** [$(ELDS_BOARD)][$(BOARD_TYPE)] USING $(ELDS_SCM)/$(*F) SOURCES *****\n\n"
endef

define solution-env
	@printf "========================================================================\n"
	@printf "ELDS                         : $(ELDS)\n"
	@printf "ELDS_ISSUE                   : $(ELDS_ISSUE)\n"
	@printf "ELDS_BOARD                   : $(ELDS_BOARD)\n"
	@printf "ELDS_CROSS_TUPLE             : $(ELDS_CROSS_TUPLE)\n"
	@printf "========================================================================\n"
	$(call $(ELDS_BOARD)-env)
	@printf "ELDS_BOOTLOADER_TARGET_FINAL : $(ELDS_BOOTLOADER_TARGET_FINAL)\n"
	@printf "========================================================================\n"
	@printf "ELDS_TOOLCHAIN               : $(ELDS_TOOLCHAIN)\n"
	@printf "ELDS_TOOLCHAIN_TREE          : $(ELDS_TOOLCHAIN_TREE)\n"
	@printf "ELDS_TOOLCHAIN_VERSION       : $(ELDS_TOOLCHAIN_VERSION)\n"
	@printf "ELDS_TOOLCHAIN_PATH          : $(ELDS_TOOLCHAIN_PATH)\n"
	@printf "ELDS_TOOLCHAIN_BUILD         : $(ELDS_TOOLCHAIN_BUILD)\n"
	@printf "ELDS_TOOLCHAIN_TARGETS       : $(ELDS_TOOLCHAIN_TARGETS)\n"
	@printf "ELDS_TOOLCHAIN_TARGET_FINAL  : $(ELDS_TOOLCHAIN_TARGET_FINAL)\n"
	@printf "========================================================================\n"
	@printf "ELDS_ROOTFS                  : $(ELDS_ROOTFS)\n"
	@printf "ELDS_ROOTFS_TREE             : $(ELDS_ROOTFS_TREE)\n"
	@printf "ELDS_ROOTFS_VERSION          : $(ELDS_ROOTFS_VERSION)\n"
	@printf "ELDS_ROOTFS_BUILD            : $(ELDS_ROOTFS_BUILD)\n"
	@printf "ELDS_ROOTFS_TARGETS          : $(ELDS_ROOTFS_TARGETS)\n"
	@printf "ELDS_ROOTFS_TARGET_FINAL     : $(ELDS_ROOTFS_TARGET_FINAL)\n"
	@printf "========================================================================\n"
	@printf "ELDS_KERNEL                  : $(ELDS_KERNEL)\n"
	@printf "ELDS_KERNEL_TREE             : $(ELDS_KERNEL_TREE)\n"
	@printf "ELDS_KERNEL_VERSION          : $(ELDS_KERNEL_VERSION)\n"
	@printf "ELDS_KERNEL_LOCALVERSION     : $(ELDS_KERNEL_LOCALVERSION)\n"
	@printf "ELDS_KERNEL_DTB              : $(ELDS_KERNEL_DTB)\n"
	@printf "ELDS_KERNEL_DTB_OTHER        : $(ELDS_KERNEL_DTB_OTHER)\n"
	@printf "ELDS_KERNEL_BUILD            : $(ELDS_KERNEL_BUILD)\n"
	@printf "ELDS_KERNEL_BOOT             : $(ELDS_KERNEL_BOOT)\n"
	@printf "ELDS_KERNEL_TARGETS          : $(ELDS_KERNEL_TARGETS)\n"
	@printf "ELDS_KERNEL_TARGET_FINAL     : $(ELDS_KERNEL_TARGET_FINAL)\n"
	@printf "========================================================================\n"
	@printf "ELDS_ARCHIVE                 : $(ELDS_ARCHIVE)\n"
	@printf "PATH                         : $(PATH)\n"
	@printf "========================================================================\n"
endef

export ELDS
export ELDS_BOARD
export ELDS_ISSUE
export ELDS_CROSS_TUPLE
export ELDS_TOOLCHAIN_BUILD
export ELDS_TOOLCHAIN_TREE
export ELDS_BOOTLOADER_TREE
export ELDS_KERNEL_TREE
export ELDS_ROOTFS_TREE
export ELDS_TOOLCHAIN_SCM
export ELDS_BOOTLOADER_SCM
export ELDS_KERNEL_SCM
export ELDS_ROOTFS_SCM
export ELDS_TOOLCHAIN_TARBALLS
export ELDS_ROOTFS_TARBALLS
