#
# This is the GNU Make include file for 'solution'
#
# Copyright (C) 2014 Derald D. Woods
#
# This file is part of the solution project, and is made available
# under the terms of the GNU General Public License version 2
#

ELDS_HOSTNAME := versatile-pb
ELDS_GETTY_PORT := ttyAMA0

ELDS_ARCH ?= arm
ELDS_VENDOR ?= -unknown
ELDS_OS ?= linux
ELDS_ABI ?= gnueabi

BOARD_TOOLCHAIN_CONFIG := $(ELDS)/boards/$(ELDS_BOARD)/config/crosstool-ng/config
BOARD_ROOTFS_CONFIG := $(ELDS)/boards/$(ELDS_BOARD)/config/buildroot/config
BOARD_KERNEL_CONFIG := $(ELDS)/boards/$(ELDS_BOARD)/config/linux/config

BOARD_KERNEL_DT := versatile-pb

# Bootloader Definitions
BOARD_BOOTLOADER := $(ELDS)/rootfs/$(ELDS_BOARD)/$(ELDS_ARCH)$(ELDS_VENDOR)-$(ELDS_OS)-$(ELDS_ABI)/build/u-boot
BOARD_BOOTLOADER_ROOTFS := $(ELDS)/rootfs/$(ELDS_BOARD)/$(ELDS_ARCH)$(ELDS_VENDOR)-$(ELDS_OS)-$(ELDS_ABI)/target/boot
BOARD_BOOTLOADER_SCM := $(ELDS_SCM)/u-boot
BOARD_BOOTLOADER_SCM_VERSION := $(shell cat $(ELDS_SCM)/.u-boot 2>/dev/null)
BOARD_BOOTLOADER_GIT_VERSION := $(shell cd $(BOARD_BOOTLOADER_SCM) && git describe --long 2>/dev/null)
BOARD_BOOTLOADER_VERSION := $(shell cd $(BOARD_BOOTLOADER_SCM) && git describe 2>/dev/null | cut -d v -f 2)
BOARD_BOOTLOADER_BUILD := $(BOARD_BOOTLOADER)
BOARD_BOOTLOADER_CONFIG := $(BOARD_BOOTLOADER)/include/config.mk
BOARD_BOOTLOADER_SYSMAP := $(BOARD_BOOTLOADER)/System.map
BOARD_BOOTLOADER_BINARY := $(BOARD_BOOTLOADER)/u-boot.bin
BOARD_BOOTLOADER_TARGETS := $(BOARD_BOOTLOADER_BINARY)

define versatile-pb-bootloader-config
	@mkdir -p $(BOARD_BOOTLOADER_BUILD)
	$(MAKE) -C $(BOARD_BOOTLOADER_SCM) O=$(BOARD_BOOTLOADER_BUILD) $(ELDS_CROSS_PARAMS) versatilepb_config
endef

define versatile-pb-bootloader
	@if ! [ "$(BOARD_BOOTLOADER_SCM_VERSION)" = "$(BOARD_BOOTLOADER_GIT_VERSION)" ]; then \
		printf "***** WARNING 'U-Boot' HAS DIFFERENT VERSION *****\n"; \
		sleep 3; \
	fi
	@if [ "$@" = "$(BOARD_BOOTLOADER_TARGETS)" ]; then \
		$(MAKE) -j 2 -C $(BOARD_BOOTLOADER_SCM) O=$(BOARD_BOOTLOADER_BUILD) $(ELDS_CROSS_PARAMS); \
		if ! [ -f $(BOARD_BOOTLOADER_BINARY) ]; then \
			printf "***** U-Boot $(BOARD_BOOTLOADER_VERSION) build FAILED! *****\n"; \
			exit 2; \
		else \
			mkdir -p $(BOARD_BOOTLOADER_ROOTFS); \
			$(RM) $(BOARD_BOOTLOADER_ROOTFS)/u-boot-*; \
			cp -av $(BOARD_BOOTLOADER_BINARY) $(BOARD_BOOTLOADER_ROOTFS)/u-boot-$(BOARD_BOOTLOADER_VERSION).bin; \
			cd $(BOARD_BOOTLOADER_ROOTFS) && ln -sf u-boot-$(BOARD_BOOTLOADER_VERSION).bin u-boot.bin; \
		fi; \
	else \
		$(MAKE) -j 2 -C $(BOARD_BOOTLOADER_SCM) O=$(BOARD_BOOTLOADER_BUILD) $(ELDS_CROSS_PARAMS) $(*F); \
	fi
endef

define versatile-pb-env
	@printf "ELDS_ARCH                   : $(ELDS_ARCH)\n"
	@printf "ELDS_VENDOR                 : $(ELDS_VENDOR)\n"
	@printf "ELDS_OS                     : $(ELDS_OS)\n"
	@printf "ELDS_ABI                    : $(ELDS_ABI)\n"
	@printf "ELDS_HOSTNAME               : $(ELDS_HOSTNAME)\n"
	@printf "ELDS_GETTY_PORT             : $(ELDS_GETTY_PORT)\n"
	@printf "BOARD_BOOTLOADER_VERSION    : $(BOARD_BOOTLOADER_VERSION)\n"
	@printf "BOARD_BOOTLOADER            : $(BOARD_BOOTLOADER)\n"
	@printf "BOARD_BOOTLOADER_BUILD      : $(BOARD_BOOTLOADER_BUILD)\n"
	@printf "BOARD_BOOTLOADER_TARGETS    : $(BOARD_BOOTLOADER_TARGETS)\n"
endef

export ELDS_HOSTNAME
export ELDS_GETTY_PORT

