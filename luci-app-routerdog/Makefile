#
# Copyright (C) 2008-2014 The LuCI Team <luci@lists.subsignal.org>
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=RouterDog
PKG_VERSION:=1.4.10
PKG_RELEASE:=
LUCI_DEPENDS:=+routergo +luci-app-store +luci-lib-taskd
LUCI_MINIFY_CSS:=0
LUCI_MINIFY_JS:=0

define Package/luci-app-routerdog/conffiles
/etc/config/routerdog
/www/luci-static/routerdog/image/bg.gif
/www/luci-static/routerdog/image/login.gif
endef

define Package/luci-nginxer/postrm
#!/bin/sh
rm -f /tmp/luci-indexcache
exit 0
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature