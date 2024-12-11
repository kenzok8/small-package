#
# Copyright (C) 2015-2016 OpenWrt.org
# Copyright (C) 2020 jjm2473@gmail.com
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_ARCH_ISTOREENHANCE:=$(ARCH)

PKG_NAME:=istoreenhance
PKG_VERSION:=0.1.7
PKG_RELEASE:=$(PKG_ARCH_ISTOREENHANCE)-1
PKG_SOURCE:=iStoreEnhance-binary-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=http://fw.koolcenter.com/binary/iStoreEnhance/
PKG_HASH:=6c670eced471c9be7a3b59b52701bc6154cd4d3144e354d492f2ba4cf3caa6f5

PKG_BUILD_DIR:=$(BUILD_DIR)/iStoreEnhance-binary-$(PKG_VERSION)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=Web Servers/Proxies
	TITLE:=iStoreEnhance - Fix some net issues for istore
	URL:=https://www.istoreos.com/
endef

define Package/$(PKG_NAME)/description
  Fix some net issues for istore
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/istoreenhance
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	[ -f /etc/uci-defaults/istoreenhance ] && /etc/uci-defaults/istoreenhance && rm -f /etc/uci-defaults/istoreenhance
	exit 0
fi
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/config $(1)/etc/init.d $(1)/etc/uci-defaults
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/iStoreEnhance.$(PKG_ARCH_ISTOREENHANCE) $(1)/usr/sbin/iStoreEnhance
	$(INSTALL_CONF) ./files/istoreenhance.config $(1)/etc/config/istoreenhance
	$(INSTALL_BIN) ./files/istoreenhance.init $(1)/etc/init.d/istoreenhance
	$(INSTALL_BIN) ./files/istoreenhance.uci-default $(1)/etc/uci-defaults/istoreenhance
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
