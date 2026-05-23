# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2023 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=daed
PKG_VERSION:=2026.04.27
PKG_WEB_VERSION:=1.27.2
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ksong008/daed.git
PKG_SOURCE_VERSION:=da5f59a21dbdb8f6010d46c167774b4e18d2410c
PKG_MIRROR_HASH:=0486b77c375639108e97d9b2db57e2f0ea299888b05aff25e10d828fed5dfedb

PKG_LICENSE:=AGPL-3.0-only MIT
PKG_LICENSE_FILES:=LICENSE wing/LICENSE
PKG_MAINTAINER:=Tianling Shen <cnsztl@immortalwrt.org>

PKG_BUILD_DIR=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)/wing
PKG_BUILD_DEPENDS:=golang/host bpf-headers
PKG_BUILD_PARALLEL:=1
PKG_BUILD_FLAGS:=no-mips16

PATCH_DIR:=patches

ifeq ($(ARCH),arm)
  PATCH_DIR_ARCH:=patches_arm
else ifeq ($(ARCH),mips)
  PATCH_DIR_ARCH:=patches_mips
endif

GO_PKG:=github.com/daeuniverse/dae-wing
GO_PKG_LDFLAGS:= \
	-X '$(GO_PKG)/db.AppDescription=$(PKG_NAME) is a integration solution of dae, API and UI.'
GO_PKG_LDFLAGS_X= \
	$(GO_PKG)/db.AppName=$(PKG_NAME) \
	$(GO_PKG)/db.AppVersion=$(PKG_VERSION)
GO_PKG_TAGS:=embedallowed,trace

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/bpf.mk
include $(TOPDIR)/feeds/packages/lang/golang/golang-package.mk

TAR_CMD=$(HOST_TAR) -C $(BUILD_DIR)/ $(TAR_OPTIONS)

define Package/daed/Default
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Web Servers/Proxies
  URL:=https://github.com/daeuniverse/daed
endef

define Package/daed/config
  choice
    prompt "BPF dependency type"
    default DAED_USE_VMLINUX_BTF
    help
      Select the BPF dependency type.
      - BPF CO-RE (vmlinux-btf): Recommended. Does not require kernel headers.
      - Kernel DEBUG_INFO_BTF (bpf-depends): Requires kernel to be compiled with BTF debug info.

    config DAED_USE_VMLINUX_BTF
      bool "BPF CO-RE (vmlinux-btf)"

    config DAED_USE_BPF_DEPENDS
      bool "Kernel DEBUG_INFO_BTF (bpf-depends)"
  endchoice
endef

define Package/daed
  $(call Package/daed/Default)
  TITLE:=A Modern Dashboard For dae
  # You need enable KERNEL_DEBUG_INFO_BTF and KERNEL_BPF_EVENTS
  DEPENDS:=$(GO_ARCH_DEPENDS) \
    +ca-bundle +kmod-sched-core +kmod-sched-bpf \
    +kmod-veth +v2ray-geoip +v2ray-geosite

  ifeq ($(CONFIG_DAED_USE_VMLINUX_BTF),y)
    DEPENDS+=+vmlinux-btf
  endif
  ifeq ($(CONFIG_DAED_USE_BPF_DEPENDS),y)
    DEPENDS+=$(BPF_DEPENDS) +kmod-xdp-sockets-diag
  endif
endef

define Package/daed/description
  daed is a backend of dae, provides a method to bundle arbitrary
  frontend, dae and geodata into one binary.
endef

define Package/daed/conffiles
/etc/daed/wing.db
/etc/config/daed
endef

WEB_FILE:=$(PKG_NAME)-web-$(PKG_WEB_VERSION).zip
define Download/daed-web
	URL:=https://github.com/ksong008/daed/releases/download/v$(PKG_WEB_VERSION)
	URL_FILE:=web.zip
	FILE:=$(WEB_FILE)
	HASH:=f46d744b29d8e372df0728947936bc3f4ea86b42c2838cdcda63aeddd628ac94
endef

define Build/Patch
	$(call PatchDir,$(PKG_BUILD_DIR),$(PATCH_DIR),)
ifneq ($(PATCH_DIR_ARCH),)
	$(call PatchDir,$(PKG_BUILD_DIR),$(PATCH_DIR_ARCH),)
endif
endef

define Build/Prepare
	$(call Build/Prepare/Default)

	( \
		mkdir -p $(PKG_BUILD_DIR)/webrender ; \
		unzip -q -d $(PKG_BUILD_DIR)/webrender/ $(DL_DIR)/$(WEB_FILE) ; \
		find $(PKG_BUILD_DIR)/webrender/web -type f -size +4k ! -name "*.gz" ! -name "*.woff"  ! -name "*.woff2" -exec sh -c '\
			gzip -9 -k "{}"; \
			if [ "$$$$(stat -c %s "{}")" -lt "$$$$(stat -c %s "{}.gz")" ]; then \
				rm "{}.gz"; \
			else \
				rm "{}"; \
			fi' \
		";" ; \
	)
endef

DAE_CFLAGS:= \
	-O2 -Wall -Werror \
	-DMAX_MATCH_SET_LEN=1024 \
	-I$(BPF_HEADERS_DIR)/tools/lib \
	-I$(BPF_HEADERS_DIR)/arch/$(BPF_KARCH)/include/asm/mach-generic

ifneq ($(CONFIG_USE_MUSL),)
  TARGET_CFLAGS += -D_LARGEFILE64_SOURCE
endif

define Build/Compile
	( \
		pushd $(PKG_BUILD_DIR) ; \
		export \
		$(GO_GENERAL_BUILD_CONFIG_VARS) \
		$(GO_PKG_BUILD_CONFIG_VARS) \
		$(GO_PKG_BUILD_VARS) ; \
		go generate ./... ; \
		cd dae-core ; \
		export \
		BPF_CLANG="$(CLANG)" \
		BPF_STRIP_FLAG="-strip=$(LLVM_STRIP)" \
		BPF_CFLAGS="$(DAE_CFLAGS)" \
		BPF_TARGET="bpfel,bpfeb" \
		BPF_TRACE_TARGET="$(GO_ARCH)" ; \
		go generate control/control.go ; \
		go generate trace/trace.go ; \
		popd ; \
		$(call GoPackage/Build/Compile) ; \
	)
endef

define Package/daed/install
	$(call GoPackage/Package/Install/Bin,$(PKG_INSTALL_DIR))
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/dae-wing $(1)/usr/bin/daed

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) $(CURDIR)/files/daed.config $(1)/etc/config/daed

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(CURDIR)/files/daed.init $(1)/etc/init.d/daed
endef

$(eval $(call Download,daed-web))
$(eval $(call GoBinPackage,daed))
$(eval $(call BuildPackage,daed))
