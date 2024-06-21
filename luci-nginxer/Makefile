#
# Copyright (C) 2008-2014 The LuCI Team <luci@lists.subsignal.org>
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=Nginxer
LUCI_DESCRIPTION:=Standard OpenWrt set including full admin with ppp support and the default Bootstrap theme
PKG_VERSION:=0.0.2
PKG_RELEASE:=1
LUCI_DEPENDS:=+luci-nginx

define Package/luci-nginxer/postrm
#!/bin/sh
/etc/init.d/uhttpd enable
/etc/init.d/uhttpd start
exit 0
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
