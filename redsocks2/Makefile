
# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=redsocks2
PKG_VERSION:=0.70
PKG_RELEASE:=1

PKG_SOURCE:=redsocks-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/semigodking/redsocks/tar.gz/release-$(PKG_VERSION)?
PKG_HASH:=2f0536132b744801a135e89c17ee8d51c1893371df8646c0b8e8504d33edb23c
PKG_BUILD_DIR:=$(BUILD_DIR)/redsocks-release-$(PKG_VERSION)

PKG_MAINTAINER:=semigodking <semigodking@gmail.com>
PKG_LICENSE:=Apache-2.0
PKG_LICENSE_FILE:=LICENSE

PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

define Package/redsocks2
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Web Servers/Proxies
  TITLE:=Redirect TCP connection to proxy server
  URL:=https://github.com/semigodking/redsocks
  DEPENDS:=+libevent2 +libopenssl
endef

define Package/redsocks2/description
  This is a modified version of original redsocks.
  Transparent redirector of any TCP/UDP connection to proxy.
endef

MAKE_VARS += DISABLE_SHADOWSOCKS=true

define Package/redsocks2/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/redsocks2 $(1)/usr/sbin
	$(INSTALL_DIR) $(1)/etc/redsocks2
	$(INSTALL_DATA) ./files/redsocks2.template $(1)/etc/redsocks2/config.template
endef

$(eval $(call BuildPackage,redsocks2))
