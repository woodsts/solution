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
BOARD_KERNEL_CONFIG := $(BOARD_CONFIG)/linux/config

BOARD_ROOTFS := $(ELDS)/rootfs/$(BOARD_TYPE)/$(BOARD_ARCH)$(BOARD_VENDOR)-$(BOARD_OS)-$(BOARD_ABI)
BOARD_BUILD := $(BOARD_ROOTFS)/build
BOARD_IMAGES := $(BOARD_ROOTFS)/images
BOARD_TARGET := $(BOARD_ROOTFS)/target
BOARD_ROOTFS_FINAL := $(BOARD_ROOTFS)

BOARD_ROOTFS_TARGETS := $(BOARD_IMAGES)/rootfs.tar

# Bootloader Definitions
BOARD_BOOTLOADER := U-Boot
BOARD_BOOTLOADER_BUILD := $(BOARD_BUILD)/u-boot
BOARD_BOOTLOADER_TARGET := $(BOARD_TARGET)/boot
BOARD_BOOTLOADER_SCM := $(ELDS_SCM)/u-boot
BOARD_BOOTLOADER_SCM_VERSION := $(shell cat $(ELDS_SCM)/.u-boot 2>/dev/null)
BOARD_BOOTLOADER_GIT_VERSION := $(shell cd $(BOARD_BOOTLOADER_SCM) && git describe --long --dirty 2>/dev/null)
BOARD_BOOTLOADER_VERSION := $(shell cd $(BOARD_BOOTLOADER_SCM) && git describe --long --dirty 2>/dev/null | cut -d v -f 2)
BOARD_BOOTLOADER_CONFIG := $(BOARD_BOOTLOADER_BUILD)/include/autoconf.mk
BOARD_BOOTLOADER_SYSMAP := $(BOARD_BOOTLOADER_BUILD)/System.map
BOARD_BOOTLOADER_BINARY_SPL := $(BOARD_BOOTLOADER_BUILD)/MLO
BOARD_BOOTLOADER_BINARY_IMAGE := $(BOARD_BOOTLOADER_BUILD)/u-boot.img
BOARD_BOOTLOADER_TARGETS := $(BOARD_BOOTLOADER_BINARY_SPL) $(BOARD_BOOTLOADER_BINARY_IMAGE)

define omap2plus-bootloader
	@if ! [ "$(BOARD_BOOTLOADER_SCM_VERSION)" = "$(BOARD_BOOTLOADER_GIT_VERSION)" ]; then \
		printf "***** WARNING 'U-Boot' HAS DIFFERENT VERSION *****\n"; \
		sleep 3; \
	fi
	@case "$@" in \
	$(BOARD_BOOTLOADER_BINARY_SPL) | $(BOARD_BOOTLOADER_BINARY_IMAGE))\
		printf "***** U-Boot $(BOARD_BOOTLOADER_VERSION) 'make $@' *****\n"; \
		$(MAKE) -j 2 -C $(BOARD_BOOTLOADER_SCM) O=$(BOARD_BOOTLOADER_BUILD) $(ELDS_CROSS_PARAMS); \
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
		cp -av $(BOARD_BOOTLOADER_BINARY_SPL) $(BOARD_BOOTLOADER_TARGET)/MLO-$(BOARD_BOOTLOADER_VERSION); \
		cp -av $(BOARD_BOOTLOADER_BINARY_IMAGE) $(BOARD_BOOTLOADER_TARGET)/u-boot-$(BOARD_BOOTLOADER_VERSION).img; \
		cd $(BOARD_BOOTLOADER_TARGET) && \
			ln -sf u-boot-$(BOARD_BOOTLOADER_VERSION).img u-boot.img && \
			ln -sf MLO-$(BOARD_BOOTLOADER_VERSION) MLO; \
		;;\
	*)\
		printf "***** U-Boot $(BOARD_BOOTLOADER_VERSION) 'make $(*F)' *****\n"; \
		$(MAKE) -j 2 -C $(BOARD_BOOTLOADER_SCM) O=$(BOARD_BOOTLOADER_BUILD) $(ELDS_CROSS_PARAMS) $(*F); \
	esac;
endef

define omap2plus-rootfs-finalize
	@mkdir -p $(BOARD_ROOTFS_FINAL)/images
	@for f in $(ELDS_ROOTFS_TARGETS); do \
		if [ -f $$f ]; then \
			rsync $$f $(BOARD_ROOTFS_FINAL)/images/; \
		fi; \
	done
	@$(RM) -r $(BOARD_ROOTFS_FINAL)/target
	@mkdir -p $(BOARD_ROOTFS_FINAL)/target/lib
	@if [ -d $(BOARD_TARGET)/boot ]; then \
		rsync -aP $(BOARD_TARGET)/boot \
			$(BOARD_ROOTFS_FINAL)/target/; \
	fi
	@if [ -d $(BOARD_TARGET)/lib/modules ]; then \
		rsync -aP $(BOARD_TARGET)/lib/modules \
			$(BOARD_ROOTFS_FINAL)/target/lib/; \
	fi
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
	@printf "BOARD_BOOTLOADER_VERSION     : $(BOARD_BOOTLOADER_VERSION)\n"
	@printf "BOARD_BOOTLOADER_SCM_VERSION : $(BOARD_BOOTLOADER_SCM_VERSION)\n"
	@printf "BOARD_BOOTLOADER_GIT_VERSION : $(BOARD_BOOTLOADER_GIT_VERSION)\n"
	@printf "BOARD_BOOTLOADER_BUILD       : $(BOARD_BOOTLOADER_BUILD)\n"
	@printf "BOARD_BOOTLOADER_TARGETS     : $(BOARD_BOOTLOADER_TARGETS)\n"
endef

export BOARD_TYPE

