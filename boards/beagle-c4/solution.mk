#
# This is the GNU Make include file for 'solution'
#
# Copyright (C) 2014 Derald D. Woods
#
# This file is part of the solution project, and is made available
# under the terms of the GNU General Public License version 2
#

BOARD_HOSTNAME := $(ELDS_BOARD)
BOARD_GETTY_PORT ?= ttyO2

BOARD_KERNEL_TREE ?= linux
BOARD_KERNEL_DT ?= omap3-beagle

include $(ELDS)/boards/omap2plus/solution.mk

BOARD_ROOTFS_FINAL := $(ELDS)/rootfs/$(ELDS_BOARD)/$(BOARD_ARCH)$(BOARD_VENDOR)-$(BOARD_OS)-$(BOARD_ABI)

define $(ELDS_BOARD)-bootloader-config
	@mkdir -p $(BOARD_BOOTLOADER_BUILD)
	$(MAKE) -C $(BOARD_BOOTLOADER_SCM) O=$(BOARD_BOOTLOADER_BUILD) $(ELDS_CROSS_PARAMS) distclean
	$(MAKE) -C $(BOARD_BOOTLOADER_SCM) O=$(BOARD_BOOTLOADER_BUILD) $(ELDS_CROSS_PARAMS) omap3_beagle_defconfig
endef

export BOARD_HOSTNAME
export BOARD_GETTY_PORT
export BOARD_KERNEL_TREE
export BOARD_KERNEL_DT
