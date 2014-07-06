#
# This is the GNU Make include file for 'solution'
#
# Copyright (C) 2014 Derald D. Woods
#
# This file is part of the solution project, and is made available
# under the terms of the GNU General Public License version 2
#

BOARD_HOSTNAME := realview-pb
BOARD_GETTY_PORT := ttyAMA0

BOARD_ARCH ?= arm
BOARD_VENDOR ?= -unknown
BOARD_OS ?= linux
BOARD_ABI ?= gnueabihf

BOARD_BUILD := $(ELDS)/rootfs/$(ELDS_BOARD)/$(BOARD_ARCH)$(BOARD_VENDOR)-$(BOARD_OS)-$(BOARD_ABI)/build
BOARD_ROOTFS := $(ELDS)/rootfs/$(ELDS_BOARD)/$(BOARD_ARCH)$(BOARD_VENDOR)-$(BOARD_OS)-$(BOARD_ABI)/target

BOARD_TOOLCHAIN_CONFIG := $(ELDS)/boards/$(ELDS_BOARD)/config/crosstool-ng/config
BOARD_ROOTFS_CONFIG := $(ELDS)/boards/$(ELDS_BOARD)/config/buildroot/config
BOARD_KERNEL_CONFIG := $(ELDS)/boards/$(ELDS_BOARD)/config/linux/config

define realview-pb-env
	@printf "BOARD_ARCH                  : $(BOARD_ARCH)\n"
	@printf "BOARD_VENDOR                : $(BOARD_VENDOR)\n"
	@printf "BOARD_OS                    : $(BOARD_OS)\n"
	@printf "BOARD_ABI                   : $(BOARD_ABI)\n"
	@printf "BOARD_HOSTNAME              : $(BOARD_HOSTNAME)\n"
	@printf "BOARD_GETTY_PORT            : $(BOARD_GETTY_PORT)\n"
endef

export BOARD_HOSTNAME
export BOARD_GETTY_PORT

