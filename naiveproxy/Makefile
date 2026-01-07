# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=naiveproxy
PKG_VERSION:=143.0.7499.109-2
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
  PKG_HASH:=e5eec05d7e799c4b6f93adb02129246142a88e427d76d6275a0312872031a1db
else ifeq ($(ARCH_PACKAGES),aarch64_cortex-a72)
  PKG_HASH:=ca7975f7b711d1936d44b7a3676d4ddec59dd84339da0e28aa8bbc1fa738523a
else ifeq ($(ARCH_PACKAGES),aarch64_generic)
  PKG_HASH:=a4b34126901ad577a018332dd8cfa015ca5de1dcbbcf445465fb5a89a29a6b29
else ifeq ($(ARCH_PACKAGES),arm_arm1176jzf-s_vfp)
  PKG_HASH:=ec0a9a76bc51d7608897db9d87c3e52a889989856b3456cf1b35c4a42891fc40
else ifeq ($(ARCH_PACKAGES),arm_arm926ej-s)
  PKG_HASH:=bdd03cdec1f7215369cafdc7922f3d78ecd570a59d5cd04e829cab33c6dbc68e
else ifeq ($(ARCH_PACKAGES),arm_cortex-a15_neon-vfpv4)
  PKG_HASH:=fce86759321a06cc373ceef1a38fee456cf0383cc466a3762671b9a0fc4e13ba
else ifeq ($(ARCH_PACKAGES),arm_cortex-a5_vfpv4)
  PKG_HASH:=3bb0eef45955ccb656c0b074db40024e35a96c0588250534d25468242b21e067
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7)
  PKG_HASH:=42c95ce44d9abb1472f4817b5839252fc418cecd3b1d683a0211ca98e7e9a21f
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_neon-vfpv4)
  PKG_HASH:=7222d40cc5b0f29e5858e6023e713cc69174672b2489a8c8525d031822b38230
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_vfpv4)
  PKG_HASH:=1c15ceeb689d686e198afd0c1bb72b6c54ef89bde5b347205d6c2cedf359f37a
else ifeq ($(ARCH_PACKAGES),arm_cortex-a8_vfpv3)
  PKG_HASH:=a5f370df608aba401cb5a761c17f994d27d1a912be1aa9c7bcc0417314ecfb62
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9)
  PKG_HASH:=f5df82bd5d3a45e8869026977c2d30bac6ccc258dadb7046e3306d4e54395741
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_neon)
  PKG_HASH:=7600df27693dda5f43c7d38715b9d4664db77ed4488c77da822c690cb28fcf90
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_vfpv3-d16)
  PKG_HASH:=c010124d705e19da53e0df4658c23a5ad0ff71e89f8819e01f9e7011160042fa
else ifeq ($(ARCH_PACKAGES),arm_mpcore)
  PKG_HASH:=6ccbf7cf6b17b4cf4ab7b29b12a279b1fc79257f2fc569e81a5af6bda18819f4
else ifeq ($(ARCH_PACKAGES),arm_xscale)
  PKG_HASH:=5367433f1759aa0b947f6180c9d1944205629d7829db9f3466bd38d40da57ae0
else ifeq ($(ARCH_PACKAGES),mipsel_24kc)
  PKG_HASH:=444a59288e3e7e80b2ca04fb4d6fb9a046a624cb01a9cea2314834c736561433
else ifeq ($(ARCH_PACKAGES),mipsel_mips32)
  PKG_HASH:=fa568b8a8ed8505a99d5ca30568cbdb2539cc48d218c338a321fba116632daa1
else ifeq ($(ARCH_PACKAGES),riscv64)
  PKG_HASH:=13c1a43e58cef7219baf828250afb9390fd2ed9379d30f7d7b182db61492fe69
else ifeq ($(ARCH_PACKAGES),x86)
  PKG_HASH:=8088dd1ea80321109248f68f6f1a7c45f5b4dc0982992aabde725c3503a5b442
else ifeq ($(ARCH_PACKAGES),x86_64)
  PKG_HASH:=5681e13c833757cfb5769755fd93d1906c47448af190585067bde9de590bdb2e
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
