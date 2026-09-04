#
# Copyright (C) 2008-2014 The LuCI Team <luci@lists.subsignal.org>
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=iStoreRouter
PKG_VERSION:=0.6.7
LUCI_DEPENDS:=+luci-app-quickstart +luci-app-store +luci-lib-taskd
LUCI_EXTRA_DEPENDS:=luci-lib-taskd (>=1.0.15)
LUCI_MINIFY_CSS:=0
LUCI_MINIFY_JS:=0

define Package/luci-app-istorerouter/conffiles
/etc/config/istorerouter
/www/luci-static/istorerouter/image/bg.gif
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
