#
# This is the GNU Make include file for 'solution'
#
# Copyright (C) 2014 Derald D. Woods
#
# This file is part of the solution project, and is made available
# under the terms of the GNU General Public License version 2
#

BOARD_TYPE := omap2plus

BOARD_ARCH ?= arm
BOARD_VENDOR ?= -cortexa8
BOARD_OS ?= linux
BOARD_ABI ?= gnueabihf

BOARD_CONFIG := $(ELDS)/boards/$(BOARD_TYPE)/config
BOARD_TOOLCHAIN_CONFIG := $(BOARD_CONFIG)/crosstool-ng/config
BOARD_ROOTFS_CONFIG := $(BOARD_CONFIG)/buildroot/config
BOARD_KERNEL_CONFIG := $(BOARD_CONFIG)/$(BOARD_KERNEL_TREE)/config

BOARD_ROOTFS := $(ELDS)/rootfs/$(BOARD_TYPE)/$(BOARD_ARCH)$(BOARD_VENDOR)-$(BOARD_OS)-$(BOARD_ABI)
BOARD_BUILD := $(BOARD_ROOTFS)/build
BOARD_IMAGES := $(BOARD_ROOTFS)/images
BOARD_TARGET := $(BOARD_ROOTFS)/target
BOARD_ROOTFS_FINAL := $(BOARD_ROOTFS)

BOARD_ROOTFS_TARGETS := $(BOARD_IMAGES)/rootfs.tar

# Bootloader Definitions
BOARD_BOOTLOADER := U-Boot
BOARD_BOOTLOADER_TREE ?= u-boot-$(BOARD_HOSTNAME)
BOARD_BOOTLOADER_BUILD := $(BOARD_BUILD)/$(BOARD_BOOTLOADER_TREE)
BOARD_BOOTLOADER_TARGET := $(BOARD_TARGET)/boot
BOARD_BOOTLOADER_SCM := $(ELDS_SCM)/$(BOARD_BOOTLOADER_TREE)
BOARD_BOOTLOADER_VERSION := $(shell cd $(BOARD_BOOTLOADER_SCM) && git describe --long --dirty 2>/dev/null | cut -d v -f 2)
BOARD_BOOTLOADER_CONFIG := $(BOARD_BOOTLOADER_BUILD)/include/autoconf.mk
BOARD_BOOTLOADER_SYSMAP := $(BOARD_BOOTLOADER_BUILD)/System.map
BOARD_BOOTLOADER_BINARY_SPL := $(BOARD_BOOTLOADER_BUILD)/MLO
BOARD_BOOTLOADER_BINARY_IMAGE := $(BOARD_BOOTLOADER_BUILD)/u-boot.img
BOARD_BOOTLOADER_TARGETS := $(BOARD_BOOTLOADER_BINARY_SPL) $(BOARD_BOOTLOADER_BINARY_IMAGE)

define omap2plus-bootloader
	@case "$@" in \
	$(BOARD_BOOTLOADER_BINARY_SPL) | $(BOARD_BOOTLOADER_BINARY_IMAGE))\
		printf "***** U-Boot $(BOARD_BOOTLOADER_VERSION) 'make $@' *****\n"; \
		$(MAKE) -C $(BOARD_BOOTLOADER_SCM) O=$(BOARD_BOOTLOADER_BUILD) $(ELDS_CROSS_PARAMS); \
		if ! [ -f $(BOARD_BOOTLOADER_BINARY_SPL) ]; then \
			printf "***** U-Boot $(BOARD_BOOTLOADER_VERSION) $(BOARD_BOOTLOADER_BINARY_SPL) build FAILED! *****\n"; \
			exit 2; \
		fi; \
		if ! [ -f $(BOARD_BOOTLOADER_BINARY_IMAGE) ]; then \
			printf "***** U-Boot $(BOARD_BOOTLOADER_VERSION) $(BOARD_BOOTLOADER_BINARY_IMAGE) build FAILED! *****\n"; \
			exit 2; \
		fi; \
		mkdir -p $(BOARD_BOOTLOADER_TARGET); \
		$(RM) $(BOARD_BOOTLOADER_TARGET)/u-boot*; \
		$(RM) $(BOARD_BOOTLOADER_TARGET)/MLO*; \
		cp -av $(BOARD_BOOTLOADER_BINARY_SPL) $(BOARD_BOOTLOADER_TARGET)/; \
		cp -av $(BOARD_BOOTLOADER_BINARY_IMAGE) $(BOARD_BOOTLOADER_TARGET)/; \
		;; \
	*)\
		printf "***** U-Boot $(BOARD_BOOTLOADER_VERSION) 'make $(*F)' *****\n"; \
		$(MAKE) -C $(BOARD_BOOTLOADER_SCM) O=$(BOARD_BOOTLOADER_BUILD) $(ELDS_CROSS_PARAMS) $(*F); \
	esac;
endef

define $(ELDS_BOARD)-bootloader
	$(call omap2plus-bootloader)
endef

define omap2plus-finalize
	@mkdir -p $(BOARD_ROOTFS_FINAL)/images
	@for f in $(ELDS_ROOTFS_TARGETS); do \
		if [ -f $$f ]; then \
			rsync $$f $(BOARD_ROOTFS_FINAL)/images/; \
		fi; \
	done
	@$(RM) -r $(BOARD_ROOTFS_FINAL)/target/boot
	@$(RM) -r $(BOARD_ROOTFS_FINAL)/target/lib/modules
	@mkdir -p $(BOARD_ROOTFS_FINAL)/target/lib
	@if [ -d $(BOARD_TARGET)/boot ]; then \
		rsync -aP $(BOARD_TARGET)/boot \
			$(BOARD_ROOTFS_FINAL)/target/; \
	fi
	@if [ -d $(BOARD_TARGET)/lib/modules ]; then \
		rsync -aP $(BOARD_TARGET)/lib/modules \
			$(BOARD_ROOTFS_FINAL)/target/lib/; \
	fi
	@if [ -d $(BOARD_TARGET)/lib/firmware ]; then \
		rsync -aP $(BOARD_TARGET)/lib/firmware \
			$(BOARD_ROOTFS_FINAL)/target/lib/; \
	fi
endef

define $(ELDS_BOARD)-finalize
	$(call omap2plus-finalize)
endef

define $(ELDS_BOARD)-append-dtb
	@cat $(BOARD_BUILD)/$(BOARD_KERNEL_TREE)/arch/$(BOARD_ARCH)/boot/dts/$(BOARD_KERNEL_DT).dtb >> \
		$(BOARD_BUILD)/$(BOARD_KERNEL_TREE)/arch/$(BOARD_ARCH)/boot/zImage
	@mkimage -A arm -O linux -T kernel -C none -a 0x82000000 -e 0x82000000 -n "Linux $(ELDS_KERNEL_VERSION)" \
		-d $(BOARD_BUILD)/$(BOARD_KERNEL_TREE)/arch/$(BOARD_ARCH)/boot/zImage \
		$(BOARD_BUILD)/$(BOARD_KERNEL_TREE)/arch/$(BOARD_ARCH)/boot/uImage
	@cp -av $(BOARD_BUILD)/$(BOARD_KERNEL_TREE)/arch/$(BOARD_ARCH)/boot/uImage $(BOARD_TARGET)/boot/
endef

define $(ELDS_BOARD)-env
	$(call omap2plus-env)
endef

define omap2plus-env
	@printf "BOARD_TYPE                   : $(BOARD_TYPE)\n"
	@printf "BOARD_ARCH                   : $(BOARD_ARCH)\n"
	@printf "BOARD_VENDOR                 : $(BOARD_VENDOR)\n"
	@printf "BOARD_OS                     : $(BOARD_OS)\n"
	@printf "BOARD_ABI                    : $(BOARD_ABI)\n"
	@printf "BOARD_HOSTNAME               : $(BOARD_HOSTNAME)\n"
	@printf "BOARD_GETTY_PORT             : $(BOARD_GETTY_PORT)\n"
	@printf "========================================================================\n"
	@printf "BOARD_BOOTLOADER             : $(BOARD_BOOTLOADER)\n"
	@printf "BOARD_BOOTLOADER_TREE        : $(BOARD_BOOTLOADER_TREE)\n"
	@printf "BOARD_BOOTLOADER_VERSION     : $(BOARD_BOOTLOADER_VERSION)\n"
	@printf "BOARD_BOOTLOADER_BUILD       : $(BOARD_BOOTLOADER_BUILD)\n"
	@printf "BOARD_BOOTLOADER_TARGETS     : $(BOARD_BOOTLOADER_TARGETS)\n"
endef

export BOARD_TYPE
export BOARD_BOOTLOADER_TREE
