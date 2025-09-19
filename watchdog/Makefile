#
# Copyright (C) 2025 sirpdboy herboy2008@gmail.com https://github.com/sirpdboy/luci-app-watchdog
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.

include $(TOPDIR)/rules.mk

PKG_NAME:=watchdog
PKG_VERSION:=1
PKG_RELEASE:=5

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=utils
	CATEGORY:=Utilities
	TITLE:=Routing Security Watchdog for OpenWrt
	DEPENDS:=+curl +bash
endef

define Package/$(PKG_NAME)/description
	Routing Security Watchdog for OpenWrt  @sirpdboy  <herboy2008@gmail.com>
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/watchdog
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/config
	$(CP) ./files/watchdog.config $(1)/etc/config/watchdog
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(CURDIR)/files/watchdog.init $(1)/etc/init.d/watchdog
	$(INSTALL_DIR) $(1)/usr/libexec
	$(INSTALL_BIN) $(CURDIR)/files/watchdog-call.libexec $(1)/usr/libexec/watchdog-call
	$(INSTALL_DIR) $(1)/usr/share/watchdog
	$(INSTALL_BIN) $(CURDIR)/files/watchdog.share $(1)/usr/share/watchdog/watchdog
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
