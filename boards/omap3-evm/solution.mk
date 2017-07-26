#
# This is the GNU Make include file for 'solution'
#
# Copyright (C) 2017 Derald D. Woods
#
# This file is part of the solution project, and is made available
# under the terms of the GNU General Public License version 2
#

BOARD_HOSTNAME := $(ELDS_BOARD)

BOARD_GETTY_PORT ?= ttyO0

BOARD_KERNEL_DT ?= omap3-evm

BOARD_KERNEL_TREE ?= linux
BOARD_ROOTFS_TREE ?= buildroot
BOARD_BOOTLOADER_TREE ?= u-boot
BOARD_TOOLCHAIN_TREE ?= crosstool-ng

# needed until omap3-evm in U-Boot is updated
ELDS_APPEND_DTB := yes

include $(ELDS)/boards/omap2plus/solution.mk

define $(ELDS_BOARD)-bootloader-defconfig
	@mkdir -p $(BOARD_BOOTLOADER_BUILD)
	$(MAKE) -C $(BOARD_BOOTLOADER_SCM) O=$(BOARD_BOOTLOADER_BUILD) $(ELDS_CROSS_PARAMS) distclean
	$(MAKE) -C $(BOARD_BOOTLOADER_SCM) O=$(BOARD_BOOTLOADER_BUILD) $(ELDS_CROSS_PARAMS) omap3_evm_defconfig
endef

export BOARD_HOSTNAME
export BOARD_GETTY_PORT
export BOARD_KERNEL_TREE
export BOARD_KERNEL_DT
