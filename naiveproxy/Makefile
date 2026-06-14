# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=naiveproxy
PKG_REAL_VERSION:=149.0.7827.114-1
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
  PKG_HASH:=f47f3563547df291179faedce1cbaea79d3308d9b514ab45cd9a48ef91b16004
else ifeq ($(ARCH_PREBUILT),aarch64_cortex-a72)
  PKG_HASH:=720506fb399fad7721ebafa6d79c62afa5af6e2129963d34c4fe9eae5e21271e
else ifeq ($(ARCH_PREBUILT),aarch64_generic)
  PKG_HASH:=ae9c706226534fa5d0eda08f4a9d7503284abef5d786af5158b744fff6f29ac3
else ifeq ($(ARCH_PREBUILT),arm_arm1176jzf-s_vfp)
  PKG_HASH:=7377bb778a50133da75693f5a13b2a5ea71ff187c074f29d003e6a5a60b945f9
else ifeq ($(ARCH_PREBUILT),arm_arm926ej-s)
  PKG_HASH:=a43eb9984a93212df55ab47f66dd2dc8cbeb1eda807d9936fb28fe5b58f38991
else ifeq ($(ARCH_PREBUILT),arm_cortex-a15_neon-vfpv4)
  PKG_HASH:=d74106a600a9a22dfb727b30753c6a97d22616a5db690d83ef9166a5288b776c
else ifeq ($(ARCH_PREBUILT),arm_cortex-a5_vfpv4)
  PKG_HASH:=5a121b951bd4dbc19599fdfcde61249a1afc8cd492f290b782808297e987cfab
else ifeq ($(ARCH_PREBUILT),arm_cortex-a7)
  PKG_HASH:=a1e7cab958cc4912d65d00fc56144102d88792886bc4d3fc77fad2306ecb2d38
else ifeq ($(ARCH_PREBUILT),arm_cortex-a7_neon-vfpv4)
  PKG_HASH:=24bda5d57d206f91341be3cc7da6ab57342f2232b7e725295b1f928bcecc51ac
else ifeq ($(ARCH_PREBUILT),arm_cortex-a7_vfpv4)
  PKG_HASH:=13e20e649a226fbb879c1d571caa18bc40bdf27d90a1391172754bcb14ac6b74
else ifeq ($(ARCH_PREBUILT),arm_cortex-a8_vfpv3)
  PKG_HASH:=4bb88189ceb131136a72e19650a8b495b2124762a20b9a4dad0f2da6a296f8b5
else ifeq ($(ARCH_PREBUILT),arm_cortex-a9)
  PKG_HASH:=9a9913aab430e5f319ce1efdf9e673c12174eb5977596f6b6af8c69f5be095e4
else ifeq ($(ARCH_PREBUILT),arm_cortex-a9_neon)
  PKG_HASH:=9cb857ad352a7fafc06569aaae2a90d43fc5ad33a383686b56dbd508c6caa3c3
else ifeq ($(ARCH_PREBUILT),arm_cortex-a9_vfpv3-d16)
  PKG_HASH:=89582a47cc611e5caa51e720a13139cd87b3b22105c204afaa8744ad8ddca0a5
else ifeq ($(ARCH_PREBUILT),arm_mpcore)
  PKG_HASH:=3f8a2513ac301a16344b24544f86e4b62355622ec8dc9c6757b0faee231a7560
else ifeq ($(ARCH_PREBUILT),arm_xscale)
  PKG_HASH:=2ca1330ed5dd42a92221e32e5a769d19ac87787b0f4cf6a3dbe065241f16dd4d
else ifeq ($(ARCH_PREBUILT),mipsel_24kc)
  PKG_HASH:=a24acff64dc71603d46951b4f1496e3704ef60d17e25b221fa1664d37e1d375b
else ifeq ($(ARCH_PREBUILT),mipsel_mips32)
  PKG_HASH:=3ecc3c6796cd26dec68b6e6989bbd2636502e735323c81c954441431678b45dc
else ifeq ($(ARCH_PREBUILT),riscv64)
  PKG_HASH:=f72aeda71c6da0b75ccf2a09f2a963e750aba9f18f7a849fd09bcbfa89514199
else ifeq ($(ARCH_PREBUILT),x86)
  PKG_HASH:=b3513fee31ec503a3835579d211f5d0aa70e2d46b17eda363d42841d7ea15552
else ifeq ($(ARCH_PREBUILT),x86_64)
  PKG_HASH:=f1a1742f78f0b4b7fa36f8f4600598579b048da6c033c353633b396ec24c1bf2
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
