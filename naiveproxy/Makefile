# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=naiveproxy
PKG_VERSION:=139.0.7258.62-1
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
  PKG_HASH:=88b631884518ad25eaee00350445824bb962283cf7665519d4d7b242605a95a4
else ifeq ($(ARCH_PACKAGES),aarch64_cortex-a72)
  PKG_HASH:=c8196e4ac5e60c933cdce968b1e630abf3577de1258a4c330eb99ea8649a177a
else ifeq ($(ARCH_PACKAGES),aarch64_generic)
  PKG_HASH:=7fa990948c429c36fd0778cd9125e08aed79d5e92be6675951540ddd7069b2fb
else ifeq ($(ARCH_PACKAGES),arm_arm1176jzf-s_vfp)
  PKG_HASH:=51db374620c21797a732d11e17b7ddc31e9be681804ea3145938a24320aaa66a
else ifeq ($(ARCH_PACKAGES),arm_arm926ej-s)
  PKG_HASH:=abf5db455d57de10dec4b5e5d37903293bcbbe80a3baeb33aded53fb4d503db1
else ifeq ($(ARCH_PACKAGES),arm_cortex-a15_neon-vfpv4)
  PKG_HASH:=4ea19599f0287da886c79b93d3ac7ae03727402587fa3af5fdd3d12ad2e2a58e
else ifeq ($(ARCH_PACKAGES),arm_cortex-a5_vfpv4)
  PKG_HASH:=6824c79925f5cc9c3a8fd8a2090c982a0b30c0ce014aa90f99a2f36ed68ada9d
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7)
  PKG_HASH:=456c896ac9a26d41a6bc0aea74262780516203a143cfb530906ac9a580d35ab5
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_neon-vfpv4)
  PKG_HASH:=0ac6f60ba0b90ef38aa88f1172b7119e07ec775b1776594afb51452f5b4af125
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_vfpv4)
  PKG_HASH:=361341cd9300e071f06545d92bf355bd83fe415af7392cffcd503e9207f273e5
else ifeq ($(ARCH_PACKAGES),arm_cortex-a8_vfpv3)
  PKG_HASH:=04eaadc2c6cf300c788d8531cdf04821c91a751bae720c2fc4631ec6445a0cd8
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9)
  PKG_HASH:=523af9336b72da3a32f38d1975e86f15bdc859234f8e7f0a3c664fc31da2ce3f
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_neon)
  PKG_HASH:=b20c2e0c098503d8b57c6ab70d70de401bb642a474521ccf0e700756ad7ed8e1
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_vfpv3-d16)
  PKG_HASH:=9658d4f6a9a7e753774b1b231808c5267addc7cea94e2e93e7f823ec84e279e3
else ifeq ($(ARCH_PACKAGES),arm_mpcore)
  PKG_HASH:=cfdcc0bfd70c689b01af8ebcc712f8a1431aeba77a4bc1522444268f9864d12d
else ifeq ($(ARCH_PACKAGES),arm_xscale)
  PKG_HASH:=5c7706b1cb19e27d4c0135feea6af245e19af684b9e2bb38c3cea80c9adb970c
else ifeq ($(ARCH_PACKAGES),mipsel_24kc)
  PKG_HASH:=70e248ffa44a067ced6c178f3aef09097e7bbd6030cb7d3776866880ad954eb6
else ifeq ($(ARCH_PACKAGES),mipsel_mips32)
  PKG_HASH:=a49e6088ddb1af6135fa2a46ba5c55db66b4a2ecd46cb6daf3776181a2e62296
else ifeq ($(ARCH_PACKAGES),riscv64)
  PKG_HASH:=4f8163daea361188f8eec3c1794b78416b898aff226e33e82f8ae6f96d403ac3
else ifeq ($(ARCH_PACKAGES),x86)
  PKG_HASH:=02e38a354b26ed8ebe7a753bac2f8a4a4b4210a23dcb430de0ab88b88b689f92
else ifeq ($(ARCH_PACKAGES),x86_64)
  PKG_HASH:=df910463af15f53b5540dcb23a9858ba73dd2bc336eea9625ba0360bd3b29042
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
