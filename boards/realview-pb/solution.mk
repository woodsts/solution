#
# This is the GNU Make include file for 'solution'
#
# Copyright (C) 2014 Derald D. Woods
#
# This file is part of the solution project, and is made available
# under the terms of the GNU General Public License version 2
#

BOARD_TYPE := $(ELDS_BOARD)

BOARD_HOSTNAME := realview-pb
BOARD_GETTY_PORT := ttyAMA0

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

BOARD_ROOTFS_TARGETS := $(BOARD_IMAGES)/rootfs.tar $(BOARD_IMAGES)/rootfs.cpio.xz

BOARD_KERNEL_TREE ?= linux

define realview-pb-env
	@printf "BOARD_ARCH                  : $(BOARD_ARCH)\n"
	@printf "BOARD_VENDOR                : $(BOARD_VENDOR)\n"
	@printf "BOARD_OS                    : $(BOARD_OS)\n"
	@printf "BOARD_ABI                   : $(BOARD_ABI)\n"
	@printf "BOARD_HOSTNAME              : $(BOARD_HOSTNAME)\n"
	@printf "BOARD_GETTY_PORT            : $(BOARD_GETTY_PORT)\n"
endef

export BOARD_TYPE
export BOARD_HOSTNAME
export BOARD_GETTY_PORT

