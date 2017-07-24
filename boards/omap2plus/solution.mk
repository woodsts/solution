#
# This is the GNU Make include file for 'solution'
#
# Copyright (C) 2017 Derald D. Woods
#
# This file is part of the solution project, and is made available
# under the terms of the GNU General Public License version 2
#

BOARD_TYPE := omap2plus

BOARD_ARCH ?= arm
BOARD_VENDOR ?= cortexa8
BOARD_OS ?= linux
BOARD_ABI ?= gnueabihf
BOARD_CROSS_TUPLE := $(BOARD_ARCH)-$(BOARD_VENDOR)-$(BOARD_OS)-$(BOARD_ABI)

BOARD_CONFIG := $(ELDS)/boards/$(BOARD_TYPE)/config
BOARD_TOOLCHAIN_CONFIG := $(BOARD_CONFIG)/crosstool-ng/config
BOARD_ROOTFS_CONFIG := $(BOARD_CONFIG)/buildroot/config
BOARD_KERNEL_CONFIG := $(BOARD_CONFIG)/$(BOARD_KERNEL_TREE)/config

BOARD_ROOTFS := $(ELDS)/rootfs/$(BOARD_TYPE)/$(BOARD_CROSS_TUPLE)
BOARD_BUILD := $(BOARD_ROOTFS)/build
BOARD_IMAGES := $(BOARD_ROOTFS)/images
BOARD_TARGET := $(BOARD_ROOTFS)/target
# NOTE: Using derived ELDS_BOARD for final build artifacts
BOARD_ROOTFS_FINAL := $(ELDS)/rootfs/$(ELDS_BOARD)/$(BOARD_CROSS_TUPLE)

BOARD_ROOTFS_TARGETS := $(BOARD_ROOTFS_FINAL)/images/rootfs.tar $(BOARD_ROOTFS_FINAL)/images/rootfs.ubifs

# Bootloader Definitions
BOARD_BOOTLOADER := U-Boot
BOARD_BOOTLOADER_BUILD := $(BOARD_BUILD)/u-boot-$(ELDS_BOARD)
BOARD_BOOTLOADER_TARGET := $(BOARD_TARGET)/boot
BOARD_BOOTLOADER_SCM := $(ELDS_SCM)/$(BOARD_BOOTLOADER_TREE)
BOARD_BOOTLOADER_VERSION := $(shell cd $(BOARD_BOOTLOADER_SCM) && git describe --long --dirty 2>/dev/null | cut -d v -f 2)
ifeq ($(shell echo $(BOARD_BOOTLOADER_VERSION) | cut -d '-' -f 2),0)
BOARD_BOOTLOADER_VERSION := $(shell cd $(BOARD_BOOTLOADER_SCM) && git describe 2>/dev/null | cut -d v -f 2)
endif
BOARD_BOOTLOADER_CONFIG := $(BOARD_CONFIG)/u-boot-$(ELDS_BOARD)/config
BOARD_BOOTLOADER_SYSMAP := $(BOARD_BOOTLOADER_BUILD)/System.map
BOARD_BOOTLOADER_BINARY_SPL := $(BOARD_BOOTLOADER_BUILD)/MLO
BOARD_BOOTLOADER_BINARY_IMAGE := $(BOARD_BOOTLOADER_BUILD)/u-boot.img
BOARD_BOOTLOADER_TARGETS := $(BOARD_ROOTFS_FINAL)/target/boot/u-boot.img $(BOARD_ROOTFS_FINAL)/target/boot/MLO

define omap2plus-bootloader
	@case "$@" in \
	$(BOARD_ROOTFS_FINAL)/target/boot/u-boot.img | $(BOARD_ROOTFS_FINAL)/target/boot/MLO) \
		printf "\n***** [$(ELDS_BOARD)][$(BOARD_TYPE)] make bootloader *****\n\n"; \
		$(MAKE) -C $(BOARD_BOOTLOADER_SCM) O=$(BOARD_BOOTLOADER_BUILD) $(ELDS_CROSS_PARAMS); \
		if ! [ -f $(BOARD_BOOTLOADER_BINARY_SPL) ]; then \
			printf "\n***** [$(ELDS_BOARD)][$(BOARD_TYPE)] make bootloader $(BOARD_BOOTLOADER_BINARY_SPL) build FAILED! *****\n\n"; \
			exit 2; \
		fi; \
		if ! [ -f $(BOARD_BOOTLOADER_BINARY_IMAGE) ]; then \
			printf "\n***** [$(ELDS_BOARD)][$(BOARD_TYPE)] make bootloader $(BOARD_BOOTLOADER_BINARY_IMAGE) build FAILED! *****\n\n"; \
			exit 2; \
		fi; \
		mkdir -p $(BOARD_BOOTLOADER_TARGET); \
		$(RM) $(BOARD_BOOTLOADER_TARGET)/u-boot*; \
		$(RM) $(BOARD_BOOTLOADER_TARGET)/MLO*; \
		cp -av $(BOARD_BOOTLOADER_BINARY_SPL) $(BOARD_BOOTLOADER_TARGET)/; \
		cp -av $(BOARD_BOOTLOADER_BINARY_IMAGE) $(BOARD_BOOTLOADER_TARGET)/; \
		;; \
	*) \
		printf "\n***** [$(ELDS_BOARD)][$(BOARD_TYPE)] make $(*F) *****\n\n"; \
		$(MAKE) -C $(BOARD_BOOTLOADER_SCM) O=$(BOARD_BOOTLOADER_BUILD) $(ELDS_CROSS_PARAMS) $(*F); \
		cat $(ELDS_BOOTLOADER_CONFIG) > $(BOARD_BOOTLOADER_CONFIG); \
	esac;
endef

define $(ELDS_BOARD)-bootloader
	$(call omap2plus-bootloader)
endef

define omap2plus-finalize
	@printf "\n***** [$(ELDS_BOARD)][$(BOARD_TYPE)] finalize *****\n"
	@mkdir -p $(BOARD_ROOTFS_FINAL)/target/boot
	@mkdir -p $(BOARD_ROOTFS_FINAL)/target/lib/modules
	@case "$@" in \
	$(ELDS_ROOTFS_TARGET_FINAL)) \
		rsync -a $(BOARD_IMAGES) $(BOARD_ROOTFS_FINAL)/; \
		;; \
	$(ELDS_BOOTLOADER_TARGET_FINAL)) \
		if [ -d $(BOARD_TARGET)/boot ]; then \
			cp -a \
				$(BOARD_BOOTLOADER_TARGET)/MLO \
				$(BOARD_BOOTLOADER_TARGET)/u-boot.img \
				$(BOARD_ROOTFS_FINAL)/target/boot/; \
		fi; \
		;; \
	$(ELDS_KERNEL_TARGET_FINAL)) \
		if [ -d $(BOARD_TARGET)/boot ]; then \
			cp -a \
				$(BOARD_TARGET)/boot/zImage \
				$(BOARD_TARGET)/boot/uImage \
				$(BOARD_TARGET)/boot/$(BOARD_KERNEL_DT).dtb \
				$(BOARD_TARGET)/boot/System.map \
				$(BOARD_ROOTFS_FINAL)/target/boot/; \
		fi; \
		if [ -d $(BOARD_TARGET)/lib/modules/$(ELDS_KERNEL_VERSION) ]; then \
			rsync -a $(BOARD_TARGET)/lib/modules/$(ELDS_KERNEL_VERSION) \
				$(BOARD_ROOTFS_FINAL)/target/lib/modules/; \
		fi; \
		if [ -d $(BOARD_TARGET)/lib/firmware ]; then \
			rsync -a $(BOARD_TARGET)/lib/firmware \
				$(BOARD_ROOTFS_FINAL)/target/lib/; \
		fi; \
		;; \
	*) \
		;; \
	esac;
endef

define $(ELDS_BOARD)-finalize
	$(call omap2plus-finalize)
endef

#define $(ELDS_BOARD)-append-dtb
#	@cat $(BOARD_BUILD)/$(BOARD_KERNEL_TREE)/arch/$(BOARD_ARCH)/boot/dts/$(BOARD_KERNEL_DT).dtb >> \
#		$(BOARD_BUILD)/$(BOARD_KERNEL_TREE)/arch/$(BOARD_ARCH)/boot/zImage
#	@mkimage -A arm -O linux -T kernel -C none -a 0x82000000 -e 0x82000000 -n "Linux $(ELDS_KERNEL_VERSION)" \
#		-d $(BOARD_BUILD)/$(BOARD_KERNEL_TREE)/arch/$(BOARD_ARCH)/boot/zImage \
#		$(BOARD_BUILD)/$(BOARD_KERNEL_TREE)/arch/$(BOARD_ARCH)/boot/uImage
#	@cp -av $(BOARD_BUILD)/$(BOARD_KERNEL_TREE)/arch/$(BOARD_ARCH)/boot/uImage $(BOARD_TARGET)/boot/
#endef

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
