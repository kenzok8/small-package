# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2009-2013 OpenWrt.org
#

include $(TOPDIR)/rules.mk

PKG_NAME:=BaiduPCS-Go
PKG_VERSION:=3.9.0
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/qjfoidnh/BaiduPCS-Go/tar.gz/v$(PKG_VERSION)?
PKG_HASH:=de71666e961a3eeb90f8aca7b11934c3f0296d1870e036a7c086ba1decfca8ab

PKG_LICENSE:=Apache-2.0
PKG_LICENSE_FILES:=LICENSE

PKG_BUILD_DEPENDS:=golang/host
PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

GO_PKG:=github.com/qjfoidnh/BaiduPCS-Go
GO_PKG_LDFLAGS_X:=main.Version=v$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk
include ../../lang/golang/golang-package.mk

define Package/BaiduPCS-Go
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Download Manager
  TITLE:=Terminal utility for Baidu Network Disk
  URL:=https://github.com/qjfoidnh/BaiduPCS-Go
  DEPENDS:=$(GO_ARCH_DEPENDS) +ca-bundle
endef

define Package/BaiduPCS-Go/install
	$(call GoPackage/Package/Install/Bin,$(PKG_INSTALL_DIR))

	$(INSTALL_DIR) $(1)/usr/bin/
	$(CP) $(PKG_INSTALL_DIR)/usr/bin/BaiduPCS-Go $(1)/usr/bin/
endef

$(eval $(call GoBinPackage,BaiduPCS-Go))
$(eval $(call BuildPackage,BaiduPCS-Go))
