# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=naiveproxy
PKG_VERSION:=137.0.7151.44-2
PKG_RELEASE:=1

# intel 80386 & riscv64 & cortex-a76
ifeq ($(ARCH_PREBUILT),aarch64_cortex-a76)
  ARCH_PREBUILT:=aarch64_generic
else ifeq ($(ARCH_PREBUILT),i386_pentium-mmx)
  ARCH_PREBUILT:=x86
else ifeq ($(ARCH_PREBUILT),i386_pentium4)
  ARCH_PREBUILT:=x86
else ifeq ($(ARCH_PREBUILT),riscv64_riscv64)
  ARCH_PREBUILT:=riscv64
endif

ifeq ($(ARCH_PACKAGES),aarch64_cortex-a53)
  PKG_HASH:=db0527adea0cde274873c28c0562c00f9aff7488ce02bf582ebbb3bf22f198fd
else ifeq ($(ARCH_PACKAGES),aarch64_cortex-a72)
  PKG_HASH:=ce0fbd501e11f515e0dac203157346201727ffec62ebc9f25c37db959e3b5b00
else ifeq ($(ARCH_PACKAGES),aarch64_generic)
  PKG_HASH:=7e3778ded1fe210c180127c7fac4913e1b0fa624f27d4f9a581ca56315cac72d
else ifeq ($(ARCH_PACKAGES),arm_arm1176jzf-s_vfp)
  PKG_HASH:=29d3585aa2cb790d15803a25d3fd4a831296bdb4ae3eaa2f0ac52b5bc09abba4
else ifeq ($(ARCH_PACKAGES),arm_arm926ej-s)
  PKG_HASH:=6469b5ff3745bcce8c6055566f4f92d692fa58ff912ff1a356ac540fbdac3bc0
else ifeq ($(ARCH_PACKAGES),arm_cortex-a15_neon-vfpv4)
  PKG_HASH:=76dcb85944194bf5cb7caa971696cb74dd134167afa37b4a5476562932a9aac1
else ifeq ($(ARCH_PACKAGES),arm_cortex-a5_vfpv4)
  PKG_HASH:=3f62e2f52423b2983a6ef569e99c797ac1322a34afbd0a6288514a7e936ec124
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7)
  PKG_HASH:=b57eb5b8f54d418d435e2e141618d0875f9463e1428cd994f3dbd9bd7d47258d
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_neon-vfpv4)
  PKG_HASH:=25123b03d30add7b91bb265b26ec9533749b50f1e42c12dec709e593e8a5dc11
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_vfpv4)
  PKG_HASH:=0f7f19b24ca5c60dbfb2b9979fe1e814843909803557e04a9c06e921b8e2b6dd
else ifeq ($(ARCH_PACKAGES),arm_cortex-a8_vfpv3)
  PKG_HASH:=3cd99622d737e09098b9b117d4525a8b4586bd1bdd93b8c6b305b8bf1479a72a
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9)
  PKG_HASH:=1895d5d943abdab61f4d518700dcf21167f6e633213ee2fe438e5782e3a8c39a
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_neon)
  PKG_HASH:=13478da67df395e4e2cc37ffab22b2875d9a88cd0ec14b7af7f9936f0364b471
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_vfpv3-d16)
  PKG_HASH:=efd1a5a5f19c5a14991f8f607a9e636be7e205fdac5afbaeb811c26762583f28
else ifeq ($(ARCH_PACKAGES),arm_mpcore)
  PKG_HASH:=d23f160bf4e1a22e7997d589bedbde8368e4b842ee6f4e0c1dba3c6825d42ef6
else ifeq ($(ARCH_PACKAGES),arm_xscale)
  PKG_HASH:=b82aaaada7cf3261a58a8f30bdd2710dcc021435cf310a1cec25f6fed6788428
else ifeq ($(ARCH_PACKAGES),mipsel_24kc)
  PKG_HASH:=277405ce386c56172e8e0ca2d98beec5bf5034f77a1224de201119abc5cd92b5
else ifeq ($(ARCH_PACKAGES),mipsel_mips32)
  PKG_HASH:=4e31ac05f877cc36cf9296377bb4edbfc0b91657c39e5c9dfe36ea63500cf5a0
else ifeq ($(ARCH_PACKAGES),riscv64)
  PKG_HASH:=deceede3b36871a785ece5f1465517b7cfa42d014f5c21eb23a4ea9b6821d4a8
else ifeq ($(ARCH_PACKAGES),x86)
  PKG_HASH:=0181e0b33b961a50d3d17a25513d28d8e0286fb1db417da5875cbec9341dd073
else ifeq ($(ARCH_PACKAGES),x86_64)
  PKG_HASH:=0c633a5dfe7d929cac0b3f389522c47ac46db9a9491724c7e1e7ef7380b2299e
else
  PKG_HASH:=dummy
endif

PKG_SOURCE:=naiveproxy-v$(PKG_VERSION)-openwrt-$(ARCH_PACKAGES).tar.xz
PKG_SOURCE_URL:=https://github.com/klzgrad/naiveproxy/releases/download/v$(PKG_VERSION)/
PKG_BUILD_DIR:=$(BUILD_DIR)/naiveproxy-v$(PKG_VERSION)-openwrt-$(ARCH_PACKAGES)

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
