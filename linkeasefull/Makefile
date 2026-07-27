#
# Copyright (C) 2026 iStoreOS
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=linkeasefull
PKG_SOURCE_DATE:=3.0.4
PKG_RELEASE:=1

ifeq ($(ARCH),x86_64)
LINKEASE_RUNTIME_ARCH:=amd64
PKG_HASH:=9e8d7b42d0cfb7ae746a34fb1980978b8a32fc57ac5ad905f27df4229cedeb98
else ifeq ($(ARCH),aarch64)
LINKEASE_RUNTIME_ARCH:=arm64
PKG_HASH:=6a02d5a515e80819693609f042a25f0dd005307d54f7111e5ccf730d683743e3
endif

PKG_SOURCE:=linkease-runtime-$(PKG_SOURCE_DATE)-linux-$(LINKEASE_RUNTIME_ARCH).tar.gz
PKG_SOURCE_URL:=https://github.com/linkease/linkease-desktop/releases/download/linkease-runtime-v$(PKG_SOURCE_DATE)/
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-binary-$(PKG_SOURCE_DATE)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0
TAR_CMD=$(HOST_TAR) -C $(PKG_BUILD_DIR) --strip-components=1 $(TAR_OPTIONS)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=Web Servers/Proxies
	TITLE:=LinkEase Full - the local web desktop
	DEPENDS:=@(x86_64||aarch64) +linkease +luci-app-linkease +ca-bundle
	URL:=https://www.linkease.com/
endef

define Package/$(PKG_NAME)/description
  LinkEase Full provides the local web desktop entry for LinkEase and reuses the standard LinkEase LuCI file entry.
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
	$(INSTALL_DIR) $(1)/usr/bin $(1)/usr/libexec/linkeasefull/linkmount_bin $(1)/usr/libexec/linkeasefull/scripts $(1)/etc/config $(1)/etc/init.d $(1)/etc/uci-defaults
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/linkease-full $(1)/usr/bin/linkease-full
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/linkremote-agent $(1)/usr/bin/linkremote-agent
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/hostlink $(1)/usr/bin/hostlink
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/linkmount_bin/linkmount_bin $(1)/usr/libexec/linkeasefull/linkmount_bin/linkmount_bin
	$(CP) $(PKG_BUILD_DIR)/linkmount_bin/lib $(1)/usr/libexec/linkeasefull/linkmount_bin/lib
	$(CP) $(PKG_BUILD_DIR)/linkmount_bin/ver.json $(1)/usr/libexec/linkeasefull/linkmount_bin/ver.json
	$(CP) $(PKG_BUILD_DIR)/scripts/. $(1)/usr/libexec/linkeasefull/scripts/
	$(INSTALL_CONF) ./files/linkeasefull.config $(1)/etc/config/linkeasefull
	$(INSTALL_BIN) ./files/linkeasefull.init $(1)/etc/init.d/linkeasefull
	$(INSTALL_BIN) ./files/linkeasefull.uci-default $(1)/etc/uci-defaults/linkeasefull
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
