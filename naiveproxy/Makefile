# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=naiveproxy
PKG_VERSION:=130.0.6723.40-1
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
  PKG_HASH:=8a9b00a09775c6eb06aaaa8dca6e669f9e6770e69f4cd8659afff40a658dbdfd
else ifeq ($(ARCH_PACKAGES),aarch64_cortex-a72)
  PKG_HASH:=380ba36e4a3f72507f015b06464aac32d1caf8e644f26e0406ca1a6dbf2d923a
else ifeq ($(ARCH_PACKAGES),aarch64_generic)
  PKG_HASH:=ae7b2e46f4af02ff4575818f34d62aae29e37f7b63d48b81e052dd14d4ac2df0
else ifeq ($(ARCH_PACKAGES),arm_arm1176jzf-s_vfp)
  PKG_HASH:=b075856d134ed7f354feb27bc4b16a91d7cc8c453f52b648524f39ac036848fe
else ifeq ($(ARCH_PACKAGES),arm_arm926ej-s)
  PKG_HASH:=b353f5727dc9ba7cc9bca1b6dc801df723979929e3ebfa3421b7d54f01713a4b
else ifeq ($(ARCH_PACKAGES),arm_cortex-a15_neon-vfpv4)
  PKG_HASH:=8649129535259cbbbfeaf2cccad1814b23fe5639c8d0d518424d589cb80b3901
else ifeq ($(ARCH_PACKAGES),arm_cortex-a5_vfpv4)
  PKG_HASH:=87aa43d7d73980aff913cba2655be5e2f8a565e8f842c59987e17555f944adaf
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7)
  PKG_HASH:=83a77062745dab1e2a4567949d4351decc2080fa818b8ade564ff8e84426b9cc
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_neon-vfpv4)
  PKG_HASH:=649e037d487a0eb73fca039b7c933534864b53135c98a6a12fe96b5073a1aef4
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_vfpv4)
  PKG_HASH:=b274c3e05d3a56d473da9f5646300be5eea100f4df8b2e517dd096d1ea162a90
else ifeq ($(ARCH_PACKAGES),arm_cortex-a8_vfpv3)
  PKG_HASH:=7901f9417c651e81e9a22c2f56d98ec4d6dd4397b1a8ade91efe6fddde63acdc
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9)
  PKG_HASH:=afb57e18ad9c124e99424128bffc6145ab48c6e1a25e4e67ad803b28c7841dda
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_neon)
  PKG_HASH:=a6fe68edc537e56f41bd1ea30d0f8e0f9a585b6e464be7ad4042a72cac8c680e
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_vfpv3-d16)
  PKG_HASH:=536ac7ea4be5861c3180e53e7da08f7d14c78ee7fdfdad6a17d8bb209881d227
else ifeq ($(ARCH_PACKAGES),arm_mpcore)
  PKG_HASH:=69df31e745eb5f075d3034ebe403c5faac327a9080aedd3c2bc89eacb4af6430
else ifeq ($(ARCH_PACKAGES),arm_xscale)
  PKG_HASH:=e2683fa31170ca028220dd8cc9fdf106ea6ead13f1e6884b12e64e8d0c7162b6
else ifeq ($(ARCH_PACKAGES),mipsel_24kc)
  PKG_HASH:=75a91c3904936b5df73de8a98cba8ac172aed9f37c22927d806cdcd1d4d501a7
else ifeq ($(ARCH_PACKAGES),mipsel_mips32)
  PKG_HASH:=f61729049d32d1144742432dcc86cc1bb61c8bd1cd81bbd0c72bb8e1304d398a
else ifeq ($(ARCH_PACKAGES),riscv64)
  PKG_HASH:=1eed7c722c1620bea6a1cfbe7b7d446817250599e9011657f3dd6546c030bfc1
else ifeq ($(ARCH_PACKAGES),x86)
  PKG_HASH:=270216b334f72c4434a27239fc3205989c1a17b96956ec357e921a7e9803a2a4
else ifeq ($(ARCH_PACKAGES),x86_64)
  PKG_HASH:=1a23923954b35a73a0d279942c5c2ccb54578379eab631a3404662e2217e6b4a
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
