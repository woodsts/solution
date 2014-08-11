#
# This is the GNU Make include file for 'solution'
#
# Copyright (C) 2014 Derald D. Woods
#
# This file is part of the solution project, and is made available
# under the terms of the GNU General Public License version 2
#

BOARD_HOSTNAME := olinuxino-maxi
BOARD_GETTY_PORT := ttyAMA0

BOARD_ARCH ?= arm
BOARD_VENDOR ?= -unknown
BOARD_OS ?= linux
BOARD_ABI ?= gnueabi

BOARD_CONFIG := $(ELDS)/boards/$(ELDS_BOARD)/config
BOARD_TOOLCHAIN_CONFIG := $(BOARD_CONFIG)/crosstool-ng/config
BOARD_ROOTFS_CONFIG := $(BOARD_CONFIG)/buildroot/config
BOARD_KERNEL_CONFIG := $(BOARD_CONFIG)/linux/config

BOARD_ROOTFS := $(ELDS)/rootfs/$(ELDS_BOARD)/$(BOARD_ARCH)$(BOARD_VENDOR)-$(BOARD_OS)-$(BOARD_ABI)
BOARD_BUILD := $(BOARD_ROOTFS)/build
BOARD_IMAGES := $(BOARD_ROOTFS)/images
BOARD_TARGET := $(BOARD_ROOTFS)/target

BOARD_ROOTFS_TARGETS := $(BOARD_IMAGES)/rootfs.tar.xz

BOARD_KERNEL_DT := imx23-olinuxino

# Bootloader Definitions
BOARD_BOOTLOADER := U-Boot
BOARD_BOOTLOADER_BUILD := $(BOARD_BUILD)/u-boot
BOARD_BOOTLOADER_TARGET := $(BOARD_TARGET)/boot
BOARD_BOOTLOADER_SCM := $(ELDS_SCM)/u-boot
BOARD_BOOTLOADER_SCM_VERSION := $(shell cat $(ELDS_SCM)/.u-boot 2>/dev/null)
BOARD_BOOTLOADER_GIT_VERSION := $(shell cd $(BOARD_BOOTLOADER_SCM) && git describe --long 2>/dev/null)
BOARD_BOOTLOADER_VERSION := $(shell cd $(BOARD_BOOTLOADER_SCM) && git describe 2>/dev/null | cut -d v -f 2)
BOARD_BOOTLOADER_CONFIG := $(BOARD_BOOTLOADER_BUILD)/include/config.mk
BOARD_BOOTLOADER_SYSMAP := $(BOARD_BOOTLOADER_BUILD)/System.map
BOARD_BOOTLOADER_BINARY := $(BOARD_BOOTLOADER_BUILD)/u-boot.sd
BOARD_BOOTLOADER_TARGETS := $(BOARD_BOOTLOADER_BINARY)

define olinuxino-maxi-bootloader-config
	@mkdir -p $(BOARD_BOOTLOADER_BUILD)
	$(MAKE) -C $(BOARD_BOOTLOADER_SCM) O=$(BOARD_BOOTLOADER_BUILD) $(ELDS_CROSS_PARAMS) mx23_olinuxino_config
endef

define olinuxino-maxi-bootloader
	@if ! [ "$(BOARD_BOOTLOADER_SCM_VERSION)" = "$(BOARD_BOOTLOADER_GIT_VERSION)" ]; then \
		printf "***** WARNING 'U-Boot' HAS DIFFERENT VERSION *****\n"; \
		sleep 3; \
	fi
	@if [ "$@" = "$(BOARD_BOOTLOADER_TARGETS)" ]; then \
		$(MAKE) -j 2 -C $(BOARD_BOOTLOADER_SCM) O=$(BOARD_BOOTLOADER_BUILD) $(ELDS_CROSS_PARAMS); \
		$(MAKE) -j 2 -C $(BOARD_BOOTLOADER_SCM) O=$(BOARD_BOOTLOADER_BUILD) $(ELDS_CROSS_PARAMS) u-boot.sb; \
		if ! [ -f $(BOARD_BOOTLOADER_BUILD)/u-boot.sb ]; then \
			printf "***** U-Boot $(BOARD_BOOTLOADER_VERSION) build FAILED! *****\n"; \
			exit 2; \
		else \
			mkdir -p $(BOARD_BOOTLOADER_TARGET); \
			$(RM) $(BOARD_BOOTLOADER_TARGET)/u-boot-*; \
			$(BOARD_BOOTLOADER_BUILD)/tools/mxsboot sd $(BOARD_BOOTLOADER_BUILD)/u-boot.sb $(BOARD_BOOTLOADER_BINARY); \
			cp -av $(BOARD_BOOTLOADER_BUILD)/u-boot.sd $(BOARD_BOOTLOADER_TARGET)/u-boot-$(BOARD_BOOTLOADER_VERSION).sd; \
			cd $(BOARD_BOOTLOADER_TARGET) && ln -sf u-boot-$(BOARD_BOOTLOADER_VERSION).sd u-boot.sd; \
		fi; \
	else \
		printf "***** U-Boot $(BOARD_BOOTLOADER_VERSION) 'make $(*F)' *****\n"; \
		$(MAKE) -j 2 -C $(BOARD_BOOTLOADER_SCM) O=$(BOARD_BOOTLOADER_BUILD) $(ELDS_CROSS_PARAMS) $(*F); \
	fi
endef

define olinuxino-maxi-env
	@printf "BOARD_ARCH                   : $(BOARD_ARCH)\n"
	@printf "BOARD_VENDOR                 : $(BOARD_VENDOR)\n"
	@printf "BOARD_OS                     : $(BOARD_OS)\n"
	@printf "BOARD_ABI                    : $(BOARD_ABI)\n"
	@printf "BOARD_HOSTNAME               : $(BOARD_HOSTNAME)\n"
	@printf "BOARD_GETTY_PORT             : $(BOARD_GETTY_PORT)\n"
	@printf "========================================================================\n"
	@printf "BOARD_BOOTLOADER             : $(BOARD_BOOTLOADER)\n"
	@printf "BOARD_BOOTLOADER_VERSION     : $(BOARD_BOOTLOADER_VERSION)\n"
	@printf "BOARD_BOOTLOADER_SCM_VERSION : $(BOARD_BOOTLOADER_SCM_VERSION)\n"
	@printf "BOARD_BOOTLOADER_GIT_VERSION : $(BOARD_BOOTLOADER_GIT_VERSION)\n"
	@printf "BOARD_BOOTLOADER_BUILD       : $(BOARD_BOOTLOADER_BUILD)\n"
	@printf "BOARD_BOOTLOADER_TARGETS     : $(BOARD_BOOTLOADER_TARGETS)\n"
endef

export BOARD_HOSTNAME
export BOARD_GETTY_PORT
