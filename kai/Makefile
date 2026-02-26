#
# Copyright (C) 2015-2016 OpenWrt.org
# Copyright (C) 2020 jjm2473@gmail.com
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_ARCH_kai:=$(ARCH)

PKG_NAME:=kai
PKG_VERSION:=0.0.3
PKG_RELEASE:=0
PKG_SOURCE:=$(PKG_NAME)-binary-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/linkease/istore-packages/releases/download/prebuilt/
PKG_HASH:=c7c7159ba1278239707bdb79276fe775781a6b086bf83cb726d4da49e4c20b20
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-binary-$(PKG_VERSION)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=System
	SUBMENU:=
	TITLE:=KAI
	URL:=https://github.com/Carseason/openwrt-packages
endef

define Package/$(PKG_NAME)/description
  KAI is a dashboard & user guide
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/kai
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/init.d $(1)/etc/config
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/kai.$(PKG_ARCH_kai) $(1)/usr/sbin/kai_bin
	$(INSTALL_BIN) ./files/kai.init $(1)/etc/init.d/kai
	$(INSTALL_CONF) ./files/kai.config $(1)/etc/config/kai
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
