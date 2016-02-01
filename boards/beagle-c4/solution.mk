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

BOARD_KERNEL_TREE ?= linux-$(BOARD_HOSTNAME)
BOARD_KERNEL_DT ?= omap3-beagle

include $(ELDS)/boards/omap2plus/solution.mk

BOARD_ROOTFS_FINAL := $(ELDS)/rootfs/$(ELDS_BOARD)/$(BOARD_ARCH)$(BOARD_VENDOR)-$(BOARD_OS)-$(BOARD_ABI)
BOARD_ROOTFS_TARGETS += $(BOARD_ROOTFS_FINAL)/images/rootfs.tar $(BOARD_ROOTFS_FINAL)/images/rootfs.ubi $(BOARD_ROOTFS_FINAL)/images/rootfs.ubifs

define $(ELDS_BOARD)-bootloader-config
	@mkdir -p $(BOARD_BOOTLOADER_BUILD)
	$(MAKE) -C $(BOARD_BOOTLOADER_SCM) O=$(BOARD_BOOTLOADER_BUILD) $(ELDS_CROSS_PARAMS) distclean
	$(MAKE) -C $(BOARD_BOOTLOADER_SCM) O=$(BOARD_BOOTLOADER_BUILD) $(ELDS_CROSS_PARAMS) omap3_beagle_defconfig
endef

define $(ELDS_BOARD)-bootloader
	$(call omap2plus-bootloader)
endef

define $(ELDS_BOARD)-env
	$(call omap2plus-env)
endef

#define $(ELDS_BOARD)-append-dtb
#	@cat $(BOARD_BUILD)/$(BOARD_KERNEL_TREE)/arch/$(BOARD_ARCH)/boot/dts/$(BOARD_KERNEL_DT).dtb >> $(BOARD_BUILD)/$(BOARD_KERNEL_TREE)/arch/$(BOARD_ARCH)/boot/zImage
#	@mkimage -A arm -O linux -T kernel -C none -a 0x80008000 -e 0x80008000 -n "Linux $(ELDS_BOARD)" \
#		-d $(BOARD_BUILD)/$(BOARD_KERNEL_TREE)/arch/$(BOARD_ARCH)/boot/zImage $(BOARD_BUILD)/$(BOARD_KERNEL_TREE)/arch/$(BOARD_ARCH)/boot/uImage
#	@cp -av $(BOARD_BUILD)/$(BOARD_KERNEL_TREE)/arch/$(BOARD_ARCH)/boot/uImage $(BOARD_TARGET)/boot/
#endef

define $(ELDS_BOARD)-finalize
	$(call omap2plus-finalize)
endef

export BOARD_HOSTNAME
export BOARD_GETTY_PORT
export BOARD_KERNEL_TREE
export BOARD_KERNEL_DT
