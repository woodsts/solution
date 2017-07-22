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

BOARD_KERNEL_DT ?= versatile-pb

BOARD_KERNEL_TREE ?= linux
BOARD_ROOTFS_TREE ?= buildroot
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

BOARD_ROOTFS_TARGETS := $(BOARD_ROOTFS_FINAL)/images/rootfs.tar $(BOARD_ROOTFS_FINAL)/images/rootfs.cpio.xz

define $(ELDS_BOARD)-env
	@printf "BOARD_ARCH                   : $(BOARD_ARCH)\n"
	@printf "BOARD_VENDOR                 : $(BOARD_VENDOR)\n"
	@printf "BOARD_OS                     : $(BOARD_OS)\n"
	@printf "BOARD_ABI                    : $(BOARD_ABI)\n"
	@printf "BOARD_HOSTNAME               : $(BOARD_HOSTNAME)\n"
	@printf "BOARD_GETTY_PORT             : $(BOARD_GETTY_PORT)\n"
endef

export BOARD_TYPE
export BOARD_HOSTNAME
export BOARD_GETTY_PORT
export BOARD_KERNEL_TREE
export BOARD_KERNEL_DT
