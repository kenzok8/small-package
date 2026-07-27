#
# Copyright (C) 2015-2016 OpenWrt.org
# Copyright (C) 2026 LinkEaseLite Contributors
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=linkeaselite
PKG_SOURCE_DATE:=3.0.0
PKG_RELEASE:=1

PKG_SOURCE:=linkeaselite-binary-$(PKG_SOURCE_DATE).tar.gz
PKG_SOURCE_URL:=https://github.com/linkease/istore-packages/releases/download/linkeaselite-v$(PKG_SOURCE_DATE)/
PKG_HASH:=db0811ee189f859b4c8a434338697a57cd2d40d6162b955d3acd3f6b8aee442c
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-binary-$(PKG_SOURCE_DATE)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0
TAR_CMD=$(HOST_TAR) -C $(PKG_BUILD_DIR) $(TAR_OPTIONS)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=Web Servers/Proxies
	TITLE:=LinkEaseLite - the file cloud
	DEPENDS:=@(arm||x86_64||aarch64) +ca-bundle
	URL:=https://www.linkease.com/
endef

define Package/$(PKG_NAME)/description
  LinkEaseLite is a lightweight LinkEase runtime for small-memory OpenWrt devices.
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/linkeaselite
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	[ -f /etc/uci-defaults/linkeaselite ] && /etc/uci-defaults/linkeaselite && rm -f /etc/uci-defaults/linkeaselite
	exit 0
fi
endef

define Package/$(PKG_NAME)/postrm
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	uci -q delete firewall.linkeaselite
	uci -q commit firewall
	/etc/init.d/firewall reload
fi
exit 0
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/config $(1)/etc/init.d $(1)/etc/uci-defaults
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/linkease-lite.$(ARCH) $(1)/usr/sbin/linkease-lite
	$(INSTALL_BIN) ./files/linkeaselite-config.sh $(1)/usr/sbin/linkeaselite-config.sh
	$(INSTALL_CONF) ./files/linkeaselite.config $(1)/etc/config/linkeaselite
	$(INSTALL_BIN) ./files/linkeaselite.init $(1)/etc/init.d/linkeaselite
	$(INSTALL_BIN) ./files/linkeaselite.uci-default $(1)/etc/uci-defaults/linkeaselite
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
