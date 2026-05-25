#
# Copyright (C) 2015-2016 OpenWrt.org
# Copyright (C) 2026 jjm2473@gmail.com
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_ARCH_baidudrive:=$(ARCH)

PKG_NAME:=baidudrive
PKG_VERSION:=0.4.0
PKG_RELEASE:=1
PKG_SOURCE:=$(PKG_NAME)-binary-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/Carseason/openwrt-packages/releases/download/prebuilt/
PKG_HASH:=ed9bbedd82ad4504cf6462c2b4a73ebb6f1cd0b9f24e53f26ed830f0b369e1ae
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-binary-$(PKG_VERSION)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=Web Servers/Proxies
	TITLE:=BaiduDrive
	DEPENDS:=@(x86_64||aarch64)
	URL:=https://github.com/linkease/istore-packages
endef

define Package/$(PKG_NAME)/description
  BaiduDrive provides a Baidu Netdisk Web UI for iStoreOS.
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/baidudrive
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/init.d $(1)/etc/uci-defaults $(1)/etc/config
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/baidudrive.$(PKG_ARCH_baidudrive) $(1)/usr/sbin/baidudrive
	$(INSTALL_BIN) ./files/baidudrive.init $(1)/etc/init.d/baidudrive
	$(INSTALL_BIN) ./files/baidudrive.uci-default $(1)/etc/uci-defaults/09-baidudrive
	$(INSTALL_CONF) ./files/baidudrive.config $(1)/etc/config/baidudrive
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
