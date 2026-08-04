#
# Copyright (C) 2026 iStoreOS
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=linkeasefull
PKG_SOURCE_DATE:=3.0.4
PKG_RELEASE:=2

ifeq ($(ARCH),x86_64)
LINKEASE_RUNTIME_ARCH:=amd64
PKG_HASH:=942d04302781f8029d3a05fdc10cb7f1d31df1773c690c47df21dfcd028ebbb6
else ifeq ($(ARCH),aarch64)
LINKEASE_RUNTIME_ARCH:=arm64
PKG_HASH:=9de58f0617392420787c4b2f49888fa3c77a1212166918c7c5ff01873d2b4e24
endif

PKG_SOURCE:=linkease-runtime-$(PKG_SOURCE_DATE)-linux-$(LINKEASE_RUNTIME_ARCH).tar.gz
PKG_SOURCE_URL:=https://github.com/istoreos/istoreos-app-hub/releases/download/linkeasefull-runtime-v$(PKG_SOURCE_DATE)/
PKG_BUILD_DIR:=$(BUILD_DIR)/linkease-runtime-$(PKG_SOURCE_DATE)-linux-$(LINKEASE_RUNTIME_ARCH)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=Web Servers/Proxies
	TITLE:=LinkEase Full - the local web desktop
	DEPENDS:=@(x86_64||aarch64) +linkease-common-bin +ca-bundle
	URL:=https://www.linkease.com/
endef

define Package/$(PKG_NAME)/description
  LinkEase Full provides the local web desktop entry for LinkEase and reuses the shared LinkEase file entry.
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/linkeasefull
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	[ -f /etc/uci-defaults/linkeasefull ] && /etc/uci-defaults/linkeasefull && rm -f /etc/uci-defaults/linkeasefull
	exit 0
fi
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin $(1)/usr/libexec/linkeasefull/linkmount_bin $(1)/etc/config $(1)/etc/init.d $(1)/etc/uci-defaults
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/linkease-full $(1)/usr/bin/linkease-full
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/linkremote-agent $(1)/usr/bin/linkremote-agent
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/hostlink $(1)/usr/bin/hostlink
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/linkmount_bin/linkmount_bin $(1)/usr/libexec/linkeasefull/linkmount_bin/linkmount_bin
	$(CP) $(PKG_BUILD_DIR)/linkmount_bin/lib $(1)/usr/libexec/linkeasefull/linkmount_bin/lib
	$(CP) $(PKG_BUILD_DIR)/linkmount_bin/ver.json $(1)/usr/libexec/linkeasefull/linkmount_bin/ver.json
	$(INSTALL_CONF) ./files/linkeasefull.config $(1)/etc/config/linkeasefull
	$(INSTALL_BIN) ./files/linkeasefull.init $(1)/etc/init.d/linkeasefull
	$(INSTALL_BIN) ./files/linkeasefull.uci-default $(1)/etc/uci-defaults/linkeasefull
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
