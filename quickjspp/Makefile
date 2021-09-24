# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=quickjspp
PKG_RELEASE:=$(AUTORELEASE)

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ftk/quickjspp.git
PKG_SOURCE_DATE:=2021-09-13
PKG_SOURCE_VERSION:=bfc4512b28e5cb243376e7af0bb4c320f3be409c
PKG_MIRROR_HASH:=skip

PKG_MAINTAINER:=Tianling Shen <cnsztl@immortalwrt.org>

PKG_BUILD_PARALLEL:=1
CMAKE_INSTALL:=1

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/quickjspp
  SECTION:=lib
  CATEGORY:=Libraries
  URL:=https://github.com/ftk/quickjspp
  TITLE:=QuickJS wrapper for C++
  DEPENDS:=+libatomic +libpthread
  PROVIDES:=quickjs
endef

define Package/quickjspp/description
  QuickJSPP is QuickJS wrapper for C++. It allows you to easily embed
  Javascript engine into your program.
endef

CMAKE_OPTIONS += -DCMAKE_EXE_LINKER_FLAGS="-latomic"

define Build/Install
	$(INSTALL_DIR) $(PKG_INSTALL_DIR)/usr/lib/
	$(CP) $(PKG_BUILD_DIR)/quickjs/libquickjs.a $(PKG_INSTALL_DIR)/usr/lib/
	$(INSTALL_DIR) $(PKG_INSTALL_DIR)/usr/include/quickjs/
	$(CP) $(PKG_BUILD_DIR)/quickjspp.hpp $(PKG_INSTALL_DIR)/usr/include/
	$(CP) $(PKG_BUILD_DIR)/quickjs/quickjs*.h $(PKG_INSTALL_DIR)/usr/include/quickjs/
endef

$(eval $(call BuildPackage,quickjspp))
