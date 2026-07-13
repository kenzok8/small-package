# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2023 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=daed
PKG_VERSION:=2026.07.08
PKG_RELEASE:=1

PKG_SOURCE:=daed-src-2026.07.08-e83da9ff800e.tar.gz
PKG_SOURCE_URL:=https://github.com/kenzok8/openwrt-daede/releases/download/daed-src
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_HASH:=4e90e37e8be531adbd3200c97e99a638886fc0aeeeb538499115654ea9d30269

PKG_LICENSE:=AGPL-3.0-only MIT
PKG_LICENSE_FILES:=LICENSE wing/LICENSE
PKG_MAINTAINER:=kenzok8

DAED_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_BUILD_DIR:=$(DAED_BUILD_DIR)/wing

PKG_BUILD_DEPENDS:=golang/host bpf-headers
PKG_BUILD_PARALLEL:=1
PKG_BUILD_FLAGS:=no-mips16

# armv7 lacks a CO-RE vmlinux.h for the trace eBPF (under wing/dae-core), so
# trace's bpf2go fails there. Apply sbwml/openwrt_helloworld's arm patches
# (add vmlinux-arm.h + drop the kprobe that doesn't work) to build on arm.
ifeq ($(ARCH),arm)
PATCH_DIR:=$(CURDIR)/patches_arm
endif

GO_PKG:=github.com/daeuniverse/dae-wing

GO_PKG_LDFLAGS:= \
	-s -w -buildid= \
	-linkmode external -extldflags '-static -Wl,-s' \
	-X '$(GO_PKG)/db.AppDescription=$(PKG_NAME) is a integration solution of dae, API and UI.'
GO_PKG_LDFLAGS_X:= \
	$(GO_PKG)/db.AppName=$(PKG_NAME) \
	$(GO_PKG)/db.AppVersion=$(PKG_VERSION)
GO_PKG_TAGS:=embedallowed,trace,timetzdata

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/bpf.mk
include $(TOPDIR)/feeds/packages/lang/golang/golang-package.mk

GO_PKG_BUILD_VARS+= GOFLAGS="-trimpath -buildvcs=false -pgo=auto"
GO_PKG_TARGET_VARS+= \
	CGO_LDFLAGS="$(TARGET_LDFLAGS) -static -Wl,-s" \
	GOEXPERIMENT=newinliner,simd

define Package/daed/Default
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Web Servers/Proxies
  URL:=https://github.com/daeuniverse/daed
endef

define Package/daed
  $(call Package/daed/Default)
  TITLE:=A Modern Dashboard For dae
  DEPENDS:=$(GO_ARCH_DEPENDS) \
    +ca-bundle +kmod-sched-core +kmod-sched-bpf \
    +kmod-veth +v2ray-geoip +v2ray-geosite \
    +@KERNEL_XDP_SOCKETS \
    +DAED_USE_VMLINUX_BTF:vmlinux-btf
endef

define Package/daed/config
	choice
		prompt "BTF source for CO-RE"
		default DAED_USE_KERNEL_BTF
		depends on PACKAGE_daed

	config DAED_USE_KERNEL_BTF
		bool "Use kernel BTF (integrated)"
		depends on KERNEL_DEBUG_INFO_BTF

	config DAED_USE_VMLINUX_BTF
		bool "Use vmlinux-btf package"
	endchoice
endef

define Package/daed/description
  daed is a backend of dae, provides a method to bundle arbitrary
  frontend, dae and geodata into one binary.
endef

define Package/daed/conffiles
/etc/daed/wing.db
/etc/config/daed
endef

define Build/Prepare
	mkdir -p $(DAED_BUILD_DIR)
	$(TAR) --strip-components=1 -C $(DAED_BUILD_DIR) -xzf $(DL_DIR)/$(PKG_SOURCE)
	$(if $(wildcard $(CURDIR)/patches/*.patch),$(call PatchDir,$(PKG_BUILD_DIR),$(CURDIR)/patches,))
	$(if $(filter arm,$(ARCH)),$(if $(wildcard $(CURDIR)/patches_arm/*.patch),$(call PatchDir,$(PKG_BUILD_DIR),$(CURDIR)/patches_arm,)))
endef

DAE_CFLAGS:= \
	-O2 -Wall -Werror \
	-DMAX_MATCH_SET_LEN=1024 \
	-I$(BPF_HEADERS_DIR)/tools/lib \
	-I$(BPF_HEADERS_DIR)/arch/$(BPF_KARCH)/include/asm/mach-generic

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
		go generate ./control/control.go ; \
		go generate ./trace/trace.go ; \
		popd ; \
	)
	$(call GoPackage/Build/Compile)
endef

define Package/daed/install
	$(call GoPackage/Package/Install/Bin,$(PKG_INSTALL_DIR))
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/dae-wing $(1)/usr/bin/daed
	$(INSTALL_BIN) $(CURDIR)/files/daed-guard $(1)/usr/bin/daed-guard

	$(INSTALL_DIR) $(1)/usr/share/daed
	$(INSTALL_DATA) $(CURDIR)/files/daed-cleanup.sh $(1)/usr/share/daed/cleanup.sh

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) $(CURDIR)/files/daed.config $(1)/etc/config/daed

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(CURDIR)/files/daed.init $(1)/etc/init.d/daed
endef

$(eval $(call GoBinPackage,daed))
$(eval $(call BuildPackage,daed))
