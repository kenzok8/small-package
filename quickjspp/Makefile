# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=quickjspp
PKG_RELEASE:=$(AUTORELEASE)

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ftk/quickjspp.git
PKG_SOURCE_DATE:=2022-02-05
PKG_SOURCE_VERSION:=8efd98903fca507e58144865d26c47c91565bb55
PKG_MIRROR_HASH:=dd9e69c41adf7991ce414b399d3e6188fa1b9421f74c722a084b1269985793d6

PKG_MAINTAINER:=Tianling Shen <cnsztl@immortalwrt.org>

PKG_BUILD_PARALLEL:=1
CMAKE_INSTALL:=1

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/libquickjs
  SECTION:=lib
  CATEGORY:=Libraries
  URL:=https://bellard.org/quickjs/
  TITLE:=A small and embeddable Javascript engine
  # mips(el) & glibc require it
  DEPENDS:=+libatomic
endef

define Package/libquickjs/description
  QuickJS is a small and embeddable Javascript engine. It supports the
  ES2020 specification including modules, asynchronous generators,
  proxies and BigInt.

  It optionally supports mathematical extensions such as big decimal
  floating point numbers (BigDecimal), big binary floating point
  numbers (BigFloat) and operator overloading.
endef

CMAKE_OPTIONS+= \
	-DBUILD_SHARED_LIBS=ON \
	-DBUILD_TESTING=OFF \
	-DCMAKE_EXE_LINKER_FLAGS="-latomic"

define Package/libquickjs/install
	$(INSTALL_DIR) $(1)/usr/lib/
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libquickjs.so $(1)/usr/lib/
endef

$(eval $(call BuildPackage,libquickjs))
