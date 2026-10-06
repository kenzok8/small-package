# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=naiveproxy
PKG_REAL_VERSION:=154.0.8037.49-3
PKG_VERSION:=$(subst -,.,$(PKG_REAL_VERSION))
PKG_RELEASE:=1

ARCH_PREBUILT:=$(ARCH_PACKAGES)
ifeq ($(ARCH_PREBUILT),aarch64_cortex-a76)
  ARCH_PREBUILT:=aarch64_generic
else ifeq ($(ARCH_PREBUILT),i386_pentium-mmx)
  ARCH_PREBUILT:=x86
else ifeq ($(ARCH_PREBUILT),i386_pentium4)
  ARCH_PREBUILT:=x86
else ifeq ($(ARCH_PREBUILT),riscv64_riscv64)
  ARCH_PREBUILT:=riscv64
endif

ifeq ($(ARCH_PREBUILT),aarch64_cortex-a53)
  PKG_HASH:=16aee40b354df9c320fbaf6b6bebb82c4453c40015e0a8e16f693b5ad1667976
else ifeq ($(ARCH_PREBUILT),aarch64_cortex-a72)
  PKG_HASH:=b64125e9edae065ba608cee7505b7a8ed4ec7f3c14c0b758b90ff053d69435b4
else ifeq ($(ARCH_PREBUILT),aarch64_generic)
  PKG_HASH:=f9f776f31fdf563f695a4bbea134f908eab51e70c145df334273304d0b8ab54b
else ifeq ($(ARCH_PREBUILT),arm_arm1176jzf-s_vfp)
  PKG_HASH:=ea335311fc4ed5e2d2cc3e89d2421b147bb2c8bce0c03be744aa03a0fa3a4051
else ifeq ($(ARCH_PREBUILT),arm_arm926ej-s)
  PKG_HASH:=a54c7b8b79344fab351c5bd141e76749689307b41a53a5803499c73b27ecc185
else ifeq ($(ARCH_PREBUILT),arm_cortex-a15_neon-vfpv4)
  PKG_HASH:=1ea2271c873eb84c263187e5b82cb752c6e5eab7a75928143c41871fd91d0ed2
else ifeq ($(ARCH_PREBUILT),arm_cortex-a5_vfpv4)
  PKG_HASH:=5b1a329b3296d05d8479c0fb09f8f92d6884d1747189fc1a916dc23eb228e09e
else ifeq ($(ARCH_PREBUILT),arm_cortex-a7)
  PKG_HASH:=b6c8a7575a4fcbd57048904fbd1235adf8532d413ae673531b080d63b3cb50a7
else ifeq ($(ARCH_PREBUILT),arm_cortex-a7_neon-vfpv4)
  PKG_HASH:=9c430b572d0028125c5c684bb1c7f8b3c70fa003083b9c1ec28c59e0fe0035ab
else ifeq ($(ARCH_PREBUILT),arm_cortex-a7_vfpv4)
  PKG_HASH:=764b2b4c686299e705b4da9c04f05537bdf6dfcef93bf5eeab216c0c7d6615ae
else ifeq ($(ARCH_PREBUILT),arm_cortex-a8_vfpv3)
  PKG_HASH:=bc4e2ab807c82728a89c0b93dd4add3bfdaaa14f25bd9150b9ddd4cb1ee10f38
else ifeq ($(ARCH_PREBUILT),arm_cortex-a9)
  PKG_HASH:=72faf0d3347d8d144313cd3ef68e59753b86bf988765ce3e95b888ea65ec78f4
else ifeq ($(ARCH_PREBUILT),arm_cortex-a9_neon)
  PKG_HASH:=be316f5a7031bae31cb865144b11b862432d90a569edba0ecf75e015fba7b3d9
else ifeq ($(ARCH_PREBUILT),arm_cortex-a9_vfpv3-d16)
  PKG_HASH:=cdcbbc212199365c64d396c744a917247cd164e514e1dbee600f4a7ebcab7952
else ifeq ($(ARCH_PREBUILT),arm_mpcore)
  PKG_HASH:=3401110e25d6ad09f3e198da3ca24a85b1cdc1c674f8fe729b64d3b8a4355700
else ifeq ($(ARCH_PREBUILT),arm_xscale)
  PKG_HASH:=9b073c716b1399dcfdef6b4f64d6db9429d2aed9245bc6262a614f3612ae091a
else ifeq ($(ARCH_PREBUILT),mipsel_24kc)
  PKG_HASH:=0de76d80deb8f6b02ec9792382d1c47a38911ff617c5b487d5714acf0bc19ced
else ifeq ($(ARCH_PREBUILT),mipsel_mips32)
  PKG_HASH:=2ef2416f572e967af75117f3beb49e4b75d5daf4988a1c2965aeaead1c4c3543
else ifeq ($(ARCH_PREBUILT),riscv64)
  PKG_HASH:=84c9e8bf65100f5d49d6d8e160a954fa98420b3362b189cee6837a6b4d1e139b
else ifeq ($(ARCH_PREBUILT),x86)
  PKG_HASH:=a6fc59afaa8ee989edda0ac6e3d51ac0b16e3eafb7d9d594b4674e6a493f817c
else ifeq ($(ARCH_PREBUILT),x86_64)
  PKG_HASH:=ad4a14d2bcc565b2c59f2e65e588e739ed0626f282f68c7611a72660b520f4a1
else
  PKG_HASH:=dummy
endif

PKG_SOURCE:=naiveproxy-v$(PKG_REAL_VERSION)-openwrt-$(ARCH_PREBUILT).tar.xz
PKG_SOURCE_URL:=https://github.com/klzgrad/naiveproxy/releases/download/v$(PKG_REAL_VERSION)/
PKG_BUILD_DIR:=$(BUILD_DIR)/naiveproxy-v$(PKG_REAL_VERSION)-openwrt-$(ARCH_PACKAGES)

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
