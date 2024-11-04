#
# Copyright (C) 2015-2016 OpenWrt.org
# Copyright (C) 2020 jjm2473@gmail.com
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk


PKG_NAME:=xunyou
PKG_VERSION:=2.0.6.3
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)_v$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://partnerdownload.xunyou.com/routerplugin/koolshare/
PKG_HASH:=09ce1dd0d4fff42b806dcbeca555b231a184f7a135cc0c9c5b4f03d64b8f8eeb

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)_v$(PKG_VERSION)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=Web Servers/Proxies
	TITLE:=xunyou
	DEPENDS:=+coreutils-nohup
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
	$(CP) $(PKG_BUILD_DIR)/common/. $(1)/
	$(CP) $(PKG_BUILD_DIR)/$(ARCH)/. $(1)/
	$(INSTALL_CONF) ./files/xunyou.config $(1)/etc/config/xunyou
	$(INSTALL_BIN) ./files/xunyou.init $(1)/etc/init.d/xunyou
	$(INSTALL_BIN) ./files/xunyou.uci-default $(1)/etc/uci-defaults/xunyou
endef

$(eval $(call BuildPackage,xunyou))
