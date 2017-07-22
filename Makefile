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
solution: toolchain bootloader kernel rootfs

# Test for Git source existence
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

# Toolchain build tool (ct-ng) via crostool-NG
.PHONY: toolchain-builder
toolchain-builder: $(ELDS)/toolchain/builder/ct-ng

$(ELDS)/toolchain/builder/ct-ng:
	@$(MAKE) $(ELDS_TOOLCHAIN_TREE)-check
	@if ! [ -d $(shell dirname $@) ]; then \
		mkdir -p $(ELDS)/toolchain; \
		cp -a $(ELDS_SCM)/$(ELDS_TOOLCHAIN_TREE) $(ELDS)/toolchain/builder; \
	fi
	@cd $(ELDS)/toolchain/builder; \
	if ! [ -f .crosstool-ng-patched ]; then \
		for f in $(shell ls $(ELDS_PATCHES)/$(ELDS_TOOLCHAIN_TREE)/*.patch); do \
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
	@mkdir -p $(ELDS_TOOLCHAIN_TARBALLS)
	@cat $< > $@
	@$(MAKE) toolchain-builder

# Build toolchain for embedded target board
.PHONY: toolchain
toolchain: $(ELDS_TOOLCHAIN_TARGET_FINAL)

$(ELDS_TOOLCHAIN_TARGET_FINAL):
	@printf "\n***** [$(ELDS_BOARD)][$(BOARD_TYPE)] $(ELDS_TOOLCHAIN) $(BOARD_TOOLCHAIN_VERSION) *****\n"
	@$(MAKE) $(ELDS_TOOLCHAIN_TREE)-check
	$(MAKE) toolchain-build

# Run toolchain build tool (ct-ng) with options
toolchain-%: $(ELDS_TOOLCHAIN_CONFIG)
	@printf "\n***** [$(ELDS_BOARD)][$(BOARD_TYPE)] make $@ *****\n\n"
	@cd $(ELDS_TOOLCHAIN_BUILD) && CT_ARCH=$(BOARD_ARCH) ct-ng $(*F) && \
		[ "$(*F)" = "build" ] && $(RM) -r $(ELDS_TOOLCHAIN_BUILD)/{$(ELDS_CROSS_TUPLE),src}
	@cat $< > $(BOARD_TOOLCHAIN_CONFIG)

# Create bootloader configuration for embedded target board
.PHONY: bootloader-config
bootloader-config: $(ELDS_BOOTLOADER_CONFIG)

$(ELDS_BOOTLOADER_CONFIG): $(BOARD_BOOTLOADER_CONFIG)
	@mkdir -p $(ELDS_BOOTLOADER_BUILD)
	@cat $< > $@

$(BOARD_BOOTLOADER_CONFIG):
	$(call $(ELDS_BOARD)-bootloader-defconfig)
	@cat $(ELDS_BOOTLOADER_CONFIG) > $@

# Build bootloader for embedded target board
.PHONY: bootloader
bootloader: $(ELDS_BOOTLOADER_TARGET_FINAL)

$(ELDS_BOOTLOADER_TARGET_FINAL): $(ELDS_TOOLCHAIN_TARGETS)
	@printf "\n***** [$(ELDS_BOARD)][$(BOARD_TYPE)] $(ELDS_BOOTLOADER) $(BOARD_BOOTLOADER_VERSION) *****\n\n"
	@$(MAKE) $(ELDS_BOOTLOADER_TREE)-check
	@$(MAKE) bootloader-config
	$(call $(ELDS_BOARD)-bootloader)
	$(call $(ELDS_BOARD)-finalize)

# Run 'make bootloader' with options
bootloader-%: $(BOARD_BOOTLOADER_CONFIG)
	@printf "\n***** [$(ELDS_BOARD)][$(BOARD_TYPE)] make $@ *****\n\n"
	$(call $(ELDS_BOARD)-bootloader)
	$(call $(ELDS_BOARD)-finalize)

# Remove targets
.PHONY: bootloader-rm
bootloader-rm:
	$(RM) $(BOARD_BOOTLOADER_TARGETS)

# Restore existing kernel configuration for embedded target board
.PHONY: kernel-config
kernel-config: $(ELDS_KERNEL_CONFIG)

$(ELDS_KERNEL_CONFIG): $(BOARD_KERNEL_CONFIG)
	@mkdir -p $(ELDS_KERNEL_BUILD)
	@cat $< > $@

# Build kernel for embedded target board
.PHONY: kernel
kernel: $(ELDS_KERNEL_TARGET_FINAL)

$(ELDS_KERNEL_TARGET_FINAL): $(ELDS_TOOLCHAIN_TARGETS)
	@printf "\n***** [$(ELDS_BOARD)][$(BOARD_TYPE)] $(ELDS_KERNEL) $(ELDS_KERNEL_VERSION) *****\n\n"
	@$(MAKE) $(ELDS_KERNEL_TREE)-check
	@$(MAKE) kernel-config
	@mkdir -p $(ELDS_KERNEL_BOOT)
	@mkdir -p $(ELDS_ROOTFS_BUILD)/target/boot
	@printf "\n***** [$(ELDS_BOARD)][$(BOARD_TYPE)] make kernel zImage *****\n\n"
	$(MAKE) -j 2 -C $(ELDS_KERNEL_SCM) O=$(ELDS_KERNEL_BUILD) $(ELDS_CROSS_PARAMS) zImage \
		LOCALVERSION=$(ELDS_KERNEL_LOCALVERSION)
	@if [ -f $(ELDS_KERNEL_BOOT)/zImage ]; then \
		$(RM) $(ELDS_ROOTFS_BUILD)/target/boot/uImage; \
		$(RM) $(ELDS_ROOTFS_BUILD)/target/boot/zImage; \
		$(RM) $(ELDS_ROOTFS_BUILD)/target/boot/System.map; \
	        cp -av $(ELDS_KERNEL_SYSMAP) $(ELDS_ROOTFS_BUILD)/target/boot/System.map; \
		cp -av $(ELDS_KERNEL_BOOT)/zImage $(ELDS_ROOTFS_BUILD)/target/boot/zImage; \
		printf "\n***** [$(ELDS_BOARD)][$(BOARD_TYPE)] make kernel uImage *****\n\n"; \
		mkimage -A arm -O linux -T kernel -C none -a 0x82000000 -e 0x82000000 -n "Linux $(ELDS_KERNEL_VERSION)" \
			-d $(ELDS_KERNEL_BOOT)/zImage $(ELDS_ROOTFS_BUILD)/target/boot/uImage; \
	else \
		printf "***** Linux $(ELDS_KERNEL_VERSION) zImage build FAILED! *****\n"; \
		exit 2; \
	fi
	@printf "\n***** [$(ELDS_BOARD)][$(BOARD_TYPE)] make kernel device-tree ($(BOARD_KERNEL_DT)) *****\n\n"
	$(MAKE) -j 2 -C $(ELDS_KERNEL_SCM) O=$(ELDS_KERNEL_BUILD) $(ELDS_CROSS_PARAMS) $(BOARD_KERNEL_DT).dtb \
		LOCALVERSION=$(ELDS_KERNEL_LOCALVERSION)
	@if [ -f $(ELDS_KERNEL_DTB) ]; then \
		$(RM) $(ELDS_ROOTFS_BUILD)/target/boot/$(BOARD_KERNEL_DT).dtb; \
		cp -av $(ELDS_KERNEL_DTB) $(ELDS_ROOTFS_BUILD)/target/boot/; \
	else \
		printf "***** Linux $(ELDS_KERNEL_VERSION) $(LINUX_DT) build FAILED! *****\n"; \
		exit 2; \
	fi
ifdef ELDS_APPEND_DTB
	$(call $(ELDS_BOARD)-append-dtb)
endif
ifdef BOARD_KERNEL_DT_OTHER
	@printf "\n***** [$(ELDS_BOARD)][$(BOARD_TYPE)] make kernel device-tree (other) *****\n\n"
	$(MAKE) -j 2 -C $(ELDS_KERNEL_SCM) O=$(ELDS_KERNEL_BUILD) $(ELDS_CROSS_PARAMS) $(BOARD_KERNEL_DT_OTHER).dtb \
		LOCALVERSION=$(ELDS_KERNEL_LOCALVERSION)
	@if [ -f $(ELDS_KERNEL_DTB_OTHER) ]; then \
		$(RM) $(ELDS_ROOTFS_BUILD)/target/boot/$(BOARD_KERNEL_DT_OTHER).dtb; \
		cp -av $(ELDS_KERNEL_DTB_OTHER) $(ELDS_ROOTFS_BUILD)/target/boot/; \
	else \
		printf "***** Linux $(ELDS_KERNEL_VERSION) $(LINUX_DT_OTHER) build FAILED! *****\n"; \
		exit 2; \
	fi
endif
	@printf "\n***** [$(ELDS_BOARD)][$(BOARD_TYPE)] make kernel modules *****\n\n"
	$(MAKE) -j 2 -C $(ELDS_KERNEL_SCM) O=$(ELDS_KERNEL_BUILD) $(ELDS_CROSS_PARAMS) modules \
		LOCALVERSION=$(ELDS_KERNEL_LOCALVERSION)
	@$(RM) -r $(BOARD_TARGET)/lib/modules
	@printf "\n***** [$(ELDS_BOARD)][$(BOARD_TYPE)] make kernel modules_install *****\n\n"
	$(MAKE) -C $(ELDS_KERNEL_SCM) O=$(ELDS_KERNEL_BUILD) $(ELDS_CROSS_PARAMS) modules_install \
		LOCALVERSION=$(ELDS_KERNEL_LOCALVERSION) \
		INSTALL_MOD_PATH=$(BOARD_TARGET)
	@if [ -d $(BOARD_TARGET)/lib/modules ]; then \
		find $(BOARD_TARGET)/lib/modules -type l -exec rm -f {} \; ; \
	fi
	@printf "\n***** [$(ELDS_BOARD)][$(BOARD_TYPE)] make kernel headers_install *****\n\n"
	$(MAKE) -C $(ELDS_KERNEL_SCM) O=$(ELDS_KERNEL_BUILD) $(ELDS_CROSS_PARAMS) headers_install \
		LOCALVERSION=$(ELDS_KERNEL_LOCALVERSION) \
		INSTALL_HDR_PATH=$(ELDS_ROOTFS_BUILD)/staging/usr/include
	$(call $(ELDS_BOARD)-finalize)

# Run Linux kernel build with options
kernel-%: $(ELDS_KERNEL_CONFIG)
	@printf "\n***** [$(ELDS_BOARD)][$(BOARD_TYPE)] make $@ *****\n\n"
	$(MAKE) -j 2 -C $(ELDS_KERNEL_SCM) O=$(ELDS_KERNEL_BUILD) $(ELDS_CROSS_PARAMS) $(*F)
	@if [ "$(*F)" = "$(BOARD_KERNEL_DT).dtb" ]; then \
		if [ -f $(ELDS_KERNEL_DTB) ]; then \
			printf "\n***** [$(ELDS_BOARD)][$(BOARD_TYPE)] make kernel device-tree ($(BOARD_KERNEL_DT)) *****\n\n"; \
			$(RM) $(ELDS_ROOTFS_BUILD)/target/boot/$(BOARD_KERNEL_DT).dtb; \
			$(RM) $(BOARD_ROOTFS_FINAL)/target/boot/$(BOARD_KERNEL_DT).dtb; \
			cp -av $(ELDS_KERNEL_DTB) $(ELDS_ROOTFS_BUILD)/target/boot/; \
			cp -av $(ELDS_KERNEL_DTB) $(BOARD_ROOTFS_FINAL)/target/boot/; \
		else \
			printf "***** Linux $(ELDS_KERNEL_VERSION) $(LINUX_DT) build FAILED! *****\n"; \
			exit 2; \
		fi; \
	fi
ifdef BOARD_KERNEL_DT_OTHER
	@if [ "$(*F)" = "$(BOARD_KERNEL_DT_OTHER).dtb" ]; then \
		if [ -f $(ELDS_KERNEL_DTB_OTHER) ]; then \
			printf "\n***** [$(ELDS_BOARD)][$(BOARD_TYPE)] make kernel device-tree ($(BOARD_KERNEL_DT_OTHER)) *****\n\n"; \
			$(RM) $(ELDS_ROOTFS_BUILD)/target/boot/$(BOARD_KERNEL_DT_OTHER).dtb; \
			$(RM) $(BOARD_ROOTFS_FINAL)/target/boot/$(BOARD_KERNEL_DT_OTHER).dtb; \
			cp -av $(ELDS_KERNEL_DTB_OTHER) $(ELDS_ROOTFS_BUILD)/target/boot/; \
			cp -av $(ELDS_KERNEL_DTB_OTHER) $(BOARD_ROOTFS_FINAL)/target/boot/; \
		else \
			printf "***** Linux $(ELDS_KERNEL_VERSION) $(LINUX_DT_OTHER) build FAILED! *****\n"; \
			exit 2; \
		fi; \
	fi
endif
	@cat $< > $(BOARD_KERNEL_CONFIG)
	$(call $(ELDS_BOARD)-finalize)

# Remove kernel targets
.PHONY: kernel-rm
kernel-rm:
	$(RM) $(ELDS_KERNEL_TARGETS)

# Restore existing rootfs configuration for embedded target board
.PHONY: rootfs-config
rootfs-config: $(ELDS_ROOTFS_CONFIG)

$(ELDS_ROOTFS_CONFIG): $(BOARD_ROOTFS_CONFIG)
	@mkdir -p $(ELDS_ROOTFS_BUILD)
	@mkdir -p $(ELDS_ROOTFS_TARBALLS)
	@cat $< > $@

# Build rootfs for embedded target board
.PHONY: rootfs
rootfs: $(ELDS_ROOTFS_TARGET_FINAL)

$(ELDS_ROOTFS_TARGET_FINAL): $(ELDS_TOOLCHAIN_TARGETS)
	@printf "\n***** [$(ELDS_BOARD)][$(BOARD_TYPE)] $(ELDS_ROOTFS) $(ELDS_ROOTFS_VERSION) *****\n\n"
	@$(MAKE) $(ELDS_ROOTFS_TREE)-check
	@$(MAKE) rootfs-config
	$(MAKE) -C $(ELDS_ROOTFS_SCM) O=$(ELDS_ROOTFS_BUILD)
	$(call $(ELDS_BOARD)-finalize)

# Run 'make rootfs' with options
rootfs-%: $(ELDS_ROOTFS_CONFIG)
	@printf "\n***** [$(ELDS_BOARD)][$(BOARD_TYPE)] make $@ *****\n\n"
	$(MAKE) -C $(ELDS_SCM)/buildroot O=$(ELDS_ROOTFS_BUILD) $(*F)
	@cat $< > $(BOARD_ROOTFS_CONFIG)
	$(call $(ELDS_BOARD)-finalize)

# Remove rootfs targets
.PHONY: rootfs-rm
rootfs-rm:
	$(RM) $(ELDS_ROOTFS_TARGETS)

# Selectively remove some solution artifacts
.PHONY: clean
clean: bootloader-rm kernel-rm rootfs-rm
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

# Essential Embedded Linux Development Packages [Ubuntu 15.04+]
.PHONY: build-essential
build-essential:
	@if [ -f /usr/bin/apt-get ]; then \
		sudo apt-get install -y \
			asciidoc \
			autoconf \
			autopoint \
			bash-completion \
			bc \
			bison \
			build-essential \
			ccache \
			chrpath \
			cmake \
			curl \
			cvs \
			device-tree-compiler \
			dia \
			docbook-utils \
			dosfstools \
			exuberant-ctags \
			fakeroot \
			flex \
			flip \
			gawk \
			gcc-doc \
			gcc-multilib \
			gettext \
			git-core \
			gitg \
			gitk \
			gperf \
			help2man \
			indent \
			inkscape \
			intltool \
			libexpat1-dev \
			libglade2-dev \
			libglib2.0-dev \
			libgtk2.0-dev \
			libncurses5-dev \
			libreadline-dev \
			libssl-dev \
			libtool \
			libtool-bin \
			libusb-1.0-0-dev \
			libx11-dev \
			lzma \
			lzop \
			man-db \
			manpages-dev \
			manpages-posix-dev \
			mc \
			mercurial \
			mtd-utils \
			pkg-config \
			qemu \
			rsync \
			ssh \
			subversion \
			texinfo \
			tftp-hpa \
			tig \
			tree \
			tshark \
			u-boot-tools \
			uucp \
			unzip \
			vim \
			wget \
			whiptail \
			whois \
			wireshark \
			xz-utils \
			zip; \
		if [ "$(shell uname -m)" = "x86_64" ]; then \
			sudo apt-get install -y libc6-dev-i386; \
		fi; \
	fi
