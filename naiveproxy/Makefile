# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=naiveproxy
PKG_REAL_VERSION:=154.0.8037.49-4
PKG_VERSION:=$(subst -,.,$(PKG_REAL_VERSION))
PKG_RELEASE:=1

ARCH_PREBUILT:=$(ARCH_PACKAGES)
ifeq ($(ARCH_PREBUILT),aarch64_cortex-a76)
  ARCH_PREBUILT:=aarch64_generic
else ifeq ($(ARCH_PREBUILT),i386_pentium-mmx)
  ARCH_PREBUILT:=x86
else ifeq ($(ARCH_PREBUILT),i386_pentium4)
  ARCH_PREBUILT:=x86
else ifeq ($(ARCH_PREBUILT),riscv64_riscv64)
  ARCH_PREBUILT:=riscv64
endif

ifeq ($(ARCH_PREBUILT),aarch64_cortex-a53)
  PKG_HASH:=f1b783fe5d1e16ccab94b5f2d09da8c4e02c425714f8da27ee38d8bb591c0bf1
else ifeq ($(ARCH_PREBUILT),aarch64_cortex-a72)
  PKG_HASH:=72bca35314f40886a713c8deb329e2924fb666b335138364886c1306e07ca352
else ifeq ($(ARCH_PREBUILT),aarch64_generic)
  PKG_HASH:=880b6442f19977876ef4a6b2ed5132cb38efd57858f797e71380a634eb90651f
else ifeq ($(ARCH_PREBUILT),arm_arm1176jzf-s_vfp)
  PKG_HASH:=145886375d1cbd5e7617f9a35940fb9c6a9982104f59fb0091b6dacb2cf5da26
else ifeq ($(ARCH_PREBUILT),arm_arm926ej-s)
  PKG_HASH:=3309584b9796499f5db4a69606fa520357e28581cadaa0ebd6b90be02d4f0c1a
else ifeq ($(ARCH_PREBUILT),arm_cortex-a15_neon-vfpv4)
  PKG_HASH:=c0cbd21bc079ee5ec27450a32b0bcf3a6eadafab77c4edbd5d743f12ba862d0c
else ifeq ($(ARCH_PREBUILT),arm_cortex-a5_vfpv4)
  PKG_HASH:=614df45cd53f62a3bb61c468f48f42e896e283b2626ff88b316ed73bea09732b
else ifeq ($(ARCH_PREBUILT),arm_cortex-a7)
  PKG_HASH:=9cab71647f66ee1900080360cdcdfcb1fae5995b0686ea38bff13702a9464ff5
else ifeq ($(ARCH_PREBUILT),arm_cortex-a7_neon-vfpv4)
  PKG_HASH:=d902783bdd551e5500112efa8d621de1df68baed60161714a4ad956bb94927c7
else ifeq ($(ARCH_PREBUILT),arm_cortex-a7_vfpv4)
  PKG_HASH:=e67ef771678239484243aefaa1923891954f7eecafd8ba37aba132c256c6ae7e
else ifeq ($(ARCH_PREBUILT),arm_cortex-a8_vfpv3)
  PKG_HASH:=a4439e30661c254ad832121804d5bfd1ac1ffb6c6197eed611fd3c2037223b26
else ifeq ($(ARCH_PREBUILT),arm_cortex-a9)
  PKG_HASH:=2521c8ab36c2a650434f3e972a95d678801d1b67e807a4445d97ecccad5aae65
else ifeq ($(ARCH_PREBUILT),arm_cortex-a9_neon)
  PKG_HASH:=3c4d87cbf586e60f3c402d128d0dbfeade9503baf6112de0907aa95b2ee3a4e1
else ifeq ($(ARCH_PREBUILT),arm_cortex-a9_vfpv3-d16)
  PKG_HASH:=7b578e85cad891f92330afd0832ab22940dbe75639eb4800bcd99d919039b68d
else ifeq ($(ARCH_PREBUILT),arm_mpcore)
  PKG_HASH:=d4309cc6c8d92d3b8986cb20aa11ecf3d8cdbb6421960acfad768587c9da0b8b
else ifeq ($(ARCH_PREBUILT),arm_xscale)
  PKG_HASH:=b1d7949bd95e72a68b8bf4e19c3457acbc5191a289568575c3a2e9d5a1869b5e
else ifeq ($(ARCH_PREBUILT),mipsel_24kc)
  PKG_HASH:=7b49d3f7164fda922715e304d6f1fdf0c3b8d1db36699bdb1402c1a81c97fc31
else ifeq ($(ARCH_PREBUILT),mipsel_mips32)
  PKG_HASH:=28048c3542abd718a74d3324dd30a77bfd16c89f112d3cfbf611132593076b8b
else ifeq ($(ARCH_PREBUILT),riscv64)
  PKG_HASH:=bf19b60b0971a73b2ed6e508067f950c4a0dec91ef78788498626e93448ab87b
else ifeq ($(ARCH_PREBUILT),x86)
  PKG_HASH:=66f6982616dbe6233b98836b3e39a9ab1a01831065325b71ab8c6afd80d5a9f2
else ifeq ($(ARCH_PREBUILT),x86_64)
  PKG_HASH:=57ac75e342f7d7098f39d4dbf9c08168001957698d0a72e33d849e4b2df71cf2
else
  PKG_HASH:=dummy
endif

PKG_SOURCE:=naiveproxy-v$(PKG_REAL_VERSION)-openwrt-$(ARCH_PREBUILT).tar.xz
PKG_SOURCE_URL:=https://github.com/klzgrad/naiveproxy/releases/download/v$(PKG_REAL_VERSION)/
PKG_BUILD_DIR:=$(BUILD_DIR)/naiveproxy-v$(PKG_REAL_VERSION)-openwrt-$(ARCH_PACKAGES)

PKG_LICENSE:=BSD 3-Clause
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=sbwml <admin@cooluc.com>

include $(INCLUDE_DIR)/package.mk

define Package/naiveproxy
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Web Servers/Proxies
  TITLE:=Make a fortune quietly
  URL:=https://github.com/klzgrad/naiveproxy
  DEPENDS:=@(aarch64||arm||i386||mipsel||riscv64||x86_64) +libatomic
endef

define Package/naiveproxy/description
  NaïveProxy uses Chrome's network stack to camouflage traffic with strong
  censorship resistance and low detectability. Reusing Chrome's stack also
  ensures best practices in performance and security.
endef

define Package/naiveproxy/conffiles
/etc/config/naiveproxy
endef

define Build/Compile
endef

define Package/naiveproxy/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/naive $(1)/usr/bin/naive
	$(INSTALL_DIR) $(1)/etc/config $(1)/etc/init.d
	$(INSTALL_CONF) $(CURDIR)/files/naiveproxy.config $(1)/etc/config/naiveproxy
	$(INSTALL_BIN) $(CURDIR)/files/naiveproxy.init $(1)/etc/init.d/naiveproxy
endef

$(eval $(call BuildPackage,naiveproxy))
