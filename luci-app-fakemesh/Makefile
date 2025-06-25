#
# Copyright (C) 2017-2019 Chen Minqiang <ptpt52@gmail.com>
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-fakemesh
PKG_VERSION:=1.0.2
PKG_RELEASE:=1

PKG_LICENSE:=GPLv3
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=Chen Minqiang <ptpt52@gmail.com>

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-fakemesh
	CATEGORY:=X
	SUBMENU:=Configuration Fake Mesh Support
	TITLE:=LuCI Support for fakemesh
	PKGARCH:=all
	DEPENDS:=+jsonfilter +umdns +firewall4
endef

define Package/luci-app-fakemesh/description
	LuCI Support for fakemesh.
endef

define Build/Prepare
	$(foreach po,$(wildcard ${CURDIR}/files/luci/i18n/*.po), \
		po2lmo $(po) $(PKG_BUILD_DIR)/$(patsubst %.po,%.lmo,$(notdir $(po)));)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/luci-app-fakemesh/conffiles
/etc/config/fakemesh
endef

define Package/luci-app-fakemesh/postinst
#!/bin/sh
if [ -z "$$IPKG_INSTROOT" ]; then
  ( . /etc/uci-defaults/40_luci-app-fakemesh )
  rm -f /etc/uci-defaults/40_luci-app-fakemesh
  ( . /etc/uci-defaults/96-fakemesh-defaults )
  rm -f /etc/uci-defaults/96-fakemesh-defaults

  rm -rf /tmp/luci-indexcache /tmp/luci-modulecache
fi

exit 0
endef

define Package/luci-app-fakemesh/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/fakemesh.*.lmo $(1)/usr/lib/lua/luci/i18n/
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./root/etc/config/fakemesh $(1)/etc/config/fakemesh
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./root/etc/init.d/fakemesh $(1)/etc/init.d/fakemesh
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) ./root/usr/sbin/fakemesh $(1)/usr/sbin/fakemesh
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_DATA) ./root/etc/uci-defaults/40_luci-app-fakemesh $(1)/etc/uci-defaults/40_luci-app-fakemesh
	$(INSTALL_DATA) ./root/etc/uci-defaults/96-fakemesh-defaults $(1)/etc/uci-defaults/96-fakemesh-defaults
	$(INSTALL_DIR) $(1)/etc/hotplug.d/dhcp/
	$(INSTALL_DATA) ./root/etc/hotplug.d/dhcp/10-fakemesh $(1)/etc/hotplug.d/dhcp/10-fakemesh
	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface/
	$(INSTALL_DATA) ./root/etc/hotplug.d/iface/19-fakemesh $(1)/etc/hotplug.d/iface/19-fakemesh
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) ./root/usr/share/rpcd/acl.d/*.json $(1)/usr/share/rpcd/acl.d/
	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d
	$(INSTALL_DATA) ./root/usr/share/luci/menu.d/*.json $(1)/usr/share/luci/menu.d/
	$(INSTALL_DIR) $(1)/www/luci-static/resources/view/fakemesh
	$(INSTALL_DATA) ./htdocs/luci-static/resources/view/fakemesh/fakemesh.js $(1)/www/luci-static/resources/view/fakemesh/fakemesh.js
	$(INSTALL_DIR) $(1)/usr/share/ucitrack
	$(INSTALL_DATA) ./root/usr/share/ucitrack/*.json $(1)/usr/share/ucitrack/
endef

$(eval $(call BuildPackage,luci-app-fakemesh))
