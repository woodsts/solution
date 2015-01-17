#
# This is the GNU Make Makefile for 'solution'
#
# Copyright (C) 2014 Derald D. Woods
#
# This file is part of the solution project, and is made available
# under the terms of the GNU General Public License version 2
#

include solution.mk

.PHONY: all
all: usage

.PHONY: usage
usage:
	@printf "USAGE: make <solution|usage|[...]>\n"

# Primary make target for 'solution'
.PHONY: solution
solution: toolchain rootfs kernel bootloader

# Restore any downloaded files that have been previously archived
.PHONY: restore
restore:
	@mkdir -p $(ELDS)/toolchain/tarballs
	@if [ -d $(ELDS_ARCHIVE)/toolchain/tarballs ]; then \
		for f in $(ELDS_TOOLCHAIN_SOURCES); do \
			if [ -f $(ELDS_ARCHIVE)/toolchain/tarballs/$$f ]; then \
				rsync -a $(ELDS_ARCHIVE)/toolchain/tarballs/$$f $(ELDS)/toolchain/tarballs/; \
			fi; \
		done; \
	fi
	@mkdir -p $(ELDS)/rootfs/tarballs
	@if [ -d $(ELDS_ARCHIVE)/rootfs/tarballs ]; then \
		for f in $(ELDS_ROOTFS_SOURCES); do \
			if [ -f $(ELDS_ARCHIVE)/rootfs/tarballs/$$f ]; then \
				rsync -a $(ELDS_ARCHIVE)/rootfs/tarballs/$$f $(ELDS)/rootfs/tarballs/; \
			fi; \
		done; \
	fi

# Store any downloaded files
.PHONY: archive
archive:
	@mkdir -p $(ELDS_ARCHIVE)/toolchain
	@if [ -d $(ELDS)/toolchain/tarballs ]; then \
		for f in $(ELDS_TOOLCHAIN_SOURCES); do \
			if [ -f $(ELDS)/toolchain/tarballs/$$f ]; then \
				rsync -a $(ELDS)/toolchain/tarballs/$$f $(ELDS_ARCHIVE)/toolchain/tarballs/; \
			fi; \
		done; \
	fi
	@mkdir -p $(ELDS_ARCHIVE)/rootfs
	@if [ -d $(ELDS)/rootfs/tarballs ]; then \
		for f in $(ELDS_ROOTFS_SOURCES); do \
			if [ -f $(ELDS)/rootfs/tarballs/$$f ]; then \
				rsync -a $(ELDS)/rootfs/tarballs/$$f $(ELDS_ARCHIVE)/rootfs/tarballs/; \
			fi; \
		done; \
	fi

# Initialize and update(clone/pull) Git Submodules
.PHONY: scm
scm:
	@git submodule init
	@git submodule update

# Run 'git submodule' with option
scm-%:
	@git submodule $(*F)

# Test for Git Submodule's existence
%-check:
	$(call scm-check)

# Documentation via AsciiDoc
.PHONY: doc
doc: $(ELDS)/doc/solution.pdf

$(ELDS)/doc/solution.pdf: $(ELDS)/doc/solution.txt
	@if [ -f "$(shell which a2x)" ]; then \
		a2x -v -f pdf -L $(ELDS)/doc/solution.txt; \
	else \
		printf "***** AsciiDoc is NOT installed! *****\n"; \
		exit 1; \
	fi

# Create bootloader configuration for embedded target board
.PHONY: bootloader-config
bootloader-config: $(BOARD_BOOTLOADER_CONFIG)

$(BOARD_BOOTLOADER_CONFIG):
	$(call $(ELDS_BOARD)-bootloader-config)

# Build bootloader for embedded target board
.PHONY: bootloader
bootloader: $(BOARD_BOOTLOADER_TARGETS)

$(BOARD_BOOTLOADER_TARGETS): $(ELDS_TOOLCHAIN_TARGETS)
	@$(MAKE) u-boot-check
	@$(MAKE) bootloader-config
	$(call $(ELDS_BOARD)-bootloader)

# Run 'make bootloader' with options
bootloader-%: $(BOARD_BOOTLOADER_CONFIG)
	$(call $(ELDS_BOARD)-bootloader)

# Remove targets
.PHONY: bootloader-rm
bootloader-rm:
	$(RM) $(BOARD_BOOTLOADER_TARGETS)

# Toolchain build tool (ct-ng) via crostool-NG
.PHONY: toolchain-builder
toolchain-builder: $(ELDS)/toolchain/builder/ct-ng

$(ELDS)/toolchain/builder/ct-ng:
	@$(MAKE) crosstool-ng-check
	@if ! [ -d $(shell dirname $@) ]; then \
		mkdir -p $(ELDS)/toolchain; \
		cp -a $(ELDS_SCM)/crosstool-ng $(ELDS)/toolchain/builder; \
	fi
	@cd $(ELDS)/toolchain/builder; \
	if ! [ -f .crosstool-ng-patched ]; then \
		for f in $(shell ls $(ELDS_PATCHES)/crosstool-ng/*.patch); do \
			patch -p1 < $$f; \
		done; \
		touch .crosstool-ng-patched; \
	fi; \
	./bootstrap; \
	./configure --enable-local; \
	sed -i s,-dirty,, $(ELDS)/toolchain/builder/Makefile; \
	$(MAKE)
	@if ! [ -f $@ ]; then \
		printf "***** crosstool-NG build FAILED! *****\n"; \
		exit 2; \
	fi

# Restore existing toolchain configuration for embedded target board
.PHONY: toolchain-config
toolchain-config: $(ELDS_TOOLCHAIN_CONFIG)

$(ELDS_TOOLCHAIN_CONFIG): $(BOARD_TOOLCHAIN_CONFIG)
	@mkdir -p $(ELDS_TOOLCHAIN_BUILD)
	@cat $< > $@
	@$(MAKE) toolchain-builder

# Build toolchain for embedded target board
.PHONY: toolchain
toolchain: $(ELDS_TOOLCHAIN_TARGETS)

$(ELDS_TOOLCHAIN_TARGETS):
	@$(MAKE) linux-check
	@if ! [ "$(ELDS_KERNEL_SCM_VERSION)" = "$(ELDS_KERNEL_GIT_VERSION)" ]; then \
		printf "***** WARNING 'Linux' HAS DIFFERENT VERSION *****\n"; \
		sleep 3; \
	fi
	$(MAKE) toolchain-build
	@$(MAKE) archive

# Run toolchain build tool (ct-ng) with options
toolchain-%: $(ELDS_TOOLCHAIN_CONFIG)
	@$(MAKE) restore
	@cd $(ELDS_TOOLCHAIN_BUILD) && CT_ARCH=$(BOARD_ARCH) ct-ng $(*F)
	@cat $< > $(BOARD_TOOLCHAIN_CONFIG)

# Restore existing rootfs configuration for embedded target board
.PHONY: rootfs-config
rootfs-config: $(ELDS_ROOTFS_CONFIG)

$(ELDS_ROOTFS_CONFIG): $(BOARD_ROOTFS_CONFIG)
	@mkdir -p $(ELDS_ROOTFS_BUILD)
	@cat $< > $@

# Build rootfs for embedded target board
.PHONY: rootfs
rootfs: $(ELDS_ROOTFS_TARGETS)

$(ELDS_ROOTFS_TARGETS): $(ELDS_TOOLCHAIN_TARGETS)
	@$(MAKE) restore
	@$(MAKE) buildroot-check
	@$(MAKE) rootfs-config
	@if ! [ "$(ELDS_ROOTFS_SCM_VERSION)" = "$(ELDS_ROOTFS_GIT_VERSION)" ]; then \
		printf "***** WARNING 'buildroot' HAS DIFFERENT VERSION *****\n"; \
		sleep 3; \
	fi
	$(MAKE) -C $(ELDS_ROOTFS_SCM) O=$(ELDS_ROOTFS_BUILD)
	$(call $(ELDS_BOARD)-rootfs-finalize)
	@$(MAKE) archive

# Run 'make rootfs' with options
rootfs-%: $(ELDS_ROOTFS_CONFIG)
	@$(MAKE) restore
	$(MAKE) -C $(ELDS_SCM)/buildroot O=$(ELDS_ROOTFS_BUILD) $(*F)
	@cat $< > $(BOARD_ROOTFS_CONFIG)

# Restore existing kernel configuration for embedded target board
.PHONY: kernel-config
kernel-config: $(ELDS_KERNEL_CONFIG)

$(ELDS_KERNEL_CONFIG): $(BOARD_KERNEL_CONFIG)
	@mkdir -p $(ELDS_KERNEL_BUILD)
	@cat $< > $@

# Build kernel for embedded target board
.PHONY: kernel
kernel: $(ELDS_KERNEL_TARGETS)

$(ELDS_KERNEL_TARGETS): $(ELDS_TOOLCHAIN_TARGETS)
	@$(MAKE) linux-check
	@$(MAKE) kernel-config
	@mkdir -p $(ELDS_KERNEL_BOOT)
	@mkdir -p $(ELDS_ROOTFS_BUILD)/target/boot
	@if ! [ "$(ELDS_KERNEL_SCM_VERSION)" = "$(ELDS_KERNEL_GIT_VERSION)" ]; then \
		printf "***** WARNING 'Linux' HAS DIFFERENT VERSION *****\n"; \
		sleep 3; \
	fi
	$(MAKE) -j 2 -C $(ELDS_KERNEL_SCM) O=$(ELDS_KERNEL_BUILD) $(ELDS_CROSS_PARAMS) zImage \
		LOCALVERSION=$(ELDS_KERNEL_LOCALVERSION)
	@if [ -f $(ELDS_KERNEL_BOOT)/zImage ]; then \
		$(RM) $(ELDS_ROOTFS_BUILD)/target/boot/uImage-*; \
		$(RM) $(ELDS_ROOTFS_BUILD)/target/boot/zImage-*; \
		$(RM) $(ELDS_ROOTFS_BUILD)/target/boot/System.map-*; \
		cp -av $(ELDS_KERNEL_BOOT)/zImage $(ELDS_ROOTFS_BUILD)/target/boot/zImage-$(ELDS_KERNEL_VERSION); \
	        cp -av $(ELDS_KERNEL_SYSMAP) $(ELDS_ROOTFS_BUILD)/target/boot/System.map-$(ELDS_KERNEL_VERSION); \
		mkimage -A arm -O linux -T kernel -C none -a 0x80008000 -e 0x80008000 -n "Linux $(ELDS_KERNEL_VERSION)" \
			-d $(ELDS_KERNEL_BOOT)/zImage $(ELDS_ROOTFS_BUILD)/target/boot/uImage-$(ELDS_KERNEL_VERSION); \
		cd $(ELDS_ROOTFS_BUILD)/target/boot && \
			ln -sf uImage-$(ELDS_KERNEL_VERSION) uImage && \
			ln -sf zImage-$(ELDS_KERNEL_VERSION) zImage && \
			ln -sf System.map-$(ELDS_KERNEL_VERSION) System.map; \
	else \
		printf "***** Linux $(ELDS_KERNEL_VERSION) zImage build FAILED! *****\n"; \
		exit 2; \
	fi
ifdef BOARD_KERNEL_DT
	$(MAKE) -j 2 -C $(ELDS_KERNEL_SCM) O=$(ELDS_KERNEL_BUILD) $(ELDS_CROSS_PARAMS) $(BOARD_KERNEL_DT).dtb \
		LOCALVERSION=$(ELDS_KERNEL_LOCALVERSION)
	@if [ -f $(ELDS_KERNEL_DTB) ]; then \
		$(RM) $(ELDS_ROOTFS_BUILD)/target/boot/*.dtb; \
		cp -av $(ELDS_KERNEL_DTB) $(ELDS_ROOTFS_BUILD)/target/boot/$(BOARD_KERNEL_DT)-$(ELDS_KERNEL_VERSION).dtb; \
		cd $(ELDS_ROOTFS_BUILD)/target/boot/ && \
			ln -sf $(BOARD_KERNEL_DT)-$(ELDS_KERNEL_VERSION).dtb $(BOARD_KERNEL_DT).dtb; \
	else \
		printf "***** Linux $(ELDS_KERNEL_VERSION) $(LINUX_DT) build FAILED! *****\n"; \
		exit 2; \
	fi
	$(call $(ELDS_BOARD)-kernel-append-dtb)
endif
	$(MAKE) -j 2 -C $(ELDS_KERNEL_SCM) O=$(ELDS_KERNEL_BUILD) $(ELDS_CROSS_PARAMS) modules \
		LOCALVERSION=$(ELDS_KERNEL_LOCALVERSION)
	@$(RM) -r $(ELDS_ROOTFS_BUILD)/target/lib/modules/*
	$(MAKE) -C $(ELDS_KERNEL_SCM) O=$(ELDS_KERNEL_BUILD) $(ELDS_CROSS_PARAMS) modules_install \
		LOCALVERSION=$(ELDS_KERNEL_LOCALVERSION) \
		INSTALL_MOD_PATH=$(ELDS_ROOTFS_BUILD)/target
	@if [ -d $(ELDS_ROOTFS_BUILD)/target/lib/modules ]; then \
		find $(ELDS_ROOTFS_BUILD)/target/lib/modules -type l -exec rm -f {} \; ; \
	fi
	$(MAKE) -C $(ELDS_KERNEL_SCM) O=$(ELDS_KERNEL_BUILD) $(ELDS_CROSS_PARAMS) headers_install \
		LOCALVERSION=$(ELDS_KERNEL_LOCALVERSION) \
		INSTALL_HDR_PATH=$(ELDS_ROOTFS_BUILD)/staging/usr/include

# Run Linux kernel build with options
kernel-%: $(ELDS_KERNEL_CONFIG)
	$(MAKE) -j 2 -C $(ELDS_KERNEL_SCM) O=$(ELDS_KERNEL_BUILD) $(ELDS_CROSS_PARAMS) $(*F)
	@cat $< > $(BOARD_KERNEL_CONFIG)

# Remove kernel targets
.PHONY: kernel-rm
kernel-rm:
	$(RM) $(ELDS_KERNEL_TARGETS)

# Selectively remove some solution artifacts
.PHONY: clean
clean: archive
	$(RM) $(ELDS_ROOTFS_TARGETS)
	$(RM) $(ELDS_KERNEL_TARGETS)
	$(RM) $(BOARD_BOOTLOADER_TARGETS)
	$(RM) $(ELDS)/doc/solution.pdf

# Nearly complete removal of solution artifacts
.PHONY: distclean
distclean: clean
	$(RM) -r $(ELDS_ROOTFS_BUILD)
	$(RM) -r $(ELDS_TOOLCHAIN_PATH)
	$(RM) -r $(ELDS_TOOLCHAIN_BUILD)
	$(RM) -r $(ELDS_TOOLCHAIN_BUILDER)

# Print make environment and definitions
.PHONY: env
env:
	$(call solution-env)

