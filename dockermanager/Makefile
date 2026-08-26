#
# Copyright (C) 2026 LinkEase Contributors
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_ARCH_DOCKERMANAGER:=$(ARCH)

PKG_NAME:=dockermanager
PKG_VERSION:=0.1.1
PKG_RELEASE:=1
PKG_SOURCE:=$(PKG_NAME)-binary-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/istoreos/istoreos-app-hub/releases/download/dockermanager-runtime-v$(PKG_VERSION)/
PKG_HASH:=6bd0a5b91d32125879fa5ae54ca3a00df1a3b37bffadda8f986fbf1c4a3e0919
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-binary-$(PKG_VERSION)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=System
	TITLE:=Docker Manager
	URL:=https://github.com/linkease/linkease-docker-manager
	DEPENDS:=+docker +dockerd +dockerd +ca-bundle +luci-lib-linkeaseauth
endef

define Package/$(PKG_NAME)/description
  Docker Manager provides a LinkEase Desktop web module and HTTP API for Docker management.
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/dockermanager
endef

define Package/$(PKG_NAME)/prerm
#!/bin/sh
if [ "$${IPKG_INSTROOT}" = "" ]; then
	if [ "$$(readlink /usr/share/linkeasefull/desktop-apps.d/20-dockermanager-plugin.json 2>/dev/null)" = "/usr/share/dockermanager/dockermanager-plugin.json" ]; then
		rm -f /usr/share/linkeasefull/desktop-apps.d/20-dockermanager-plugin.json
	fi
fi
exit 0
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/usr/share/dockermanager/www $(1)/usr/share/linkeasefull/desktop-apps.d $(1)/etc/init.d $(1)/etc/config
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/docker-manager.$(PKG_ARCH_DOCKERMANAGER) $(1)/usr/sbin/docker-manager
	$(CP) $(PKG_BUILD_DIR)/www/* $(1)/usr/share/dockermanager/www/
	$(INSTALL_DATA) ../app-meta-dockermanager/logo.svg $(1)/usr/share/dockermanager/www/logo.svg
	$(INSTALL_DATA) ./files/dockermanager-plugin.json $(1)/usr/share/dockermanager/dockermanager-plugin.json
	ln -sf /usr/share/dockermanager/dockermanager-plugin.json $(1)/usr/share/linkeasefull/desktop-apps.d/20-dockermanager-plugin.json
	$(INSTALL_BIN) ./files/dockermanager.init $(1)/etc/init.d/dockermanager
	$(INSTALL_CONF) ./files/dockermanager.config $(1)/etc/config/dockermanager
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
