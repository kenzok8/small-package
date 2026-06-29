# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2023 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-daede
PKG_VERSION:=1.14.7
PKG_RELEASE:=4
PKG_MAINTAINER:=kenzok8
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)/config
	choice
		prompt "Backend dependency"
		default PACKAGE_$(PKG_NAME)_daed
		help
			Select which backend package luci-app-daede should pull in by default.

	config PACKAGE_$(PKG_NAME)_daed
		bool "daed backend"

	config PACKAGE_$(PKG_NAME)_dae
		bool "dae backend"

	endchoice
endef

define Package/$(PKG_NAME)
	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=LuCI app for daede dashboard
	DEPENDS:=+luci-base +PACKAGE_$(PKG_NAME)_dae:dae +PACKAGE_$(PKG_NAME)_daed:daed
	PKGARCH:=all
	MAINTAINER:=kenzok8
endef

define Package/$(PKG_NAME)/description
	LuCI web interface for managing dae or daed backends.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	po2lmo ./po/zh-cn/daede.po $(PKG_BUILD_DIR)/daede.zh-cn.lmo
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/daede
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./root/etc/config/daede $(1)/etc/config/daede

	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./root/etc/uci-defaults/90-luci-app-daede-init $(1)/etc/uci-defaults/90-luci-app-daede-init

	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d
	$(INSTALL_DATA) ./root/usr/share/luci/menu.d/luci-app-daede.json $(1)/usr/share/luci/menu.d/luci-app-daede.json

	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) ./root/usr/share/rpcd/acl.d/luci-app-daede.json $(1)/usr/share/rpcd/acl.d/luci-app-daede.json

	$(INSTALL_DIR) $(1)/usr/share/luci-app-daede
	$(INSTALL_BIN) ./root/usr/share/luci-app-daede/pkg-info.sh $(1)/usr/share/luci-app-daede/pkg-info.sh
	$(INSTALL_BIN) ./root/usr/share/luci-app-daede/update-geo.sh $(1)/usr/share/luci-app-daede/update-geo.sh
	$(INSTALL_BIN) ./root/usr/share/luci-app-daede/update-pkg.sh $(1)/usr/share/luci-app-daede/update-pkg.sh
	$(INSTALL_BIN) ./root/usr/share/luci-app-daede/gen-dae-config.sh $(1)/usr/share/luci-app-daede/gen-dae-config.sh
	$(INSTALL_BIN) ./root/usr/share/luci-app-daede/proxy-check.sh $(1)/usr/share/luci-app-daede/proxy-check.sh
	$(INSTALL_BIN) ./root/usr/share/luci-app-daede/fetch-clash-yaml.sh $(1)/usr/share/luci-app-daede/fetch-clash-yaml.sh
	$(INSTALL_BIN) ./root/usr/share/luci-app-daede/config-backup.sh $(1)/usr/share/luci-app-daede/config-backup.sh
	$(INSTALL_BIN) ./root/usr/share/luci-app-daede/refresh-index.sh $(1)/usr/share/luci-app-daede/refresh-index.sh
	$(INSTALL_BIN) ./root/usr/share/luci-app-daede/geo-cron.sh $(1)/usr/share/luci-app-daede/geo-cron.sh
	$(INSTALL_BIN) ./root/usr/share/luci-app-daede/daed-sub-update.sh $(1)/usr/share/luci-app-daede/daed-sub-update.sh
	$(INSTALL_BIN) ./root/usr/share/luci-app-daede/daed-sub-cron.sh $(1)/usr/share/luci-app-daede/daed-sub-cron.sh
	$(INSTALL_DIR) $(1)/www/cgi-bin
	$(INSTALL_BIN) ./root/www/cgi-bin/daede-sub $(1)/www/cgi-bin/daede-sub
	$(INSTALL_BIN) ./root/www/cgi-bin/daede-graphql $(1)/www/cgi-bin/daede-graphql

	$(INSTALL_DIR) $(1)/www/luci-static/resources/view/daede
	$(INSTALL_DATA) ./htdocs/luci-static/resources/view/daede/*.js $(1)/www/luci-static/resources/view/daede/
	$(INSTALL_DIR) $(1)/www/luci-static/resources/view/daede/vendor
	$(INSTALL_DATA) ./htdocs/luci-static/resources/view/daede/vendor/* $(1)/www/luci-static/resources/view/daede/vendor/

	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/daede.zh-cn.lmo $(1)/usr/lib/lua/luci/i18n/daede.zh-cn.lmo
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	if [ -x /etc/uci-defaults/90-luci-app-daede-init ]; then
		( . /etc/uci-defaults/90-luci-app-daede-init )
		rm -f /etc/uci-defaults/90-luci-app-daede-init
	fi
	rm -f /usr/lib/lua/luci/i18n/daed.zh-cn.lmo
	rm -rf /tmp/luci-indexcache /tmp/luci-indexcache.* /tmp/luci-modulecache
	/etc/init.d/rpcd restart >/dev/null 2>&1 || true
	/etc/init.d/uhttpd restart >/dev/null 2>&1 || true
fi
exit 0
endef

define Package/$(PKG_NAME)/postrm
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	rm -rf /tmp/luci-indexcache /tmp/luci-indexcache.* /tmp/luci-modulecache
fi
exit 0
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
