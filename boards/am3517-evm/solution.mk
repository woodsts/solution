#
# This is the GNU Make include file for 'solution'
#
# Copyright (C) 2014 Derald D. Woods
#
# This file is part of the solution project, and is made available
# under the terms of the GNU General Public License version 2
#

include $(ELDS)/boards/omap2plus/solution.mk

BOARD_HOSTNAME := am3517-evm
BOARD_GETTY_PORT := ttyO2

BOARD_KERNEL_DT := am3517-evm

define am3517-evm-bootloader-config
	@mkdir -p $(BOARD_BOOTLOADER_BUILD)
	$(MAKE) -C $(BOARD_BOOTLOADER_SCM) O=$(BOARD_BOOTLOADER_BUILD) $(ELDS_CROSS_PARAMS) distclean
	$(MAKE) -C $(BOARD_BOOTLOADER_SCM) O=$(BOARD_BOOTLOADER_BUILD) $(ELDS_CROSS_PARAMS) am3517_evm_defconfig
endef

define am3517-evm-bootloader
	$(call omap2plus-bootloader)
endef

define am3517-evm-env
	$(call omap2plus-env)
endef

define am3517-evm-kernel-append-dtb
	@cat $(BOARD_BUILD)/linux/arch/$(BOARD_ARCH)/boot/dts/$(BOARD_KERNEL_DT).dtb >> $(BOARD_BUILD)/linux/arch/$(BOARD_ARCH)/boot/zImage
	@mkimage -A arm -O linux -T kernel -C none -a 0x80008000 -e 0x80008000 -n "Linux $(ELDS_BOARD)" \
		-d $(BOARD_BUILD)/linux/arch/$(BOARD_ARCH)/boot/zImage $(BOARD_BUILD)/linux/arch/$(BOARD_ARCH)/boot/uImage
	@cp -av $(BOARD_BUILD)/linux/arch/$(BOARD_ARCH)/boot/uImage $(BOARD_TARGET)/boot/
endef

define am3517-evm-rootfs-finalize
	$(call omap2plus-rootfs-finalize)
endef

export BOARD_HOSTNAME
export BOARD_GETTY_PORT

