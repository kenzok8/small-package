#
# Copyright (C) 2015-2016 OpenWrt.org
# Copyright (C) 2020 jjm2473@gmail.com
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk


PKG_NAME:=xunyou
PKG_VERSION:=1.0.9.1
PKG_RELEASE:=2


PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-binary-$(PKG_VERSION)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=Web Servers/Proxies
	TITLE:=xunyou
	DEPENDS:=
endef

define Package/$(PKG_NAME)/description
	xunyou
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/xunyou
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1) $(1)/etc/config $(1)/etc/init.d $(1)/etc/uci-defaults
	cp -pR ./files/xunyou $(1)/
	$(INSTALL_CONF) ./files/xunyou.config $(1)/etc/config/xunyou
	$(INSTALL_BIN) ./files/xunyou.init $(1)/etc/init.d/xunyou
	$(INSTALL_BIN) ./files/xunyou.uci-default $(1)/etc/uci-defaults/xunyou
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
