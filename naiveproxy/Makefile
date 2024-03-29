# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=naiveproxy
PKG_VERSION:=122.0.6261.43-2
PKG_RELEASE:=1

ifeq ($(ARCH_PACKAGES),aarch64_cortex-a53)
  PKG_HASH:=3f7ba5f4660f801e675aac8124bd7da714ff9b5a11c72955086ed4914fdd0600
else ifeq ($(ARCH_PACKAGES),aarch64_cortex-a72)
  PKG_HASH:=4027ff6b5d14ea0b4921f1048c2fa639c368b360bd34dd35bc5827c7377ba7ac
else ifeq ($(ARCH_PACKAGES),aarch64_generic)
  PKG_HASH:=eb500d7baf5b05e1a4dbdd3554168a21ae60bb72efcb58f14357ca2f089e04c4
else ifeq ($(ARCH_PACKAGES),arm_arm1176jzf-s_vfp)
  PKG_HASH:=5403ef027fe947747397c961c08c73f8cf362023a94fb471b3e27e6150b0cd70
else ifeq ($(ARCH_PACKAGES),arm_arm926ej-s)
  PKG_HASH:=c115af1a2543028e4ce639aefb89ab74d98de30c9cdd34f50831c1636e19a406
else ifeq ($(ARCH_PACKAGES),arm_cortex-a15_neon-vfpv4)
  PKG_HASH:=67a17ce9b4c03915a552004b93b8245b2572b1f783d760c53fb683b46f112ce7
else ifeq ($(ARCH_PACKAGES),arm_cortex-a5_vfpv4)
  PKG_HASH:=86bd10f78e3ba1965021d1d2e09f7cd0857757e41409eca7059f9c455e23e4c2
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7)
  PKG_HASH:=fc1ce37ae04f8891fe987ecef2d3d0e3a738cc2c4063392593446f511c0d98e5
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_neon-vfpv4)
  PKG_HASH:=22434167977afcaf058c2723c6040d160680a73dcab150f2503be19a6dff584d
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_vfpv4)
  PKG_HASH:=5a1dd8a0b8dc3f7e321de879268ebcb01f2da29d631d58db2383af0fd620fe48
else ifeq ($(ARCH_PACKAGES),arm_cortex-a8_vfpv3)
  PKG_HASH:=a4d69095ff5e2d9c648c80d8ab71e9f238ff99dfde2ca9e29a70c0368342be1c
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9)
  PKG_HASH:=724982946f4104930247433c3d2d9240cf4e7745dcea3ca754e83f40f10d5347
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_neon)
  PKG_HASH:=2bd65dbe753941086dd460e94052841664a16e85aaffe318542023f5fd054460
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_vfpv3-d16)
  PKG_HASH:=0f4278d97f748087844059361c926b073d1aa2173b0c643daa83f459e5eb85a2
else ifeq ($(ARCH_PACKAGES),arm_mpcore)
  PKG_HASH:=728f283752112aee9a4e5b6eb51a12bdee2abb8e48450607b6e378dc7b4f0ef6
else ifeq ($(ARCH_PACKAGES),arm_xscale)
  PKG_HASH:=a49acbc682c36cc5782eb0a2572dd3f9dd65def14e5b4fedf4cbcf2415a578eb
else ifeq ($(ARCH_PACKAGES),mipsel_24kc)
  PKG_HASH:=335c8c8574adc591a6d6456b7e8e46557dee40dce05fef62bcd2a806bc59bfd5
else ifeq ($(ARCH_PACKAGES),mipsel_mips32)
  PKG_HASH:=1f6845debaa59fd48a57f500f65d7996ed3d0276b9be1ea5b81d8bf299641165
else ifeq ($(ARCH_PACKAGES),riscv64)
  PKG_HASH:=7eae492c39f6b8d56d03a56e5eec5b5bfa390f44a2573941b5291412eca5d273
else ifeq ($(ARCH_PACKAGES),x86)
  PKG_HASH:=85afd988a9c63643bc6dc70e52c9d6b83cac489dba1efd8aef04591c8d832662
else ifeq ($(ARCH_PACKAGES),x86_64)
  PKG_HASH:=abc5990ecf9cbe1e552468d9e53986698de3f0328261f5e18fdedb70a1afd581
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
  DEPENDS:=@!(arc||armeb||mips||mips64||powerpc||TARGET_gemini) +libatomic
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