#
# Copyright (C) 2015-2016 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_ARCH_FASTNET:=$(ARCH)

PKG_NAME:=fastnet
PKG_VERSION:=0.7.7
PKG_RELEASE:=3

PKG_SOURCE:=$(PKG_NAME)-binary-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/istoreos/istoreos-app-hub/releases/download/fastnet-runtime-v$(PKG_VERSION)/
PKG_HASH:=724d63916f04063ca62b5f6420aa0c673bc1166f493e45fe00e431edb8dcc300

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-binary-$(PKG_VERSION)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=Web Servers/Proxies
	TITLE:=FastNet - network test Web UI
	DEPENDS:=@(arm||x86_64||aarch64) +linkease-app-entry
endef

define Package/$(PKG_NAME)/prerm
#!/bin/sh
if [ "$${IPKG_INSTROOT}" = "" ]; then
	if [ "$$(readlink /usr/share/linkease/apps.d/17-fastnet.json 2>/dev/null)" = "/usr/share/fastnet/fastnet-plugin.json" ]; then
		rm -f /usr/share/linkease/apps.d/17-fastnet.json
	fi
	if [ "$$(readlink /usr/share/linkeasefull/desktop-apps.d/17-fastnet.json 2>/dev/null)" = "/usr/share/fastnet/fastnet-plugin.json" ]; then
		rm -f /usr/share/linkeasefull/desktop-apps.d/17-fastnet.json
	fi
fi
exit 0
endef

define Package/$(PKG_NAME)/description
  FastNet provides network testing tools and a Web UI.
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/fastnet
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	[ -f /etc/uci-defaults/fastnet ] && /etc/uci-defaults/fastnet && rm -f /etc/uci-defaults/fastnet
	exit 0
fi
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/config $(1)/etc/init.d $(1)/etc/uci-defaults $(1)/usr/share/fastnet $(1)/usr/share/linkease/apps.d $(1)/usr/share/linkeasefull/desktop-apps.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/FastNet.$(PKG_ARCH_FASTNET) $(1)/usr/sbin/FastNet
	$(INSTALL_CONF) ./files/fastnet.config $(1)/etc/config/fastnet
	$(INSTALL_BIN) ./files/fastnet.init $(1)/etc/init.d/fastnet
	$(INSTALL_BIN) ./files/fastnet.uci-default $(1)/etc/uci-defaults/fastnet
	$(INSTALL_DATA) ./files/fastnet-plugin.json $(1)/usr/share/fastnet/fastnet-plugin.json
	ln -sf /usr/share/fastnet/fastnet-plugin.json $(1)/usr/share/linkease/apps.d/17-fastnet.json
	ln -sf /usr/share/fastnet/fastnet-plugin.json $(1)/usr/share/linkeasefull/desktop-apps.d/17-fastnet.json
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
