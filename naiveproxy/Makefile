# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=naiveproxy
PKG_VERSION:=138.0.7204.35-1
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
  PKG_HASH:=45c8b1f19d53f3e0c30bd591a0ba29e511295f7eb9c5ebeaee9dcb483e477d44
else ifeq ($(ARCH_PACKAGES),aarch64_cortex-a72)
  PKG_HASH:=2eb876e77a067f93e50370a1d7ebef497f948e76a732a698aac17b777c2e02da
else ifeq ($(ARCH_PACKAGES),aarch64_generic)
  PKG_HASH:=b0303b6c1147d563454605e3e2fda651aa40a8a7189b3c15245389557539b516
else ifeq ($(ARCH_PACKAGES),arm_arm1176jzf-s_vfp)
  PKG_HASH:=11f3aa85008935a7bce61e69117d0fec66b31ce7a8394d1ccb47f1fb66d00c35
else ifeq ($(ARCH_PACKAGES),arm_arm926ej-s)
  PKG_HASH:=c5838f4149efbc7b2e01d6f2c94f7585edc3b51ebc072e88f4e8d6e709125b02
else ifeq ($(ARCH_PACKAGES),arm_cortex-a15_neon-vfpv4)
  PKG_HASH:=a514d92010d2999ddbfe073e61dc9ea7f58414845077114979950ff5078a72ee
else ifeq ($(ARCH_PACKAGES),arm_cortex-a5_vfpv4)
  PKG_HASH:=1e2677d68d9c81b7505ada6ed146177e53dca708fa878c5105b87812df20c797
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7)
  PKG_HASH:=e9047f458ecba7cfc4c722d0180c1a4d823d9edbde41e4abce0f293c52712b0f
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_neon-vfpv4)
  PKG_HASH:=954cea8e06240e6391d7057765335c6ac20fdbc42dcde9d20c2e4aa55a75a9e1
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_vfpv4)
  PKG_HASH:=6d739e11f4df930139744d982ee9e98050cf6778ff0af90bf5e128f789f26b61
else ifeq ($(ARCH_PACKAGES),arm_cortex-a8_vfpv3)
  PKG_HASH:=8f3de0015d28c341d8dd303bd770ffaf4cf05767a4af3612218da78a54d01c6e
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9)
  PKG_HASH:=bf15aaaf307ac86cbd3fc9c9a8a107103d2682ba227f54fd2d2a2def252b8fca
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_neon)
  PKG_HASH:=c5788e9ce8eef9d526390ef04966668ffd9e9f40af194257fb9600362585032f
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_vfpv3-d16)
  PKG_HASH:=5c93593112ad72c75d35fc41b6d6ed3c1115dcf8aa30f9bc61303696f31fa551
else ifeq ($(ARCH_PACKAGES),arm_mpcore)
  PKG_HASH:=ee481d71ff9735e221f8a58601690f11315613f4e77678bbe3ab25236d5ad36a
else ifeq ($(ARCH_PACKAGES),arm_xscale)
  PKG_HASH:=3719a7d151c1d80250388cea32f74165772d8cc21b8bfa9c6a8db312ae19a0b8
else ifeq ($(ARCH_PACKAGES),mipsel_24kc)
  PKG_HASH:=1aa0c1fbe81242cf4c14a6c83fd32f8548a3691233c2078a640619c2b3bfd7c4
else ifeq ($(ARCH_PACKAGES),mipsel_mips32)
  PKG_HASH:=9f909d879602a0feeb2535e0859339a0496cdd948fb2f64c491bc5cf324f93f0
else ifeq ($(ARCH_PACKAGES),riscv64)
  PKG_HASH:=df183679a499ce65f3ff2e7561a551dd890c4acd6bfdeb97fdf729c97d195bac
else ifeq ($(ARCH_PACKAGES),x86)
  PKG_HASH:=f9ca7ee068b2317c8a9e1155ed692cb99d3ba35f5ea4e0dcb56d63efa8764839
else ifeq ($(ARCH_PACKAGES),x86_64)
  PKG_HASH:=c6a6526432d76a2a19412869fd37a99ffa9f832c992791fc26983965ad3f0726
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
