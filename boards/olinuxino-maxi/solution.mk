#
# This is the GNU Make include file for 'solution'
#
# Copyright (C) 2017 Derald D. Woods
#
# This file is part of the solution project, and is made available
# under the terms of the GNU General Public License version 2
#

BOARD_HOSTNAME := $(ELDS_BOARD)

BOARD_GETTY_PORT ?= ttyAMA0

BOARD_KERNEL_DT ?= imx23-olinuxino

BOARD_KERNEL_TREE ?= linux
BOARD_ROOTFS_TREE ?= buildroot
BOARD_BOOTLOADER_TREE ?= u-boot
BOARD_TOOLCHAIN_TREE ?= crosstool-ng

BOARD_TYPE := $(ELDS_BOARD)

BOARD_ARCH ?= arm
BOARD_VENDOR ?= 926ejs
BOARD_OS ?= linux
BOARD_ABI ?= gnueabi
BOARD_CROSS_TUPLE := $(BOARD_ARCH)-$(BOARD_VENDOR)-$(BOARD_OS)-$(BOARD_ABI)

BOARD_CONFIG := $(ELDS)/boards/$(BOARD_TYPE)/config
BOARD_TOOLCHAIN_CONFIG := $(BOARD_CONFIG)/crosstool-ng/config
BOARD_ROOTFS_CONFIG := $(BOARD_CONFIG)/buildroot/config
BOARD_KERNEL_CONFIG := $(BOARD_CONFIG)/$(BOARD_KERNEL_TREE)/config

BOARD_ROOTFS := $(ELDS)/rootfs/$(BOARD_TYPE)/$(BOARD_CROSS_TUPLE)
BOARD_BUILD := $(BOARD_ROOTFS)/build
BOARD_IMAGES := $(BOARD_ROOTFS)/images
BOARD_TARGET := $(BOARD_ROOTFS)/target
BOARD_ROOTFS_FINAL := $(BOARD_ROOTFS)

BOARD_ROOTFS_TARGETS := $(BOARD_ROOTFS_FINAL)/images/rootfs.tar $(BOARD_ROOTFS_FINAL)/images/rootfs.ubifs

# Bootloader Definitions
BOARD_BOOTLOADER := U-Boot
BOARD_BOOTLOADER_BUILD := $(BOARD_BUILD)/u-boot-$(ELDS_BOARD)
BOARD_BOOTLOADER_TARGET := $(BOARD_TARGET)/boot
BOARD_BOOTLOADER_SCM := $(ELDS_SCM)/$(BOARD_BOOTLOADER_TREE)
BOARD_BOOTLOADER_VERSION := $(shell cd $(BOARD_BOOTLOADER_SCM) && git describe --long --dirty 2>/dev/null | cut -d v -f 2)
ifeq ($(shell echo $(BOARD_BOOTLOADER_VERSION) | cut -d '-' -f 2),0)
BOARD_BOOTLOADER_VERSION := $(shell cd $(BOARD_BOOTLOADER_SCM) && git describe --dirty 2>/dev/null | cut -d v -f 2)
endif
BOARD_BOOTLOADER_CONFIG := $(BOARD_CONFIG)/u-boot/config
BOARD_BOOTLOADER_SYSMAP := $(BOARD_BOOTLOADER_BUILD)/System.map
BOARD_BOOTLOADER_BINARY_IMAGE := $(BOARD_BOOTLOADER_BUILD)/u-boot.sd
BOARD_BOOTLOADER_TARGETS := $(BOARD_ROOTFS_FINAL)/target/boot/u-boot.sd
# Special case (this is a different(old) type of SOC)
ELDS_BOOTLOADER_TARGET_FINAL ?= $(BOARD_ROOTFS_FINAL)/target/boot/u-boot.sd

define $(ELDS_BOARD)-bootloader-defconfig
	@mkdir -p $(BOARD_BOOTLOADER_BUILD)
	$(MAKE) -C $(BOARD_BOOTLOADER_SCM) O=$(BOARD_BOOTLOADER_BUILD) $(ELDS_CROSS_PARAMS) distclean
	$(MAKE) -C $(BOARD_BOOTLOADER_SCM) O=$(BOARD_BOOTLOADER_BUILD) $(ELDS_CROSS_PARAMS) mx23_olinuxino_defconfig
endef

define $(ELDS_BOARD)-bootloader
	@case "$@" in \
	$(BOARD_ROOTFS_FINAL)/target/boot/u-boot.sd)\
		printf "***** U-Boot $(BOARD_BOOTLOADER_VERSION) 'make $@' *****\n"; \
		$(MAKE) -C $(BOARD_BOOTLOADER_SCM) O=$(BOARD_BOOTLOADER_BUILD) $(ELDS_CROSS_PARAMS) u-boot.sb; \
		if ! [ -f $(BOARD_BOOTLOADER_BUILD)/u-boot.sb ]; then \
			printf "***** U-Boot $(BOARD_BOOTLOADER_VERSION) $(BOARD_BOOTLOADER_BUILD)/u-boot.sb build FAILED! *****\n"; \
			exit 2; \
		fi; \
		$(BOARD_BOOTLOADER_BUILD)/tools/mxsboot sd $(BOARD_BOOTLOADER_BUILD)/u-boot.sb $(BOARD_BOOTLOADER_BINARY_IMAGE); \
		if ! [ -f $(BOARD_BOOTLOADER_BINARY_IMAGE) ]; then \
			printf "***** U-Boot $(BOARD_BOOTLOADER_VERSION) $(BOARD_BOOTLOADER_BINARY_IMAGE) build FAILED! *****\n"; \
			exit 2; \
		fi; \
		mkdir -p $(BOARD_BOOTLOADER_TARGET); \
		$(RM) $(BOARD_BOOTLOADER_TARGET)/u-boot*; \
		cp -av $(BOARD_BOOTLOADER_BINARY_IMAGE) $(BOARD_BOOTLOADER_TARGET)/; \
		;;\
	*)\
		printf "***** U-Boot $(BOARD_BOOTLOADER_VERSION) 'make $(*F)' *****\n"; \
		$(MAKE) -C $(BOARD_BOOTLOADER_SCM) O=$(BOARD_BOOTLOADER_BUILD) $(ELDS_CROSS_PARAMS) $(*F); \
		if ! [ "$(*F)" = "distclean" ]; then \
			cat $(ELDS_BOOTLOADER_CONFIG) > $(BOARD_BOOTLOADER_CONFIG); \
		fi; \
	esac;
endef

define $(ELDS_BOARD)-env
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
export BOARD_HOSTNAME
export BOARD_GETTY_PORT
export BOARD_BOOTLOADER_TREE
export BOARD_KERNEL_TREE
export BOARD_KERNEL_DT
