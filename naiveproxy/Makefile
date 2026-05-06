# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=naiveproxy
PKG_VERSION:=148.0.7778.96-3
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
  PKG_HASH:=bbde023c1dbfe7bdad216bafb6313ab541ed77ad9f7d0d82460757918cae6df9
else ifeq ($(ARCH_PACKAGES),aarch64_cortex-a72)
  PKG_HASH:=9a64e5c07891e8b3022259011d3191074470c6e89c8810aba545626b9eece8ee
else ifeq ($(ARCH_PACKAGES),aarch64_generic)
  PKG_HASH:=1b716eb1d7de64efa3f2ffd8715d4544a7eac94cab531ff4d40cf7145589d9e5
else ifeq ($(ARCH_PACKAGES),arm_arm1176jzf-s_vfp)
  PKG_HASH:=7dbe00c794688d0e06584a68b04b94bcfba7ef3aacb72076124a9ba67028f8d3
else ifeq ($(ARCH_PACKAGES),arm_arm926ej-s)
  PKG_HASH:=51006b0fab95ebfc9fb11f0e758c040c7652420419d9a774cea0dcc227a85e4e
else ifeq ($(ARCH_PACKAGES),arm_cortex-a15_neon-vfpv4)
  PKG_HASH:=e0d1cd847e2328f55199fd314f6b6e31e7b15c0411f97567515e2b2e8d420c42
else ifeq ($(ARCH_PACKAGES),arm_cortex-a5_vfpv4)
  PKG_HASH:=01e13dc837ce980833393d6dc8e49ed5f0324746d4d88efbcd34c8d8f3007b2d
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7)
  PKG_HASH:=0c10d087bf3a16e9b9443464ccacc392ecf71b96443e2eb01509252528acbfa7
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_neon-vfpv4)
  PKG_HASH:=af51b4f5fe1b9cd03655771b62a4a206d7b276e418a23fbffeb76b6d7fd882f4
else ifeq ($(ARCH_PACKAGES),arm_cortex-a7_vfpv4)
  PKG_HASH:=4c1b616e1af9aa39511cfd8e63c0686f0ff59999f3419493a373e2398ad15322
else ifeq ($(ARCH_PACKAGES),arm_cortex-a8_vfpv3)
  PKG_HASH:=f7ec9f48c42e31c6f77f86fd66de15230efa3b668c87807f0441e72a52d544ab
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9)
  PKG_HASH:=d6a6724da33133990e0f09dbdb33d8f853ff900d3c8e64242f3715a0b0ac8c18
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_neon)
  PKG_HASH:=2df21a2d16294d5c02af008ba6f6c7dd7cc06ba8440695a36e4982eab946fafe
else ifeq ($(ARCH_PACKAGES),arm_cortex-a9_vfpv3-d16)
  PKG_HASH:=e949c098d17bf64aeb0dfc0e5a107ac63ac7dd02272d18a1402939a5ffdefbf5
else ifeq ($(ARCH_PACKAGES),arm_mpcore)
  PKG_HASH:=860314efc8fc133c5a027bd98e748ae0700c0832da392f7d713907861f17311c
else ifeq ($(ARCH_PACKAGES),arm_xscale)
  PKG_HASH:=edc5a3eff99a917f4bd1bd63c99c9184c09a991d36fa4e09c58cfa16da0f959d
else ifeq ($(ARCH_PACKAGES),mipsel_24kc)
  PKG_HASH:=3387e2218d001a389db2a934d2e065465de405a2c5a33992f38403db77a7e70a
else ifeq ($(ARCH_PACKAGES),mipsel_mips32)
  PKG_HASH:=7688a70061b5e72612bd73a52a4ce48a30890c8a97a3d40520fa209bf7b1288a
else ifeq ($(ARCH_PACKAGES),riscv64)
  PKG_HASH:=2fe630d1671737cea393d696464ae76a31bc7d10d152ea5738fb792fb79a3843
else ifeq ($(ARCH_PACKAGES),x86)
  PKG_HASH:=9460e0a0a083798e282dc54c48ff6b75b0ee37a811065454c7c10e19a36300ac
else ifeq ($(ARCH_PACKAGES),x86_64)
  PKG_HASH:=1a52c96e15ce3ac0069ca7ff7eb8807f86c661dd62eb76cf37c8b7ff066d9443
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
