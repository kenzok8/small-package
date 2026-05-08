# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=naiveproxy
PKG_VERSION:=148.0.7778.96-4
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
  PKG_HASH:=37dd5ba07f21fa6113a51be3dd556256246a91f5ff1035ec88c48236b224322b
else ifeq ($(ARCH_PACKAGES),aarch64_cortex-a72)
  PKG_HASH:=9cf4d3d484e236794232f9e02a63dca6f8d0da420277c42c0a42f60e6bbecc40
else ifeq ($(ARCH_PACKAGES),aarch64_generic)
  PKG_HASH:=9e7db7e25f25a144a944da4c539ea0c81207ecb7b4844d9888e6a1bc646a24fa
else ifeq ($(ARCH_PACKAGES),arm_arm1176jzf-s_vfp)
  PKG_HASH:=3d0096614d8e681ad0094a08dc04ed9d2eceaa81123fdbb3eb29ee3f941414e2
else ifeq ($(ARCH_PACKAGES),arm_arm926ej-s)
  PKG_HASH:=a87043d7f84d7a2f7960069019daf533d0e70cbdd1518c9aa05c3eb5e57bf110
else ifeq ($(ARCH_PACKAGES),arm_cortex-a15_neon-vfpv4)
  PKG_HASH:=928a76f7a80b8c207bae06836c7f6c3d624692c440e8ad23a455a889f95d176b
else ifeq ($(ARCH_PACKAGES),arm_cortex-a5_vfpv4)
  PKG_HASH:=335c835845d95dcafed2312898fd33cd135c53e059746c1527f7e134d0adee37
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7)
  PKG_HASH:=d83bb85faaa394ef6cfefa6214fb7ed4f4fc9e7a521231d3aa4b84ec207c0340
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_neon-vfpv4)
  PKG_HASH:=641ac0059986186d3ba7ccf9fa330a8c65f14968ba620ff999590015faee0808
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_vfpv4)
  PKG_HASH:=cadfd9132835e7561cc5d64b844442c12f96b08b9231b1c6d7477efe108d9181
else ifeq ($(ARCH_PACKAGES),arm_cortex-a8_vfpv3)
  PKG_HASH:=cdf60b18b0650cabe30860b5a66210bb800e99c7c9124600113015e9ed51d5b2
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9)
  PKG_HASH:=7468e8b894726d8c112ce4a7ac6b6cb57497b2fd73ff178cca9971b184067b1f
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_neon)
  PKG_HASH:=62169c664deb876ec735bfff115ba3e6203c2a5488dc8817920f44e6f8cf30c2
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_vfpv3-d16)
  PKG_HASH:=23a517bdbf49e37111bcd6d62e45d361319658325556aa560cf79b3978abfee0
else ifeq ($(ARCH_PACKAGES),arm_mpcore)
  PKG_HASH:=623022cafb17bf4fae639c5c3df1cb9e60bd633bee01b39d4ba748dbf5c9d254
else ifeq ($(ARCH_PACKAGES),arm_xscale)
  PKG_HASH:=a11aacd54558620dc78964f0e4e8a450a5cb0b50fd9108cd31bf95c2e3143eb9
else ifeq ($(ARCH_PACKAGES),mipsel_24kc)
  PKG_HASH:=60b0bfb9c1a88157a9dfd536313e9e8630f60128eedc93e650306340503cc138
else ifeq ($(ARCH_PACKAGES),mipsel_mips32)
  PKG_HASH:=230171fdbee09d3c270caa6eab8e9cc08e47a198819bbf430e4c6751b0666631
else ifeq ($(ARCH_PACKAGES),riscv64)
  PKG_HASH:=c8ed6223719217b4eec18043ab50543d6676f5c4b7c56e5ea44375c63078ccaa
else ifeq ($(ARCH_PACKAGES),x86)
  PKG_HASH:=43795a6da169796d0ff967d54f82aaa9dce69c7018db8419929f1df11ee523f2
else ifeq ($(ARCH_PACKAGES),x86_64)
  PKG_HASH:=a2e1de78ac56220c7b627ed284a2a788cec1a1b4997d6ec4f13da5aa9faefff0
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
