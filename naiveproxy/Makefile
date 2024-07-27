# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=naiveproxy
PKG_VERSION:=127.0.6533.64-1
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
  PKG_HASH:=76d6bf0891d72f2083f497aba44e9e7eb86ad420b5556a5c01857cfafb567b18
else ifeq ($(ARCH_PACKAGES),aarch64_cortex-a72)
  PKG_HASH:=5e1ec15ec4fb1145a64f5befb18c49b9b970438bba57dd8d5c6a9043803bcf8d
else ifeq ($(ARCH_PACKAGES),aarch64_generic)
  PKG_HASH:=864deabbb035a4ec7df589b796bfa2838c5ebaebdb2d91df0a900a8a239d760f
else ifeq ($(ARCH_PACKAGES),arm_arm1176jzf-s_vfp)
  PKG_HASH:=9b6f8e8ccf771305f722bad7d8454464f7fd993a62f9c4a4c187767eb3e61605
else ifeq ($(ARCH_PACKAGES),arm_arm926ej-s)
  PKG_HASH:=d9fb0c29f7c6b79afc0375751859b0db673d3355c0a5a69762f763de5d54b38e
else ifeq ($(ARCH_PACKAGES),arm_cortex-a15_neon-vfpv4)
  PKG_HASH:=964a92e915220963a94a6556db96a09c903fc3dfd4e6b2ae1a837f5b24a63945
else ifeq ($(ARCH_PACKAGES),arm_cortex-a5_vfpv4)
  PKG_HASH:=04deb25636983504a593d5c1627d1d336672afccf3c8dd75e7919e77171a9ab2
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7)
  PKG_HASH:=868ac8c97f6e8a7b4097e1a20b46c723a1caa31508e3844d470b38f820ef5976
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_neon-vfpv4)
  PKG_HASH:=ddb14e435dc396c5228647bc15fb2e3cbd49a15a5fc2c280a11417b0ad0d37c9
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_vfpv4)
  PKG_HASH:=fc7a83ab309dcdf7f3ea2ed44ad9a37b3efedfb850372042bb8853e3b3bb784d
else ifeq ($(ARCH_PACKAGES),arm_cortex-a8_vfpv3)
  PKG_HASH:=5eb32a09c30a7932bfe20bca6226d459eef7517796ea38065446b2bbaee8e0cc
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9)
  PKG_HASH:=197b1bd818f6cfd349f2077a408d2186ef430b762a65fbb6c2846599497895b7
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_neon)
  PKG_HASH:=a5f8461fa6b11fa9a53f8c41b450aed7cec8bcd0e690bc2316ec868cbf8b565a
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_vfpv3-d16)
  PKG_HASH:=09077a6318039baff022fb673a94cbce3a270338213bc0c063e9c0da168c2982
else ifeq ($(ARCH_PACKAGES),arm_mpcore)
  PKG_HASH:=eeada4b34728c5052a75abb2e55a5f0a45b66f6d220483e1c4407adb0a4eb55e
else ifeq ($(ARCH_PACKAGES),arm_xscale)
  PKG_HASH:=b5fdde4063613c7209e45fcea0c70a447f31569a916780ab1738011819d37a13
else ifeq ($(ARCH_PACKAGES),mipsel_24kc)
  PKG_HASH:=49c6722aeb41994fa919f52cfb36a80354862673837879d2432d08f8d55ba182
else ifeq ($(ARCH_PACKAGES),mipsel_mips32)
  PKG_HASH:=da35f403614f3aab9b6252fad490cf1e3cbb79ea97cfd9a047cecde5787bd9a5
else ifeq ($(ARCH_PACKAGES),riscv64)
  PKG_HASH:=2cb07b68527032329ded3ab3ccbe66930cd6b7bd523787e90305a5476594a41f
else ifeq ($(ARCH_PACKAGES),x86)
  PKG_HASH:=2010757b3555ae78a529f5b2261edf339bb5052b543558423444c133c34107d6
else ifeq ($(ARCH_PACKAGES),x86_64)
  PKG_HASH:=3a0d15a8fa4c15a4f55f80367a30b1621cbb2ed2be826e9f3a5360ffef08552e
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
