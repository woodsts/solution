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

export ELDS_HOSTNAME
export ELDS_GETTY_PORT
