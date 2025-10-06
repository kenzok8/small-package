# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2025 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=RHash
PKG_VERSION:=1.4.6
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/rhash/RHash/tar.gz/v$(PKG_VERSION)?
PKG_HASH:=9f6019cfeeae8ace7067ad22da4e4f857bb2cfa6c2deaa2258f55b2227ec937a

PKG_LICENSE:=0BSD
PKG_LICENSE_FILES:=COPYING
PKG_MAINTAINER:=Tianling Shen <cnsztl@immortalwrt.org>

PKG_BUILD_PARALLEL:=1
PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk

define Package/librhash
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=C library for computing a wide variety of hash functions
  URL:=https://rhash.sourceforge.io
  DEPENDS:=+libopenssl
  ABI_VERSION:=1
endef

define Package/rhash
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Great utility for computing hash sums
  URL:=https://rhash.sourceforge.io
  DEPENDS:=+librhash
endef

define Package/librhash/description
  LibRHash is a professional, portable, thread-safe C library for
  computing a wide variety of hash functions.
endef

define Package/rhash/description
  RHash (Recursive Hasher) is a console utility for calculation and
  verification of magnet links and various message digests, including
  CRC32, CRC32C, MD4, MD5, SHA1, SHA256, SHA512, SHA3, AICH, ED2K,
  DC++ TTH, BitTorrent BTIH, Tiger, GOST R 34.11-94, GOST R 34.11-2012,
  RIPEMD-160, HAS-160, EDON-R, and Whirlpool.
endef

CONFIGURE_ARGS := \
	--target=$(GNU_TARGET_NAME) \
	--prefix=$(CONFIGURE_PREFIX) \
	--exec-prefix=$(CONFIGURE_PREFIX) \
	--bindir=$(CONFIGURE_PREFIX)/bin \
	--sysconfdir=/etc \
	--disable-gettext \
	--enable-openssl

define Package/librhash/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/librhash.so.* $(1)/usr/lib/
endef

define Package/rhash/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/rhash $(1)/usr/bin/
	$(CP) $(PKG_INSTALL_DIR)/usr/bin/*-{hash,link} $(1)/usr/bin/
endef

$(eval $(call BuildPackage,librhash))
$(eval $(call BuildPackage,rhash))
