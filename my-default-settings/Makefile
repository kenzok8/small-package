#
# Copyright (C) 2010-2011 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=my-default-settings
PKG_VERSION:=1
PKG_RELEASE:=10

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=luci
  CATEGORY:=LuCI
  TITLE:=Default Settings
  MAINTAINER:=Kiddin'
  PKGARCH:=all
  DEPENDS:=+luci-base +bash
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/base_config
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_DATA) ./files/uci.defaults $(1)/etc/uci-defaults/95-default-settings
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./files/base_config.conf $(1)/etc/config/base_config
	$(INSTALL_DIR) $(1)/lib/wifi
	$(INSTALL_DATA) ./files/wifi-init.sh $(1)/lib/wifi/wifi-init.sh
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/wifi-init.init $(1)/etc/init.d/wifi-init
	$(INSTALL_DIR) $(1)/etc/profile.d
	$(INSTALL_BIN) ./files/sysinfo.sh $(1)/etc/profile.d/sysinfo.sh
	$(INSTALL_DIR) $(1)/sbin
	$(INSTALL_BIN) ./files/shutdown $(1)/sbin/shutdown
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	po2lmo ./po/zh_Hans/default.po $(1)/usr/lib/lua/luci/i18n/default.zh-cn.lmo

endef

$(eval $(call BuildPackage,$(PKG_NAME)))

