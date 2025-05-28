# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=naiveproxy
PKG_VERSION:=137.0.7151.44-1
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
  PKG_HASH:=c1557de5098291135e498bf8b205ae71ca7940d5e31ff160bcda438bf3b6e10f
else ifeq ($(ARCH_PACKAGES),aarch64_cortex-a72)
  PKG_HASH:=81be558b8f478c20ebad5130d06766e2b2b662ff50cfcb284f8793111296392a
else ifeq ($(ARCH_PACKAGES),aarch64_generic)
  PKG_HASH:=b89ed151af96a3ae96b12bc5afc6d875d42bf675c20357c6ae949e347171e849
else ifeq ($(ARCH_PACKAGES),arm_arm1176jzf-s_vfp)
  PKG_HASH:=07fd06e4897d5fb634f9fc32203221771070f5baa5f2809424068558379e21ac
else ifeq ($(ARCH_PACKAGES),arm_arm926ej-s)
  PKG_HASH:=beccdfae464ef7e8cd5575cc1e9f9c6e2512a78b441c3f0249402548b10557e7
else ifeq ($(ARCH_PACKAGES),arm_cortex-a15_neon-vfpv4)
  PKG_HASH:=75cfc99613bb141205a8cffdbb84e6819b9fe3d7b12b540f45a939d5fe8b8e50
else ifeq ($(ARCH_PACKAGES),arm_cortex-a5_vfpv4)
  PKG_HASH:=93a16b9420601e6775183eabcd538553594a585c696758126c7745a57603e59f
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7)
  PKG_HASH:=fa1c3cb597f41b6773079e83e42759347c300e90cc3f5c785352d265ca0e902c
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_neon-vfpv4)
  PKG_HASH:=17102847331a52fbbc912dc6ba56ea3fa41a0bcfb77940563b41c90d07535743
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_vfpv4)
  PKG_HASH:=acde0d57e5a1aa1c53f5e052b0e26923d87935c5f37405441e96b779731e889a
else ifeq ($(ARCH_PACKAGES),arm_cortex-a8_vfpv3)
  PKG_HASH:=36ca82512e740e3967f556b45a58d0eb2e0df0cb189f1d7a354589c78a467c1e
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9)
  PKG_HASH:=6e5bc7d845d1c9cc6198f7aca953f33eecbc8c2d2831f2528f22dd9d995cef3b
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_neon)
  PKG_HASH:=9e2b4f5fef983ee929ecd7871ae47d8b909b1975a73562afdd4bf0309541fbf3
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_vfpv3-d16)
  PKG_HASH:=bf1446f6e4fc3aef4844d270c6deb4af48733fc935f056566c734cb27f2d02ce
else ifeq ($(ARCH_PACKAGES),arm_mpcore)
  PKG_HASH:=f4999013284a30f7d0b092b16282c4e191989e3bbfa85e6b1083b2d35551119b
else ifeq ($(ARCH_PACKAGES),arm_xscale)
  PKG_HASH:=f2d12e524f0efe69435babdffeee9b49a9d68549326ad4c9374c2dd39acb0998
else ifeq ($(ARCH_PACKAGES),mipsel_24kc)
  PKG_HASH:=985844a518da495279d3b5d3eb46b3e17fccb0795bfdf909aef934a07e5834df
else ifeq ($(ARCH_PACKAGES),mipsel_mips32)
  PKG_HASH:=4e677e87a15b5a99eb365b0d26afd9157fa4f8df63240c8800d6ceb7c0d769a3
else ifeq ($(ARCH_PACKAGES),riscv64)
  PKG_HASH:=03ed1c42c819989ad98be7bfb5a1d1f60c2e28ea0eb06cae2de9162f50dbd46b
else ifeq ($(ARCH_PACKAGES),x86)
  PKG_HASH:=41b13c2a568b55b96122edc298f584a697238a80a5a240e74cd52ca578a57d29
else ifeq ($(ARCH_PACKAGES),x86_64)
  PKG_HASH:=11aa1d023d87075f102cadeb07780bdf3543cc47fd027e512ce7a292c582bd35
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
