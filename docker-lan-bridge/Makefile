#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=docker-lan-bridge
PKG_VERSION:=1.0.1
PKG_RELEASE:=1

PKG_MAINTAINER:=jjm2473 <jjm2473@gmail.com>

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Docker LAN Bridge
  PKGARCH:=all
  DEPENDS:=+ip-full
  URL:=https://github.com/linkease/openwrt-app-actions
endef

define Package/$(PKG_NAME)/description
  Facilitates bridging Docker containers to the LAN
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/uci-defaults $(1)/etc/init.d $(1)/etc/hotplug.d/net
	$(INSTALL_CONF) ./files/docker-lan.uci $(1)/etc/uci-defaults/docker-lan
	$(INSTALL_BIN) ./files/docker-lan.init $(1)/etc/init.d/docker-lan
	$(INSTALL_DATA) ./files/docker-lan.hotplug $(1)/etc/hotplug.d/net/11-docker-lan
endef

$(eval $(call BuildPackage,docker-lan-bridge))
