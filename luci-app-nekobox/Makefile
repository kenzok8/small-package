# See /LICENSE for more information.
# This is free software, licensed under the GNU General Public License v3.
# Copyright (C) 2024 Thaolga

include $(TOPDIR)/rules.mk

PKG_MAINTAINER:=Thaolga <https://github.com/Thaolga/luci-app-nekobox>
PKG_NAME:=luci-app-nekobox
PKG_VERSION:=1.5.0
PKG_RELEASE:=cn

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

define Package/$(PKG_NAME)
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=LuCI support for mihomo
	PKGARCH:=all
	DEPENDS:=+kmod-tun +bash +curl +jq +php8 +php8-cgi +php8-mod-curl +php8-mod-zip
endef

define Package/$(PKG_NAME)/description
    A LuCI support for mihomo
endef

include $(INCLUDE_DIR)/package.mk

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) $(CURDIR)/root $(PKG_BUILD_DIR)
	$(CP) $(CURDIR)/luasrc $(PKG_BUILD_DIR)
	$(CP) $(CURDIR)/htdocs $(PKG_BUILD_DIR)
	chmod 0755 $(PKG_BUILD_DIR)/root/usr/bin/nekobox
	chmod 0755 $(PKG_BUILD_DIR)/root/etc/init.d/neko
	chmod 0755 $(PKG_BUILD_DIR)/root/etc/neko/core/*
	chmod 0755 $(PKG_BUILD_DIR)/root/etc/uci-defaults/99_neko
	sed -i "s/0.0.0/$(PKG_VERSION)/g" $(PKG_BUILD_DIR)/root/etc/neko/core/neko
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/preinst
#!/bin/sh
	if [ -f "/etc/config/neko" ]; then
		/etc/neko/core/neko -c

		cp -f "/etc/config/neko" "/tmp/neko/neko.bak"
		cp -rf "/etc/neko/" "/tmp/neko/"

		rm -rf /etc/neko/core/* >/dev/null 2>&1
		rm -rf /www/nekobox/ >/dev/null 2>&1
	fi
	exit 0
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
	if [ -f "/tmp/neko/neko.bak" ]; then
		cp -rf "/tmp/neko/core/mihomo" "/etc/neko/core/mihomo"
		chmod 0755 /etc/neko/core/mihomo
		cp -rf "/tmp/neko/geoip.metadb" "/etc/neko/geoip.metadb"
		cp -rf "/tmp/neko/geosite.db" "/etc/neko/geosite.db"

		cp -rf /tmp/neko/config/* "/etc/neko/config/"
		cp -rf /tmp/neko/proxy_provider/* "/etc/neko/proxy_provider/"
		cp -rf /tmp/neko/rule_provider/* "/etc/neko/rule_provider/"
	fi
	exit 0
endef

define Package/$(PKG_NAME)/prerm
#!/bin/sh
	/etc/neko/core/neko -k

	cp -rf "/etc/neko/" "/tmp/neko/"
	cp -rf "/www/nekobox/" "/tmp/neko/nekobox/"
	cp -f "/etc/config/neko" "/tmp/neko/neko.bak"
	exit 0
endef

define Package/$(PKG_NAME)/postrm
#!/bin/sh
	rm -rf /etc/neko/ >/dev/null 2>&1
	rm -rf /www/nekobox/ >/dev/null 2>&1
	exit 0
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/neko
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	$(INSTALL_DIR) $(1)/www/nekobox
	$(CP) $(PKG_BUILD_DIR)/root/* $(1)/
	$(CP) $(PKG_BUILD_DIR)/luasrc/* $(1)/usr/lib/lua/luci/
	$(CP) $(PKG_BUILD_DIR)/htdocs/* $(1)/www/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
