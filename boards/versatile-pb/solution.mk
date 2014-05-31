#
# This is the GNU Make include file for 'solution'
#
# Copyright (C) 2014 Derald D. Woods
#
# This file is part of the solution project, and is made available
# under the terms of the GNU General Public License version 2
#

ELDS_HOSTNAME := versatile-pb
ELDS_GETTY_PORT := ttyAMA0

ELDS_ARCH ?= arm
ELDS_VENDOR ?= -unknown
ELDS_OS ?= linux
ELDS_ABI ?= gnueabi

BOARD_TOOLCHAIN_CONFIG := $(ELDS)/boards/$(ELDS_BOARD)/config/crosstool-ng/config
BOARD_ROOTFS_CONFIG := $(ELDS)/boards/$(ELDS_BOARD)/config/buildroot/config

define versatile-pb-env
	@printf "ELDS_ARCH              : $(ELDS_ARCH)\n"
	@printf "ELDS_VENDOR            : $(ELDS_VENDOR)\n"
	@printf "ELDS_OS                : $(ELDS_OS)\n"
	@printf "ELDS_ABI               : $(ELDS_ABI)\n"
	@printf "ELDS_HOSTNAME          : $(ELDS_HOSTNAME)\n"
	@printf "ELDS_GETTY_PORT        : $(ELDS_GETTY_PORT)\n"
endef

export ELDS_HOSTNAME
export ELDS_GETTY_PORT

