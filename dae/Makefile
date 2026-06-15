# SPDX-License-Identifier: GPL-2.0-only

include $(TOPDIR)/rules.mk

PKG_NAME:=dae
PKG_VERSION:=2026.06.14
PKG_RELEASE:=1

PKG_SOURCE:=dae-src-2026.06.14-fa89ea7197a5.tar.gz
PKG_SOURCE_URL:=https://github.com/kenzok8/openwrt-daede/releases/download/dae-src
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_HASH:=5bbbd017bffdf04d0357a4e487c5d108b983c29b231fa752de17ddda00b2b462

PKG_LICENSE:=AGPL-3.0-only
PKG_LICENSE_FILE:=LICENSE
PKG_MAINTAINER:=kenzok8

DAE_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_BUILD_DIR:=$(DAE_BUILD_DIR)/core

PKG_BUILD_DEPENDS:=golang/host bpf-headers
PKG_BUILD_PARALLEL:=1
PKG_BUILD_FLAGS:=no-mips16

# armv7 lacks a CO-RE vmlinux.h for the trace eBPF, so trace's bpf2go fails to
# build there. Apply sbwml/openwrt_helloworld's arm patches (add vmlinux-arm.h
# + drop the kprobe that doesn't work) to let dae build on arm targets.
ifeq ($(ARCH),arm)
PATCH_DIR:=$(CURDIR)/patches_arm
endif

GO_PKG:=github.com/daeuniverse/dae
GO_PKG_EXCLUDES:=control/kern/tests
GO_PKG_LDFLAGS:= \
	-s -w -buildid= \
	-linkmode external -extldflags '-static -Wl,-s'
GO_PKG_LDFLAGS_X:= \
	$(GO_PKG)/cmd.Version=$(PKG_VERSION) \
	$(GO_PKG)/common/consts.MaxMatchSetLen_=1024
GO_PKG_TAGS:=trace

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/bpf.mk
include $(TOPDIR)/feeds/packages/lang/golang/golang-package.mk

GO_PKG_BUILD_VARS+= GOFLAGS="-trimpath -buildvcs=false -pgo=auto"
GO_PKG_TARGET_VARS+= \
	CGO_LDFLAGS="$(TARGET_LDFLAGS) -static -Wl,-s" \
	GOEXPERIMENT=newinliner,simd

define Package/dae/Default
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Web Servers/Proxies
  URL:=https://github.com/daeuniverse/dae
endef

define Package/dae
  $(call Package/dae/Default)
  TITLE:=A lightweight and high-performance transparent proxy solution
  DEPENDS:=$(GO_ARCH_DEPENDS) \
    +ca-bundle +kmod-sched-core +kmod-sched-bpf \
    +kmod-veth +v2ray-geoip +v2ray-geosite \
    +@KERNEL_XDP_SOCKETS \
    +DAE_USE_VMLINUX_BTF:vmlinux-btf
endef

define Package/dae/config
	choice
		prompt "BTF source for CO-RE"
		default DAE_USE_KERNEL_BTF
		depends on PACKAGE_dae

	config DAE_USE_KERNEL_BTF
		bool "Use kernel BTF (integrated)"
		depends on KERNEL_DEBUG_INFO_BTF

	config DAE_USE_VMLINUX_BTF
		bool "Use vmlinux-btf package"
	endchoice
endef

define Package/dae/description
  dae, means goose, is a lightweight and high-performance transparent
  proxy solution.
endef

define Package/dae/conffiles
/etc/dae/config.dae
/etc/config/dae
endef

DAE_CFLAGS:= \
	-O2 -Wall -Werror \
	-DMAX_MATCH_SET_LEN=1024 \
	-I$(BPF_HEADERS_DIR)/tools/lib \
	-I$(BPF_HEADERS_DIR)/arch/$(BPF_KARCH)/include/asm/mach-generic

define Build/Prepare
	mkdir -p $(DAE_BUILD_DIR)
	$(TAR) --strip-components=1 -C $(DAE_BUILD_DIR) -xzf $(DL_DIR)/$(PKG_SOURCE)
	$(if $(wildcard $(PATCH_DIR)/*.patch),$(call PatchDir,$(PKG_BUILD_DIR),$(PATCH_DIR),))
endef

define Build/Compile
	( \
		pushd $(PKG_BUILD_DIR) ; \
		export \
		$(GO_GENERAL_BUILD_CONFIG_VARS) \
		$(GO_PKG_BUILD_CONFIG_VARS) \
		$(GO_PKG_BUILD_VARS) \
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

define Package/dae/install
	$(call GoPackage/Package/Install/Bin,$(PKG_INSTALL_DIR))
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/dae $(1)/usr/bin/dae

	$(INSTALL_DIR) $(1)/etc/dae
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/example.dae $(1)/etc/dae/example.dae

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) $(CURDIR)/files/dae.config $(1)/etc/config/dae

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(CURDIR)/files/dae.init $(1)/etc/init.d/dae
endef

$(eval $(call GoBinPackage,dae))
$(eval $(call BuildPackage,dae))
