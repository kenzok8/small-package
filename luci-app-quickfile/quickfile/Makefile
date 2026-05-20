#
# Copyright (C) 2015-2016 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=quickfile
PKG_VERSION:=1.0.15
PKG_RELEASE:=1

PKG_SOURCE:=quickfile-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://r2.cooluc.com/source
PKG_HASH:=4ba999654345415299af82c96d53d07a030f149b3a72c7e99d8fc0498b51cebb

PKG_MAINTAINER:=sbwml <admin@cooluc.com>

include $(INCLUDE_DIR)/package.mk

define Package/quickfile
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=Web Servers/Proxies
	TITLE:=Quick File Manager
	DEPENDS:=@(arm||aarch64||x86_64)
	URL:=https://git.cooluc.com/sbwml/quickfile
endef

define Package/quickfile/description
  Lightweight web-based file manager for OpenWrt/LuCI with minimal resource usage.
endef

define Build/Compile
endef

define Package/quickfile/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/quickfile.$(ARCH) $(1)/usr/bin/quickfile
	$(INSTALL_DIR) $(1)/etc/init.d $(1)/etc/nginx/conf.d
	$(INSTALL_BIN) $(CURDIR)/files/quickfile.init $(1)/etc/init.d/quickfile
	$(INSTALL_CONF) $(CURDIR)/files/quickfile.locations $(1)/etc/nginx/conf.d/quickfile.locations
endef

$(eval $(call BuildPackage,quickfile))
