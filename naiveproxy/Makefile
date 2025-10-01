# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=naiveproxy
PKG_VERSION:=140.0.7339.123-3
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
  PKG_HASH:=9bda77ac7c551e1fd33b2db21cc235e4d2e35c414655018f53e0d419ac2b46d1
else ifeq ($(ARCH_PACKAGES),aarch64_cortex-a72)
  PKG_HASH:=5a8a02055d14abd56916fb1e2ede9b56b55785fc842c893ac9cfdc98f1ceb6bd
else ifeq ($(ARCH_PACKAGES),aarch64_generic)
  PKG_HASH:=d2b41880a40e204ebe91baaf8202d0d1f3004b5335266afa426c680f2f0a909e
else ifeq ($(ARCH_PACKAGES),arm_arm1176jzf-s_vfp)
  PKG_HASH:=76df8b546ed640ed2e581f32ab837fc487aae0a80a5985a42405c2c8bad87c18
else ifeq ($(ARCH_PACKAGES),arm_arm926ej-s)
  PKG_HASH:=27b28beaa032165e9b93d423353ced3cfe594c71353fd9d109699f330b785732
else ifeq ($(ARCH_PACKAGES),arm_cortex-a15_neon-vfpv4)
  PKG_HASH:=14d4929d2b417baa7f31df114eefa2d0a1ae4bc255cf1b3a037558bd67b77faf
else ifeq ($(ARCH_PACKAGES),arm_cortex-a5_vfpv4)
  PKG_HASH:=49a9c7eecab54155a31c3bfae71cf5193a881189715c7b4d29ce50a8c5c759d6
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7)
  PKG_HASH:=99b22874957bce541a0f8cbc0d23c501b85c20e8645bfa777a9f358d0b121d03
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_neon-vfpv4)
  PKG_HASH:=c0ff70018cf45b8115c9dd3f56ffc7d82b9c381d97ea75722c56401689d2948c
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_vfpv4)
  PKG_HASH:=725add2f90194dc44397e1034d861c1f88387eeea2f32baaa07bc384bfab2176
else ifeq ($(ARCH_PACKAGES),arm_cortex-a8_vfpv3)
  PKG_HASH:=3f281c94e72d47b3676cd9135e5b83858421c2a108e7b121629480f0fd5b4830
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9)
  PKG_HASH:=b9623d595a35609050c9638c8d2903cdb51eb56675ff4109627d66d8a6a993e3
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_neon)
  PKG_HASH:=ab5a699ef830d65344f014547ae6ce73e0f25103ad02d3e80a5d441e19c7e21e
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_vfpv3-d16)
  PKG_HASH:=efb7650c31c862564f39be269d67fca4e1a43bf356a5d4c1c158cc83e7c378e2
else ifeq ($(ARCH_PACKAGES),arm_mpcore)
  PKG_HASH:=1e0fa7d2f283807a019c85ddb58f99b711bcf86eb4ac759562b221d998091093
else ifeq ($(ARCH_PACKAGES),arm_xscale)
  PKG_HASH:=40175f13102597b88f92c664bf5c595ab69b248a5b64229a6aba388be77345b4
else ifeq ($(ARCH_PACKAGES),mipsel_24kc)
  PKG_HASH:=63b1f692d2643de026d1a53699a65e7f30ee5c226beaa6cc255189a7c04d5817
else ifeq ($(ARCH_PACKAGES),mipsel_mips32)
  PKG_HASH:=e5dd26061343287e6636003795763bcc9d8d83f4b7096246bdc81ed5da45253c
else ifeq ($(ARCH_PACKAGES),riscv64)
  PKG_HASH:=38c6a3fafbf073a83229f6b0629f725006e928f06d9d2353bdd3c072ef9a99bf
else ifeq ($(ARCH_PACKAGES),x86)
  PKG_HASH:=a3e8aad951330b995273176cc310038971f4f3fff56ab047d5e60e3a0eb67d14
else ifeq ($(ARCH_PACKAGES),x86_64)
  PKG_HASH:=d6c39befccb1f3ad54ffa11c5ae8ad11a90151998eeaae6b1a73cc0702f24966
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
