#
# This is the GNU Make include file for 'solution'
#
# Copyright (C) 2017 Derald D. Woods
#
# This file is part of the solution project, and is made available
# under the terms of the GNU General Public License version 2
#

ELDS ?= /solution
ELDS_BOARD ?= tm4c1294xl

BOARD_HOSTNAME := $(ELDS_BOARD)

BOARD_TYPE := $(ELDS_BOARD)

BOARD_MCU := tm4c1294ncpdt

BOARD_TOOLCHAIN_TREE ?= crosstool-ng

BOARD_ARCH ?= arm
BOARD_VENDOR ?= none
BOARD_ABI ?= eabi
BOARD_CROSS_TUPLE := $(BOARD_ARCH)-$(BOARD_VENDOR)-$(BOARD_ABI)

BOARD_SCM ?= $(ELDS)/scm
BOARD_CONFIG := $(ELDS)/boards/$(BOARD_TYPE)/config
BOARD_TOOLCHAIN_CONFIG := $(BOARD_CONFIG)/crosstool-ng/config

define $(ELDS_BOARD)-env
	@printf "BOARD_ARCH                   : $(BOARD_ARCH)\n"
	@printf "BOARD_VENDOR                 : $(BOARD_VENDOR)\n"
	@printf "BOARD_ABI                    : $(BOARD_ABI)\n"
	@printf "BOARD_HOSTNAME               : $(BOARD_HOSTNAME)\n"
endef

export BOARD_TYPE
export BOARD_HOSTNAME
