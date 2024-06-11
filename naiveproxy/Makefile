# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=naiveproxy
PKG_VERSION:=126.0.6478.40-1
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
  PKG_HASH:=d805374e3c84c199679d120bf38b427f9a2a2572310ba2209ea3f54897021dfa
else ifeq ($(ARCH_PACKAGES),aarch64_cortex-a72)
  PKG_HASH:=2c29345f266d3b7b617756c1bee1d9c9d0c18cd2df5f91778fa3c9ee78cbb6e0
else ifeq ($(ARCH_PACKAGES),aarch64_generic)
  PKG_HASH:=712be9c6c31f92737e3a9aa6345d1797bb76111ba139c95e32f81ca92d9f94d8
else ifeq ($(ARCH_PACKAGES),arm_arm1176jzf-s_vfp)
  PKG_HASH:=9eb54e9e5aaa46c6555275ab1760c5597ff882fd44d3c7b861f74bdb1f11b7ee
else ifeq ($(ARCH_PACKAGES),arm_arm926ej-s)
  PKG_HASH:=165d08dce7efccc0dd09aed9d09745e3932a9f9090d2aece21fc3ba9cf7c8d7f
else ifeq ($(ARCH_PACKAGES),arm_cortex-a15_neon-vfpv4)
  PKG_HASH:=2814ee81d18154af761dde96449108e12c7a076e839fb6adc90914602118afb5
else ifeq ($(ARCH_PACKAGES),arm_cortex-a5_vfpv4)
  PKG_HASH:=0a9d2f15e85b6a93580173b8a5a2527d40926fce70272570e2101f82c5bb96df
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7)
  PKG_HASH:=f62ea0698f39f30d0845c3f81389d1fc929fccacf6bd92794803dc9c40397228
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_neon-vfpv4)
  PKG_HASH:=55d7c177689f4d598ee45dcf4f8f837e62accdec99c3939ed351bad6abe92f46
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_vfpv4)
  PKG_HASH:=f9c00185b42913cf5623f4caa3eb9ba7883da6c0f304506889cc798e0c987a11
else ifeq ($(ARCH_PACKAGES),arm_cortex-a8_vfpv3)
  PKG_HASH:=54285cd36969fb7a90624b569fd1c0dcbded72a992597793936f5efb7789f0c9
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9)
  PKG_HASH:=016895a8fa4a6ec36efa4a4890566bf33ea888526a8902da1b915573006d8dab
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_neon)
  PKG_HASH:=d2508c999796c4e65a93044faa243a3640dfd9be36cf758535b7a801e61149a5
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_vfpv3-d16)
  PKG_HASH:=0687360a7488b534818df5db071ff0feae8a0a8e6c0464fe0f64533d63682841
else ifeq ($(ARCH_PACKAGES),arm_mpcore)
  PKG_HASH:=13cdb19c23add28f8cc02b9d0234db5836e851ef3ff4968363da27f6045b94ae
else ifeq ($(ARCH_PACKAGES),arm_xscale)
  PKG_HASH:=a9d4e1825a391ef9294b58d765cc6425322848a70b29f64955c5933121990288
else ifeq ($(ARCH_PACKAGES),mipsel_24kc)
  PKG_HASH:=7b358d7306f77f87bcee33beb6be1d8c1d70c2128172475616bb1531bb3aa908
else ifeq ($(ARCH_PACKAGES),mipsel_mips32)
  PKG_HASH:=1bc0af17f48b83e2439534f91d462b286d8c35888bfee87785f70337088a5d32
else ifeq ($(ARCH_PACKAGES),riscv64)
  PKG_HASH:=8862ca30f93825298a00473fddbf698ffed251deef28a40958c3ccd06da91e6a
else ifeq ($(ARCH_PACKAGES),x86)
  PKG_HASH:=c403e1bd29d19dcf811e034bf6cc6940c6ef9425b80d87a1643000e7361016aa
else ifeq ($(ARCH_PACKAGES),x86_64)
  PKG_HASH:=d88b2cc80fb3b79f13f0f1d426d2b2dda9127b0b24f477c008b4c8cfa86d99ce
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
