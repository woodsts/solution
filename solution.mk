#
# This is the GNU Make include file for 'solution'
#
# Copyright (C) 2014 Derald D. Woods
#
# This file is part of the solution project, and is made available
# under the terms of the GNU General Public License version 2
#
# References:
#
# ARM Linux [http://www.arm.linux.org.uk/docs/kerncomp.php]
#

ELDS := $(shell readlink -e $(CURDIR))

ELDS_ARCH ?= arm
ELDS_VENDOR ?= -unknown
ELDS_OS ?= linux
ELDS_ABI ?= gnueabi
ELDS_CROSS_TUPLE := $(ELDS_ARCH)$(ELDS_VENDOR)-$(ELDS_OS)-$(ELDS_ABI)
ELDS_CROSS_COMPILE := $(ELDS_CROSS_TUPLE)-
ELDS_CROSS_PARAMS := ARCH=$(ELDS_ARCH) CROSS_COMPILE=$(ELDS_CROSS_COMPILE)

ELDS_SCM := $(ELDS)/scm
ELDS_PATCHES := $(ELDS)/patches

ELDS_TOOLCHAIN := $(ELDS)/toolchain/$(ELDS_CROSS_TUPLE)
ELDS_TOOLCHAIN_BUILD := $(ELDS)/toolchain/build/$(ELDS_CROSS_TUPLE)
ELDS_TOOLCHAIN_CONFIG := $(ELDS_TOOLCHAIN_BUILD)/.config

CMD := $(shell echo $(ELDS) > $(ELDS)/.solution)
CMD := $(shell echo $(ELDS_CROSS_TUPLE) > $(ELDS)/.cross-tuple)

export ELDS
