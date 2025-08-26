# SPDX-Identifier-License: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

ifeq ($(ARCH),aarch64)
  PKG_ARCH_VERYSYNC:=arm64
  PKG_HASH_VERYSYNC:=66bce5e9725969c4aa9ec057830f5197156526b2a2ff8ae92ae155cd4665fd8b
else ifeq ($(ARCH),arm)
  PKG_ARCH_VERYSYNC:=arm
  PKG_HASH_VERYSYNC:=33a1831fa26910a57a5fdf82ed2ba8ccf58bab41e10b989e546cfaf69371fccc
else ifeq ($(ARCH),i386)
  PKG_ARCH_VERYSYNC:=386
  PKG_HASH_VERYSYNC:=976210bf42da9b5a39ee8d41cce3b4edc3c1d9045192617a5b4b063f8182af74
else ifeq ($(ARCH),mips)
  PKG_ARCH_VERYSYNC:=mips
  PKG_HASH_VERYSYNC:=7362b933f561ebaa63d6c660971799ff153d0317e4d70812982f3cfbd678ba65
else ifeq ($(ARCH),mipsel)
  PKG_ARCH_VERYSYNC:=mipsle
  PKG_HASH_VERYSYNC:=2ed1feee9b5ea6cd3a39e4c5d556b8b29629d194f91b077ac2f7573f5733fb2e
else ifeq ($(ARCH),powerpc64)
  PKG_ARCH_VERYSYNC:=ppc64
  PKG_HASH_VERYSYNC:=3e2c8bb40812fec7db80b27b196746c6ba66684e4d882aa35284c3eba1de86ba
else ifeq ($(ARCH),x86_64)
  PKG_ARCH_VERYSYNC:=amd64
  PKG_HASH_VERYSYNC:=340ef24c27e4aa4df5a52824c63f8fb407947e75174673d94c18df4a8664287b
else ifeq ($(ARCH),riscv64)
  PKG_ARCH_VERYSYNC:=riscv64
  PKG_HASH_VERYSYNC:=348669525a5ef80b70ab3570d8bfc558bafdbbad6954fc2eeb3d55ab972be864
else ifeq ($(ARCH),loongarch64)
  PKG_ARCH_VERYSYNC:=loong64
  PKG_HASH_VERYSYNC:=c70ea700ebaad77c2d98ac9580191bd1bfaae4b0a5590382e29ffb8b73ab3550
endif

PKG_NAME:=verysync
PKG_VERSION:=2.21.3
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-linux-$(PKG_ARCH_VERYSYNC)-v$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=http://dl.verysync.com/releases/v$(PKG_VERSION)/ \
		http://dl-cn.verysync.com/releases/v$(PKG_VERSION)/
PKG_HASH:=$(PKG_HASH_VERYSYNC)
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-linux-$(PKG_ARCH_VERYSYNC)-v$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/verysync
  SECTION:=net
  CATEGORY:=Network
  TITLE:=A efficient data transmission tool
  URL:=http://www.verysync.com
  DEPENDS:=@(aarch64||arm||i386||mips||mipsel||powerpc64||x86_64||riscv64||loongarch64)
endef

define Build/Compile
endef

define Package/verysync/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/verysync $(1)/usr/bin/verysync
endef

$(eval $(call BuildPackage,verysync))
