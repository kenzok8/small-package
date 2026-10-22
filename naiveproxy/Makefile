# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=naiveproxy
PKG_REAL_VERSION:=154.0.8037.49-5
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
  PKG_HASH:=8a60b3a5f46e005ebce4785c367a35b4938d127e001f6f365aa7f099fb4a9a64
else ifeq ($(ARCH_PREBUILT),aarch64_cortex-a72)
  PKG_HASH:=f2fdb8f9b5c3de39a3bb34e7b87b2287711362a19b601f41dfa2dd2e65b6f03c
else ifeq ($(ARCH_PREBUILT),aarch64_generic)
  PKG_HASH:=c9930d6e2733817ff773fe10b21c1a890d92a548a3301dfb51ccd3b4234fe938
else ifeq ($(ARCH_PREBUILT),arm_arm1176jzf-s_vfp)
  PKG_HASH:=118ac3344c0b213a3df9101358af7fb2a439fa7d1311577d9ae1af6bb8925abf
else ifeq ($(ARCH_PREBUILT),arm_arm926ej-s)
  PKG_HASH:=202d433a76491a7601cd1fb8b86be2f4c7bb1b08c24e5834a2718850a6a6272f
else ifeq ($(ARCH_PREBUILT),arm_cortex-a15_neon-vfpv4)
  PKG_HASH:=d4c9bfa84e651ab50253f02f2fcef35cf8dc3c86d905ce6e09b610624af32a02
else ifeq ($(ARCH_PREBUILT),arm_cortex-a5_vfpv4)
  PKG_HASH:=b649d16b7403f93f6dc62c9cb6e677f53241b4cc9de0cf21bccaf09b6da07485
else ifeq ($(ARCH_PREBUILT),arm_cortex-a7)
  PKG_HASH:=682a934c0d655ad0a31c4e905f2b9ed91918e8254c9dc5467d07526e3695c256
else ifeq ($(ARCH_PREBUILT),arm_cortex-a7_neon-vfpv4)
  PKG_HASH:=31c9ca7957b5666dc8d22b6afe9158b3f4d95a90258ae0c2bfcfd1aeed9015b7
else ifeq ($(ARCH_PREBUILT),arm_cortex-a7_vfpv4)
  PKG_HASH:=556e39f3b0e236a9d10dd0601e697913f3b4a37bc992d16ef7091b4f222cdacf
else ifeq ($(ARCH_PREBUILT),arm_cortex-a8_vfpv3)
  PKG_HASH:=7d09655729f0722cc475a28c470eef853ae3bfaafbb5ca11dd55aceacb0eb874
else ifeq ($(ARCH_PREBUILT),arm_cortex-a9)
  PKG_HASH:=e577449172d19d512cc6ef79f1de06537d5bda790fd3d25b75c157b3b686d6d8
else ifeq ($(ARCH_PREBUILT),arm_cortex-a9_neon)
  PKG_HASH:=13acec84768976f34934560f01d8eff9820391b89462295d2522f408486566db
else ifeq ($(ARCH_PREBUILT),arm_cortex-a9_vfpv3-d16)
  PKG_HASH:=daa737b4de4c3cdf7b1810970f139a99f801d2221c254077be5081fe5869025c
else ifeq ($(ARCH_PREBUILT),arm_mpcore)
  PKG_HASH:=90ad944064f1311cb6e82b8a39527c214bcf3a0c280158e3a86183395038ddfd
else ifeq ($(ARCH_PREBUILT),arm_xscale)
  PKG_HASH:=6c3ac06266ef5a9bbf5dbb2570f8b66d730b1728628377b4dfbc5eeb4bb76072
else ifeq ($(ARCH_PREBUILT),mipsel_24kc)
  PKG_HASH:=c10cf051130352431da507e336314e5efe354d0c8273f7e8078e741f69527ec5
else ifeq ($(ARCH_PREBUILT),mipsel_mips32)
  PKG_HASH:=750fa5e2fcb677a9fc3a683f79ee9799fb72f3a5dfd435a4b744afda34cc0752
else ifeq ($(ARCH_PREBUILT),riscv64)
  PKG_HASH:=94f4301b38712f33de1b02a393b6d39e59e583fdc721bdfba781287bb4df8ab9
else ifeq ($(ARCH_PREBUILT),x86)
  PKG_HASH:=80dce6376e4a8ed6ee495a9669f9bd368dda2299b4fa683580ad1f83ea6fe06d
else ifeq ($(ARCH_PREBUILT),x86_64)
  PKG_HASH:=1eaf0fdbc1ae5d253502b6095221d6a745ac23241faa83c9afb0a1ad76b9ddfa
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
