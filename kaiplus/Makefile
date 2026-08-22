#
# Copyright (C) 2026 KaiPlus Contributors
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_ARCH_kaiplus:=$(ARCH)

PKG_NAME:=kaiplus
PKG_VERSION:=1.0.5
PKG_RELEASE:=3
PKG_SOURCE:=$(PKG_NAME)-binary-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/istoreos/istoreos-app-hub/releases/download/kaiplus-runtime-v$(PKG_VERSION)/
PKG_HASH:=9ca0430642ea9ecb601763f9d37d8957543d55ac249c82a75846be7ff71bb89c
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-binary-$(PKG_VERSION)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=System
	SUBMENU:=
	TITLE:=KaiPlus
	URL:=https://github.com/linkease/istore-packages
endef

define Package/$(PKG_NAME)/description
  KaiPlus is a single-process AI workspace and session service.
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/kaiplus
endef

define Package/$(PKG_NAME)/prerm
#!/bin/sh
if [ "$${IPKG_INSTROOT}" = "" ]; then
	if [ "$$(readlink /usr/share/linkeasefull/desktop-apps.d/00-kaiplus-plugin.json 2>/dev/null)" = "/usr/share/kaiplus/kaiplus-plugin.json" ]; then
		rm -f /usr/share/linkeasefull/desktop-apps.d/00-kaiplus-plugin.json
	fi
fi
exit 0
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/usr/share/kaiplus/www $(1)/usr/share/kaiplus/defaults $(1)/usr/share/kaiplus/helpers $(1)/usr/share/linkeasefull/desktop-apps.d $(1)/etc/init.d $(1)/etc/config
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/kaiplus_bin.$(PKG_ARCH_kaiplus) $(1)/usr/sbin/kaiplus_bin
	$(CP) $(PKG_BUILD_DIR)/www/* $(1)/usr/share/kaiplus/www/
	$(INSTALL_DATA) ./files/logo.png $(1)/usr/share/kaiplus/www/logo.png
	$(CP) $(PKG_BUILD_DIR)/defaults/* $(1)/usr/share/kaiplus/defaults/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/helpers/kaiplus_workspace_tool.* $(1)/usr/share/kaiplus/helpers/
	$(INSTALL_DATA) ./files/kaiplus-plugin.json $(1)/usr/share/kaiplus/kaiplus-plugin.json
	ln -sf /usr/share/kaiplus/kaiplus-plugin.json $(1)/usr/share/linkeasefull/desktop-apps.d/00-kaiplus-plugin.json
	$(INSTALL_BIN) ./files/kaiplus.init $(1)/etc/init.d/kaiplus
	$(INSTALL_CONF) ./files/kaiplus.config $(1)/etc/config/kaiplus
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
