# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=naiveproxy
PKG_REAL_VERSION:=154.0.8037.49-1
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
  PKG_HASH:=f7bbd8796679aadedf03bfaa20a36e6d47322d9047429b8653ada57009dcea60
else ifeq ($(ARCH_PREBUILT),aarch64_cortex-a72)
  PKG_HASH:=82606a0f241b3a6fb03aa49f6037d8649a6934f5c65c9fe6dc58f87bd0c70de0
else ifeq ($(ARCH_PREBUILT),aarch64_generic)
  PKG_HASH:=2de0827b5c07fc19635692b4b21172062072a6e28dcce1b948e7c3b21ffd94e1
else ifeq ($(ARCH_PREBUILT),arm_arm1176jzf-s_vfp)
  PKG_HASH:=cfd8e90e782a6621304361198ff567badbf4faba23d179a81c39d92ee6414a62
else ifeq ($(ARCH_PREBUILT),arm_arm926ej-s)
  PKG_HASH:=0abbd09c29ecf9167dd4518a77fe3ed4471e9c0523ecc792bac55dea035e5f86
else ifeq ($(ARCH_PREBUILT),arm_cortex-a15_neon-vfpv4)
  PKG_HASH:=c0349e9cc22604d034c4296d3be810ffad247957668689bc4978c724c43a3aa2
else ifeq ($(ARCH_PREBUILT),arm_cortex-a5_vfpv4)
  PKG_HASH:=d67a5ad6e42b5c351d04bd9c206c0404c7b10548134ededae1579aedcf4ed488
else ifeq ($(ARCH_PREBUILT),arm_cortex-a7)
  PKG_HASH:=2762af1064db4247557020b4fc1acbd47ec621255f83e12aedb11bc6794df338
else ifeq ($(ARCH_PREBUILT),arm_cortex-a7_neon-vfpv4)
  PKG_HASH:=60902ac1e1b0761c99efa147ee22b2cf2abefe1f00c3586eef475a0e6dfe7ae8
else ifeq ($(ARCH_PREBUILT),arm_cortex-a7_vfpv4)
  PKG_HASH:=cd4325e29650c0a4f899e1c8c8d4f07b31ad643ebd5bba42cfcfd91081735a01
else ifeq ($(ARCH_PREBUILT),arm_cortex-a8_vfpv3)
  PKG_HASH:=573e0ac2db8f035a21546bf9b0a86ac85aafaf83d3ab0b9fa68b9c8cddaa035c
else ifeq ($(ARCH_PREBUILT),arm_cortex-a9)
  PKG_HASH:=f70d1323654678babf3c9c330489ab4f75d2be629f3b4e6beb9ba75e0910f48d
else ifeq ($(ARCH_PREBUILT),arm_cortex-a9_neon)
  PKG_HASH:=372f5a035131403ee325d7aab730dfdee181af195b36dc15405b7aff04c36d63
else ifeq ($(ARCH_PREBUILT),arm_cortex-a9_vfpv3-d16)
  PKG_HASH:=8790bac81dae7de63a443cd1a4ca01b6c8c7ae0f9112625d7e581628b73bc682
else ifeq ($(ARCH_PREBUILT),arm_mpcore)
  PKG_HASH:=c217aaa87a5a805b55244e5a1462c7cc0236024beb57aa47273f6352ddfc17e6
else ifeq ($(ARCH_PREBUILT),arm_xscale)
  PKG_HASH:=ec764d48ccf5f802e43bbe99ef374f31a845960a7a936c64ada1aa2f853ef662
else ifeq ($(ARCH_PREBUILT),mipsel_24kc)
  PKG_HASH:=739b7e0758ec15a9db258e1b08756d521fd189779b92cf789fbe9763138c4d6f
else ifeq ($(ARCH_PREBUILT),mipsel_mips32)
  PKG_HASH:=cba629fc3bd8a73c02ccab4ea1332974bb69a31af173c5d7a9d1ef4930457879
else ifeq ($(ARCH_PREBUILT),riscv64)
  PKG_HASH:=989b2327727a132ec67815c680999ef5fe44bd6017b2b979351cc48311cf02f8
else ifeq ($(ARCH_PREBUILT),x86)
  PKG_HASH:=898dd52ba02f9737aa31d891e0f9b24c2d066ee6de59d49dd52073f9333fa2da
else ifeq ($(ARCH_PREBUILT),x86_64)
  PKG_HASH:=55a10e6ca08696f9b606e1b3cb1a65aba72253756c5e1769d78edd78d4a1c6ab
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
