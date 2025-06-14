#
# Copyright (C) 2025 sirpdboy herboy2008@gmail.com https://github.com/sirpdboy/luci-app-netspeedtest
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.

include $(TOPDIR)/rules.mk

PKG_NAME:=netspeedtest
PKG_VERSION:=1
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=utils
	CATEGORY:=Utilities
	TITLE:=Routing netspeedtest for OpenWrt 
	DEPENDS:=+curl +bash +coreutils-nohup
endef

define Package/$(PKG_NAME)/description
	Routing  netspeedtest for OpenWrt  @sirpdboy  <herboy2008@gmail.com>
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/netspeedtest
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/config
	$(CP) ./files/netspeedtest.config $(1)/etc/config/netspeedtest
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(CURDIR)/files/netspeedtest.init $(1)/etc/init.d/netspeedtest
	$(INSTALL_DIR) $(1)/usr/lib/netspeedtest
	$(INSTALL_BIN) $(CURDIR)/files/speedtest.lib $(1)/usr/lib/netspeedtest/speedtest
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) $(CURDIR)/files/99_netspeedtest.defaults $(1)/etc/uci-defaults/99_netspeedtest
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
