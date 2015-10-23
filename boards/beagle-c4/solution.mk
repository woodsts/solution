#
# This is the GNU Make include file for 'solution'
#
# Copyright (C) 2014 Derald D. Woods
#
# This file is part of the solution project, and is made available
# under the terms of the GNU General Public License version 2
#

include $(ELDS)/boards/omap2plus/solution.mk

BOARD_HOSTNAME := beagle-c4
BOARD_GETTY_PORT := ttyO2

BOARD_ROOTFS_FINAL := $(ELDS)/rootfs/$(ELDS_BOARD)/$(BOARD_ARCH)$(BOARD_VENDOR)-$(BOARD_OS)-$(BOARD_ABI)
BOARD_ROOTFS_TARGETS += $(BOARD_ROOTFS_FINAL)/images/rootfs.tar

BOARD_KERNEL_DT := omap3-beagle

define beagle-c4-bootloader-config
	@mkdir -p $(BOARD_BOOTLOADER_BUILD)
	$(MAKE) -C $(BOARD_BOOTLOADER_SCM) O=$(BOARD_BOOTLOADER_BUILD) $(ELDS_CROSS_PARAMS) distclean
	$(MAKE) -C $(BOARD_BOOTLOADER_SCM) O=$(BOARD_BOOTLOADER_BUILD) $(ELDS_CROSS_PARAMS) omap3_beagle_defconfig
endef

define beagle-c4-bootloader
	$(call omap2plus-bootloader)
endef

define beagle-c4-env
	$(call omap2plus-env)
endef

define beagle-c4-rootfs-finalize
	$(call omap2plus-rootfs-finalize)
endef

export BOARD_HOSTNAME
export BOARD_GETTY_PORT

