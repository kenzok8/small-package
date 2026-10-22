#
# Copyright (C) 2026 KaiPlus Contributors
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

KAIPLUS_ARCH_x86_64:=amd64
KAIPLUS_ARCH_aarch64:=arm64
KAIPLUS_ARCH:=$(KAIPLUS_ARCH_$(ARCH))

KAIPLUS_HASH_x86_64:=5588a5e1b7874bc5e631ab8ff1288226f567a84d3115808f22352d142c40f5d6
KAIPLUS_HASH_aarch64:=5be29e4715a1181937c0156a6954738ce96fde2f338a1b03cd32c68b00e61524

PKG_NAME:=kaiplus
PKG_VERSION:=1.0.9
PKG_RELEASE:=8

KAIPLUS_URL_FILE:=kaiplus-linux-$(KAIPLUS_ARCH)
KAIPLUS_DOWNLOAD:=$(KAIPLUS_URL_FILE)-$(KAIPLUS_HASH_$(ARCH))
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0
STRIP:=true
RSTRIP:=:

include $(INCLUDE_DIR)/package.mk

define Download/kaiplus
	URL:=https://fw.koolcenter.com/binary/kai/releases/build/
	URL_FILE:=$(KAIPLUS_URL_FILE)
	FILE:=$(KAIPLUS_DOWNLOAD)
	HASH:=$(KAIPLUS_HASH_$(ARCH))
endef

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=System
	SUBMENU:=
	TITLE:=KaiPlus
	URL:=https://github.com/linkease/istore-packages
	DEPENDS:=@(x86_64||aarch64) +linkease-app-entry
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
	if [ "$$(readlink /usr/share/linkease/apps.d/00-kaiplus-plugin.json 2>/dev/null)" = "/usr/share/kaiplus/kaiplus-plugin.json" ]; then
		rm -f /usr/share/linkease/apps.d/00-kaiplus-plugin.json
	fi
fi
exit 0
endef

define Build/Prepare
	$(INSTALL_DIR) $(PKG_BUILD_DIR)
	$(CP) $(DL_DIR)/$(KAIPLUS_DOWNLOAD) $(PKG_BUILD_DIR)/kaiplus
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/usr/share/kaiplus $(1)/usr/share/linkease/apps.d $(1)/usr/share/linkeasefull/desktop-apps.d $(1)/etc/init.d $(1)/etc/config
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/kaiplus $(1)/usr/sbin/kaiplus
	$(INSTALL_DATA) ./files/logo.png $(1)/usr/share/kaiplus/logo.png
	$(INSTALL_DATA) ./files/kaiplus-plugin.json $(1)/usr/share/kaiplus/kaiplus-plugin.json
	ln -sf /usr/share/kaiplus/kaiplus-plugin.json $(1)/usr/share/linkeasefull/desktop-apps.d/00-kaiplus-plugin.json
	ln -sf /usr/share/kaiplus/kaiplus-plugin.json $(1)/usr/share/linkease/apps.d/00-kaiplus-plugin.json
	$(INSTALL_BIN) ./files/kaiplus.init $(1)/etc/init.d/kaiplus
	$(INSTALL_CONF) ./files/kaiplus.config $(1)/etc/config/kaiplus
endef

$(eval $(call Download,kaiplus))
$(eval $(call BuildPackage,$(PKG_NAME)))
