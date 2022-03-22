#
# Copyright (C) 2020-2021 sirpdboy <herboy2008@gmail.com>
# The LuCI Network diagnosis and speed test <https://github.com/sirpdboy/NetSpeedTest>
# This is free software, licensed under the GNU General Public License v3.
# 

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-netspeedtest
PKG_VERSION:=1.7
PKG_RELEASE:=20220322
PKG_LICENSE:=GPLv2
PKG_MAINTAINER:=sirpdboy

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=LuCI Support for netspeedtest
	DEPENDS:=+python3 +iperf3
	PKGARCH:=all
endef


define Build/Compile
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/netspeedtest
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	cp -pR ./luasrc/* $(1)/usr/lib/lua/luci
	$(INSTALL_DIR) $(1)/
	cp -pR ./root/* $(1)/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	po2lmo ./po/zh-cn/netspeedtest.po $(1)/usr/lib/lua/luci/i18n/netspeedtest.zh-cn.lmo
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

