#
# Copyright (C) 2015-2016 OpenWrt.org
# Copyright (C) 2020 jjm2473@gmail.com
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_ARCH_kai:=$(ARCH)

PKG_NAME:=kai
PKG_VERSION:=0.0.25
PKG_RELEASE:=1
PKG_SOURCE:=$(PKG_NAME)-binary-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/istoreos/istoreos-app-hub/releases/download/kai-runtime-v$(PKG_VERSION)/
PKG_HASH:=748686f223d07b3b426db766d5954f2efc3c3f1edf753952bb5fad95da49c440
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-binary-$(PKG_VERSION)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=System
	SUBMENU:=
	TITLE:=KAI
	DEPENDS:=+kai_session +kai-agent +luci-lib-linkeaseauth +linkease-app-entry
	URL:=https://github.com/Carseason/openwrt-packages
endef

define Package/$(PKG_NAME)/description
  KAI is a dashboard & user guide
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/kai
endef

define Package/$(PKG_NAME)/prerm
#!/bin/sh
if [ "$${IPKG_INSTROOT}" = "" ]; then
	if [ "$$(readlink /usr/share/linkease/apps.d/05-kai-plugin.json 2>/dev/null)" = "/usr/share/kai/kai-plugin.json" ]; then
		rm -f /usr/share/linkease/apps.d/05-kai-plugin.json
	fi
	if [ "$$(readlink /usr/share/linkeasefull/desktop-apps.d/05-kai-plugin.json 2>/dev/null)" = "/usr/share/kai/kai-plugin.json" ]; then
		rm -f /usr/share/linkeasefull/desktop-apps.d/05-kai-plugin.json
	fi
fi
exit 0
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/usr/libexec $(1)/etc/init.d $(1)/etc/config $(1)/usr/share/kai/www $(1)/usr/share/linkease/apps.d $(1)/usr/share/linkeasefull/desktop-apps.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/kai.$(PKG_ARCH_kai) $(1)/usr/sbin/kai_bin
	$(INSTALL_BIN) ./files/kai-session-launch $(1)/usr/libexec/kai-session-launch
	$(INSTALL_BIN) ./files/kai.init $(1)/etc/init.d/kai
	$(INSTALL_CONF) ./files/kai.config $(1)/etc/config/kai
	$(INSTALL_DATA) ./files/kai-plugin.json $(1)/usr/share/kai/kai-plugin.json
	$(INSTALL_DATA) ./files/logo.png $(1)/usr/share/kai/www/logo.png
	ln -sf /usr/share/kai/kai-plugin.json $(1)/usr/share/linkease/apps.d/05-kai-plugin.json
	ln -sf /usr/share/kai/kai-plugin.json $(1)/usr/share/linkeasefull/desktop-apps.d/05-kai-plugin.json
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
