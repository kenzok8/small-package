# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=naiveproxy
PKG_VERSION:=136.0.7103.44-1
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
  PKG_HASH:=639e748f39380bbb146b437c2c8844d0ba73157bd0bb6570656effbf0573b2d5
else ifeq ($(ARCH_PACKAGES),aarch64_cortex-a72)
  PKG_HASH:=8c27f966bd9b98f68e594b0c876fc3cb08a4bd46d0c6c796b98765cd3d52456a
else ifeq ($(ARCH_PACKAGES),aarch64_generic)
  PKG_HASH:=fa2608512e2ccdb532474de847daa9519e100274ecb5e0b8a28702f04e322306
else ifeq ($(ARCH_PACKAGES),arm_arm1176jzf-s_vfp)
  PKG_HASH:=8630dd33bdaa7c3b70f83e709f99a8dff223ce44cd259c6b74c1937117c9adf3
else ifeq ($(ARCH_PACKAGES),arm_arm926ej-s)
  PKG_HASH:=9fc02031a8bca7352f68bd7375e56c8e2149fdd1cd7f77534a86be8cd40532bf
else ifeq ($(ARCH_PACKAGES),arm_cortex-a15_neon-vfpv4)
  PKG_HASH:=392a4c05e22cfa5bf13d70675b0f1fa3d977f1396192aa626baad998089d5097
else ifeq ($(ARCH_PACKAGES),arm_cortex-a5_vfpv4)
  PKG_HASH:=0302503e6270ec48427f13816b6608eb80241598256692a2911c9f52057153ca
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7)
  PKG_HASH:=2b1d569eb8f47ad6499d8f26b15fede9257c69e447dc8ad3a36954dbc131f0a4
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_neon-vfpv4)
  PKG_HASH:=3822c2f6ffbbdeacb6182d4e24cd2551f2cf30a31f9f38d6c059833772ee1fd6
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_vfpv4)
  PKG_HASH:=3b734e692a6ae2b17e53a10775bb3f23a89b15724b745b7b0d78f738f5cab9b4
else ifeq ($(ARCH_PACKAGES),arm_cortex-a8_vfpv3)
  PKG_HASH:=e90eeb26167f1f0360d2c94ca1116ff24a66875fa83105cadaa2665a2aa7d346
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9)
  PKG_HASH:=2ceb7baeec30fee26b15b76ad6e40922934509a6f03598ecdd53e6080e87172d
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_neon)
  PKG_HASH:=c2605ba10c7631c9ada9231de2af5ed23850b04b244003b96462b71959fc908a
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_vfpv3-d16)
  PKG_HASH:=65dae408d2c56accd6e5ddb99df104df792d87a92b0d55f36ed2596ccbdfd8c9
else ifeq ($(ARCH_PACKAGES),arm_mpcore)
  PKG_HASH:=b4b9073edda26281b6913834f04802beb40308bc06237091de38649c74295c22
else ifeq ($(ARCH_PACKAGES),arm_xscale)
  PKG_HASH:=cb051087fa4f3b58546d5c746349190163eff80635a0a1ab9ffc17b9c867129f
else ifeq ($(ARCH_PACKAGES),mipsel_24kc)
  PKG_HASH:=f01eb9a10300ac6f7d5cd9759a9a47980a9c9c8c5868e25b705c63e711706032
else ifeq ($(ARCH_PACKAGES),mipsel_mips32)
  PKG_HASH:=cf4c5f8eafba8420dbdc624b228f48f4cc9089c1cec14bb7178e44709896a798
else ifeq ($(ARCH_PACKAGES),riscv64)
  PKG_HASH:=0b755b2613e2a66b3ca5d6db20b9207a60cd0ac45fd166df6aa6a2d13acc24cb
else ifeq ($(ARCH_PACKAGES),x86)
  PKG_HASH:=7e90b9c94751c17c674a5da0a7cfd7ab28bc6657e5a698e3f7e60ec6d3ae2858
else ifeq ($(ARCH_PACKAGES),x86_64)
  PKG_HASH:=bfb9d0b7f7f48e7ab6cbcf8389e2b239c68ad608331bd03b0ab68ddf0ebff019
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
