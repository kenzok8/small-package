#
# Copyright (C) 2016 Openwrt.org
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-UUGameAcc
PKG_VERSION:=20210806
PKG_RELEASE:=2.13.4
PKG_MAINTAINER:=BCYDTZ <https://github.com/BCYDTZ/luci-app-UUGameAcc>

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=LuCI support for UUGameAcc
	PKGARCH:=all
	DEPENDS:=+kmod-tun
endef

define Package/$(PKG_NAME)/description
LuCI Support of Simple Switch to turn UUGameAcc ON/OFF
endef

define Build/Prepare
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./root/etc/config/uuplugin $(1)/etc/config/uuplugin
	
	$(INSTALL_DIR) $(1)/tmp/uuplugin
	cp -pR ./root/files/* $(1)/tmp/uuplugin
	
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./root/etc/init.d/uuplugin_luci $(1)/etc/init.d/uuplugin_luci

	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_CONF) ./root/etc/uci-defaults/* $(1)/etc/uci-defaults
	
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	cp -pR ./luasrc/* $(1)/usr/lib/lua/luci/
	
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	po2lmo ./po/zh-cn/uuplugin.po $(1)/usr/lib/lua/luci/i18n/uuplugin.zh-cn.lmo
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
	mkdir -p ./usr/bin/uuplugin
	chmod +x ./tmp/uuplugin/uuplugin.sh
	sh ./tmp/uuplugin/uuplugin.sh
	rm -rf ./tmp/uuplugin
	chmod +x ./usr/bin/uuplugin/*
	/etc/init.d/uuplugin_luci enable >/dev/null 2>&1
	chmod a+x $${IPKG_INSTROOT}/etc/init.d/uuplugin_luci >/dev/null 2>&1
exit 0
endef

define Package/$(PKG_NAME)/prerm
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
     /etc/init.d/uuplugin_luci disable
     /etc/init.d/uuplugin_luci stop
fi
exit 0
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
