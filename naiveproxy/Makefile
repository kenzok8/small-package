# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=naiveproxy
PKG_VERSION:=124.0.6367.54-2
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
  PKG_HASH:=46d8f5871fe74bf3cf6b009844c9ddb6229f146458d187e0074dacc2cbce04bd
else ifeq ($(ARCH_PACKAGES),aarch64_cortex-a72)
  PKG_HASH:=159f099607da6065da5b5629ead40169dfae4efb2d37e439fa6b3b6d205b7a26
else ifeq ($(ARCH_PACKAGES),aarch64_generic)
  PKG_HASH:=2419743b3fc54e87d16483d2d0627273a309d576b8db1b9b5133665ddc47e4ff
else ifeq ($(ARCH_PACKAGES),arm_arm1176jzf-s_vfp)
  PKG_HASH:=3768d3d21ca20072c2bffe2fd0bba1641719a1fee46916ef8e63592a752dbbef
else ifeq ($(ARCH_PACKAGES),arm_arm926ej-s)
  PKG_HASH:=3cf4e512d9baec4d5a4ed6e4362e393d63a6f66e6d66b7a71ea7231dbf84936d
else ifeq ($(ARCH_PACKAGES),arm_cortex-a15_neon-vfpv4)
  PKG_HASH:=80e893563566d4236f221c44f7ea6e1e2367c9b035ea24bb54a9959aece12f02
else ifeq ($(ARCH_PACKAGES),arm_cortex-a5_vfpv4)
  PKG_HASH:=d9d0a7655b969b473c053cbb33f4e65963aa91ba33157e86bcb9cfa6b91ef76c
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7)
  PKG_HASH:=1d772e5ddd9440c414b95fad4a3a85118a074b1cbe39e7a700ab0071d00b6568
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_neon-vfpv4)
  PKG_HASH:=df0d4092657a2e2ccb774e2005b621a90f2391a779465b999f332622cd1d6f25
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_vfpv4)
  PKG_HASH:=bd724596f967397da26c93b1f1c3c489cb6bccb536f10c3c62c38697508f5f3c
else ifeq ($(ARCH_PACKAGES),arm_cortex-a8_vfpv3)
  PKG_HASH:=5d2c24f2d7eaf238ac404f4689af2adb526be9e5ed6a36ea21ec4bc0f9d67ba7
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9)
  PKG_HASH:=1b943d5643e6c382cae896277f674a681443d4dc35a593955374f965794b02f3
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_neon)
  PKG_HASH:=68c41de6be5be53c148880c07cc6c8a217ddf18ec77a7e0dc0af33f3e29ce3ff
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_vfpv3-d16)
  PKG_HASH:=ba7f3e7267ed73b23c6829b4c9368d181d81e336edcf4a61a1dae3dc6d79bc9b
else ifeq ($(ARCH_PACKAGES),arm_mpcore)
  PKG_HASH:=abdb74c84b77a47d7d592faa95ae8c2cbfa828f551e58295d0b41dbf549779d3
else ifeq ($(ARCH_PACKAGES),arm_xscale)
  PKG_HASH:=828173fae3668936cd3c021e588c480ac78d5820e2ac516d3b968b526ea94615
else ifeq ($(ARCH_PACKAGES),mipsel_24kc)
  PKG_HASH:=2571a788140e9d3c9b73c28b5adf087cd406892861e2bd449fcbb1374c93e29b
else ifeq ($(ARCH_PACKAGES),mipsel_mips32)
  PKG_HASH:=2484dadf239727cd46101b56a0f920941e50ca06bee4dd557e88499f22de461e
else ifeq ($(ARCH_PACKAGES),riscv64)
  PKG_HASH:=120beca52a8738c2da5e38f9586e607f59c590602e51380c75d142630a7f6a40
else ifeq ($(ARCH_PACKAGES),x86)
  PKG_HASH:=1ea3bbe494ff50e51a8d8829686df1dbf8c97c5a52abff5247c9159ce6c75b4a
else ifeq ($(ARCH_PACKAGES),x86_64)
  PKG_HASH:=035ad181785673ad2f4e720922125b08a244a253dfc343272f5fbe5b9a3dd8e0
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
