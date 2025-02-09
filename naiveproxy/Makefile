# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=naiveproxy
PKG_VERSION:=133.0.6943.49-1
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
  PKG_HASH:=070ea4fec533a8ce32f55b6daf8c0431a9b532aba0a0a065583005c6baea77bc
else ifeq ($(ARCH_PACKAGES),aarch64_cortex-a72)
  PKG_HASH:=b442d4cd10612de60e88b29ed2f7662149570f0da093305511538194ed99f9cb
else ifeq ($(ARCH_PACKAGES),aarch64_generic)
  PKG_HASH:=110c0174bc9aeca41c03d207b1aa714c71528c03a8e148699b094473f8ef53f4
else ifeq ($(ARCH_PACKAGES),arm_arm1176jzf-s_vfp)
  PKG_HASH:=dac5719da72e253e02533ba1902367289b5f8fc97e2f1b2e3787e3e702922f2d
else ifeq ($(ARCH_PACKAGES),arm_arm926ej-s)
  PKG_HASH:=04f237181162ff3e8d83f9f864efead8dcec60a5d75c69b7b112aa0d3107c7a7
else ifeq ($(ARCH_PACKAGES),arm_cortex-a15_neon-vfpv4)
  PKG_HASH:=ec5bd89729eef1995b58f11f9e52f6495144001fdd3990116da598a9102d5454
else ifeq ($(ARCH_PACKAGES),arm_cortex-a5_vfpv4)
  PKG_HASH:=bb06489f76b3c8e6420aa6119afa16fe4398f8a3a29478f3939838f60126e3cd
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7)
  PKG_HASH:=2a5456cc82a92a69407ddc61b1cfc7d44290e6167d96d4c4fd2dfae53df7f4c5
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_neon-vfpv4)
  PKG_HASH:=474af81306bbb4278b70d5803cd8b810b0bffa422027b09e0e4e8a6303a6441f
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_vfpv4)
  PKG_HASH:=7f69c052fc6fb35ad3f2f90142c5f03a1ca2d1aa3c5de42ed9c6c5e46db3bff5
else ifeq ($(ARCH_PACKAGES),arm_cortex-a8_vfpv3)
  PKG_HASH:=005df4da3739d42852da7931d15846f22442f0e7ef67716b33dbbfc04f6073e5
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9)
  PKG_HASH:=a961140b121be616da691aa97a54e01ccf83d925b06d46f0a2e7f70ce93a337d
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_neon)
  PKG_HASH:=ecd4f18604ee118be763b710a6a183bf4043387950304f0b2fcefb87beec2eeb
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_vfpv3-d16)
  PKG_HASH:=707ff36bf95a4e71ff98dcc43182890cc1ac15b6d427c28e443134ca00295374
else ifeq ($(ARCH_PACKAGES),arm_mpcore)
  PKG_HASH:=135796bf6de20e1ddfb80f8aeb7c57098c1dcaeac2a566633255bb59eaf138a4
else ifeq ($(ARCH_PACKAGES),arm_xscale)
  PKG_HASH:=4f7f88885c4318259cfba73ff846eea1c5a94632f5c9d969d664eb1d7795380a
else ifeq ($(ARCH_PACKAGES),mipsel_24kc)
  PKG_HASH:=6759691bfbd271ac310be605a95d73755c34cc9dbac02d506fb272203733a937
else ifeq ($(ARCH_PACKAGES),mipsel_mips32)
  PKG_HASH:=543f521ac576667ffeeb3c2a1605cd427badb1dee863e78a562a055e25b6c540
else ifeq ($(ARCH_PACKAGES),riscv64)
  PKG_HASH:=8723cdb1e77c59bf90888c6f4ae1dac8ffb0de369b5de69249a62c5eefae2507
else ifeq ($(ARCH_PACKAGES),x86)
  PKG_HASH:=50729ddb13d31caacc1cd2f6e96d7813478c7e693ae006e3a78e71fea82a2f23
else ifeq ($(ARCH_PACKAGES),x86_64)
  PKG_HASH:=eb8fd19699363122f2dbaba8e8dce681e32415b8c485cbb5525ea26c107f1a0f
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
